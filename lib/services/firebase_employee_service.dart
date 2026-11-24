import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import '../models/employee_model.dart';
import '../models/social_cause_models.dart';
import '../models/company_notification_models.dart';
import '../models/task_model.dart';
import '../models/online_order_model.dart';
import '../models/chat_message_model.dart';
import '../models/konar_book_model.dart';
import '../providers/ecosystem_provider.dart';

/// Firebase Employee & Omnichannel Service for MN Jewel Park
/// Handles centralized Cloud Firestore sync, authentication, role allocation,
/// and real-time persistence of the 4 Pillars for Online Department.
class FirebaseEmployeeService {
  static bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// True only when running under `flutter test`. The offline credential
  /// fallback in [authenticateUser] is restricted to this environment so a
  /// failed Firebase initialization can never turn into a login bypass.
  static bool get isTestEnvironment {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  final FirebaseFirestore? _customFirestore;
  final FirebaseAuth? _customAuth;

  FirebaseEmployeeService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _customFirestore = firestore,
        _customAuth = auth;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _employeeCollection =>
      _firestore.collection('online_department_employees');

  CollectionReference<Map<String, dynamic>> get _offlineEmployeeCollection =>
      _firestore.collection('offline_department_employees');

  CollectionReference<Map<String, dynamic>> get _departmentsCollection =>
      _firestore.collection('departments');

  /// Resolves the specific Firestore collection name for a given department
  static String getDepartmentCollectionName(String? dept) {
    final clean = (dept ?? '').trim().toLowerCase();
    if (clean.isEmpty || clean == 'online' || clean == 'online department') {
      return 'online_department_employees';
    }
    if (clean == 'offline' || clean == 'offline department') {
      return 'offline_department_employees';
    }
    final slug = clean
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return slug.endsWith('_employees') ? slug : '${slug}_employees';
  }

  CollectionReference<Map<String, dynamic>> _deptEmployeeCollection(String? dept) =>
      _firestore.collection(getDepartmentCollectionName(dept));

  /// Finds the employee collection reference based on empId or known dept
  Future<CollectionReference<Map<String, dynamic>>> _findEmployeeCollection(
    String empId, [
    String? knownDept,
  ]) async {
    if (knownDept != null && knownDept.isNotEmpty) {
      return _deptEmployeeCollection(knownDept);
    }
    try {
      final userQuery = await _usersCollection
          .where('empId', isEqualTo: empId)
          .limit(1)
          .get();
      if (userQuery.docs.isNotEmpty) {
        final d = userQuery.docs.first.data();
        final dept = d['dept']?.toString();
        if (dept != null && dept.isNotEmpty) {
          return _deptEmployeeCollection(dept);
        }
      }
    } catch (_) {}

    try {
      final offlineDoc = await _offlineEmployeeCollection.doc(empId).get();
      if (offlineDoc.exists) {
        return _offlineEmployeeCollection;
      }
    } catch (_) {}

    return _employeeCollection;
  }

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _socialCausesCollection =>
      _firestore.collection('social_causes');

  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore.collection('company_notifications');

  CollectionReference<Map<String, dynamic>> get _todosCollection =>
      _firestore.collection('personal_todos');

  CollectionReference<Map<String, dynamic>> get _ordersCollection =>
      _firestore.collection('online_orders');

  CollectionReference<Map<String, dynamic>> get _chatsCollection =>
      _firestore.collection('mn_team_chats');

  CollectionReference<Map<String, dynamic>> get _konarBooksCollection =>
      _firestore.collection('konar_books');

  /// Stream real-time employee list across all department collections (Online, Offline, and custom departments)
  Stream<List<Employee>> streamEmployees() {
    final controller = StreamController<List<Employee>>.broadcast();
    final Map<String, List<Employee>> departmentEmployeesMap = {};
    final Map<String, StreamSubscription> subscriptions = {};

    void emitMergedList() {
      if (controller.isClosed) return;
      final Map<String, Employee> merged = {};
      final Map<String, Employee> byNormalizedName = {};

      for (final list in departmentEmployeesMap.values) {
        for (final emp in list) {
          final normName = emp.name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
          if (normName.isEmpty) {
            merged[emp.id] = emp;
            continue;
          }

          if (byNormalizedName.containsKey(normName)) {
            // Duplicate detected for the same person across department collections!
            final existing = byNormalizedName[normName]!;
            final isNewPackagingDispatch = emp.role.toLowerCase().contains('packaging & dispatch');
            final isExistingPackagingDispatch = existing.role.toLowerCase().contains('packaging & dispatch');
            final isNewBetter = isNewPackagingDispatch ||
                (!isExistingPackagingDispatch && emp.empNo.isNotEmpty && existing.empNo.isEmpty);

            if (isNewBetter) {
              merged.remove(existing.id);
              merged[emp.id] = emp;
              byNormalizedName[normName] = emp;
            }
          } else {
            byNormalizedName[normName] = emp;
            merged[emp.id] = emp;
          }
        }
      }

      // Guarantee executive leadership (Mohankumar G and M N Naveenraaj) are never omitted
      if (!merged.containsKey('7') && !byNormalizedName.containsKey('mohankumar g')) {
        final hrMohan = Employee(
          id: '7',
          empNo: '7',
          name: 'Mohankumar G',
          role: 'HR Manager & Operations Custodian',
          roleType: 'hr',
          dept: 'Administration',
          phone: '+91 94433 11000',
          email: 'hr@mnj.com',
          avatar: '',
          initials: 'MG',
          doj: '2021-03-10',
          experienceYears: '8 yrs in HR Management',
          experienceCategory: 'experienced',
          probationWeeks: 0,
          probationStatus: 'cleared',
          probationEndDate: 'Completed',
          status: 'active',
          ragStatus: 'green',
          lastActive: 'Active now',
          profileCompletion: ProfileCompletion(
            percentage: 100,
            isAuthorized: true,
            photoVerified: true,
            addressVerified: true,
            kycVerified: true,
            sopRolesAcknowledged: true,
          ),
        );
        merged['7'] = hrMohan;
        byNormalizedName['mohankumar g'] = hrMohan;
      }
      if (!merged.containsKey('MN-CEO01') && !byNormalizedName.containsKey('m n naveenraaj')) {
        final ceo = Employee(
          id: 'MN-CEO01',
          name: 'M N Naveenraaj',
          role: 'Managing Director & CEO',
          roleType: 'ceo',
          dept: 'Administration',
          phone: '+91 98450 00001',
          email: 'ceoofmn@mnjpark.com',
          avatar: '',
          initials: 'MN',
          doj: '2020-01-01',
          experienceYears: '25 yrs in Fine Jewellery',
          experienceCategory: 'experienced',
          probationWeeks: 0,
          probationStatus: 'cleared',
          probationEndDate: 'Completed',
          status: 'active',
          ragStatus: 'green',
          lastActive: 'Active now',
          profileCompletion: ProfileCompletion(
            percentage: 100,
            isAuthorized: true,
            photoVerified: true,
            addressVerified: true,
            kycVerified: true,
            sopRolesAcknowledged: true,
          ),
        );
        merged['MN-CEO01'] = ceo;
        byNormalizedName['m n naveenraaj'] = ceo;
      }

      controller.add(merged.values.toList());
    }

    void listenToDeptCollection(String colName) {
      if (subscriptions.containsKey(colName)) return;
      final sub = _firestore.collection(colName).snapshots().listen((snapshot) {
        final list = <Employee>[];
        for (final doc in snapshot.docs) {
          try {
            final emp = Employee.fromMap(doc.data(), doc.id);
            // Self-healing migration: if an employee was saved in online_department_employees but belongs to another department
            // Strictly exclude core leadership (CEO & HR) from migration drops
            final isCoreLeader = emp.id == 'MN-CEO01' || emp.id == '7' || emp.roleType == 'ceo' || emp.roleType == 'hr';
            final rawDept = (doc.data()['dept']?.toString() ?? emp.dept).trim();
            final targetDeptCol = getDepartmentCollectionName(rawDept);
            if (!isCoreLeader && colName == 'online_department_employees' && targetDeptCol != 'online_department_employees') {
              _firestore
                  .collection(targetDeptCol)
                  .doc(emp.id)
                  .set(doc.data(), SetOptions(merge: true))
                  .then((_) {
                _employeeCollection.doc(emp.id).delete().catchError((_) {});
              }).catchError((_) {});
              continue;
            }
            list.add(emp);
          } catch (e) {
            debugPrint('Error parsing employee doc ${doc.id} in $colName: $e');
          }
        }
        departmentEmployeesMap[colName] = list;
        emitMergedList();
      }, onError: (err) {
        debugPrint('Error streaming $colName: $err');
      });
      subscriptions[colName] = sub;
    }

    // 1. Listen to core Online, Offline & Administration department employee collections
    listenToDeptCollection('online_department_employees');
    listenToDeptCollection('offline_department_employees');
    listenToDeptCollection('administration_employees');

    // 2. Dynamically listen to any other registered departments
    StreamSubscription? deptSub;
    try {
      deptSub = _departmentsCollection.snapshots().listen((snap) {
        for (final doc in snap.docs) {
          final colName = doc.data()['collection']?.toString();
          if (colName != null && colName.isNotEmpty) {
            listenToDeptCollection(colName);
          }
        }
      }, onError: (err) {
        debugPrint('Error streaming departments registry: $err');
      });
    } catch (_) {}

    controller.onCancel = () {
      for (final s in subscriptions.values) {
        s.cancel();
      }
      deptSub?.cancel();
    };

    return controller.stream;
  }

  /// Initialize and seed corporate accounts if Firestore is completely empty
  Future<void> seedCorporateAccountsIfEmpty() async {
    try {
      if (!isFirebaseAvailable) return;
      final col = _employeeCollection;
      // Always ensure official CEO & HR leadership identity is updated in Cloud Firestore
      await syncCorporateLeadershipNames();

      final snapshot = await col.limit(1).get();
      if (snapshot.docs.isNotEmpty) return; // Already initialized

      debugPrint('Initializing Official MN Corporate accounts in Cloud Firestore...');
      final accounts = [
        {
          'id': 'MN-CEO01',
          'empNo': '',
          'name': 'M N Naveenraaj',
          'email': 'ceoofmn@mnjpark.com',
          'role': 'Managing Director & CEO',
          'roleType': 'ceo',
          'dept': 'Executive Board',
          'phone': '+91 98450 00001',
          'experienceYears': '25 yrs in Fine Jewellery',
          'experienceCategory': 'experienced',
          'probationWeeks': 0,
          'probationStatus': 'cleared',
          'probationEndDate': 'Completed',
          'status': 'active',
          'ragStatus': 'green',
          'initials': 'MN',
          'lastActive': 'Active now',
          'dob': '1975-01-15',
          'relationshipStatus': 'Married',
          'anniversaryDate': '',
          'profileCompletion': {
            'percentage': 100,
            'isAuthorized': true,
            'photoVerified': true,
            'addressVerified': true,
            'kycVerified': true,
            'sopRolesAcknowledged': true,
          },
        },
        {
          'id': '7',
          'empNo': '7',
          'name': 'Mohankumar G',
          'email': 'hr@mnj.com',
          'role': 'HR Manager & Operations Custodian',
          'roleType': 'hr',
          'dept': 'Human Resources',
          'phone': '+91 94433 11000',
          'experienceYears': '8 yrs in HR Management',
          'experienceCategory': 'experienced',
          'probationWeeks': 0,
          'probationStatus': 'cleared',
          'probationEndDate': 'Completed',
          'status': 'active',
          'ragStatus': 'green',
          'initials': 'MG',
          'lastActive': 'Active now',
          'dob': '1993-04-10',
          'relationshipStatus': 'Married',
          'anniversaryDate': '',
          'profileCompletion': {
            'percentage': 100,
            'isAuthorized': true,
            'photoVerified': true,
            'addressVerified': true,
            'kycVerified': true,
            'sopRolesAcknowledged': true,
          },
        },
        {
          'id': 'MN-TL1002',
          'empNo': '',
          'name': 'Praveenkumar M',
          'email': 'praveenkumarotm@mnj.com',
          'role': 'Online Team Manager (Editor)',
          'roleType': 'team_lead',
          'dept': 'Online & Design',
          'phone': '+91 94420 11001',
          'experienceYears': '6 yrs in Digital Media',
          'experienceCategory': 'experienced',
          'probationWeeks': 0,
          'probationStatus': 'cleared',
          'probationEndDate': 'Completed',
          'status': 'active',
          'ragStatus': 'green',
          'initials': 'PM',
          'lastActive': 'Active now',
          'dob': '1999-09-18',
          'gender': 'male',
          'relationshipStatus': 'Single',
          'anniversaryDate': '',
          'profileCompletion': {
            'percentage': 100,
            'isAuthorized': true,
            'photoVerified': true,
            'addressVerified': true,
            'kycVerified': true,
            'sopRolesAcknowledged': true,
          },
        },
        {
          'id': '6',
          'empNo': '6',
          'name': 'Gokulakrishnan K',
          'email': 'gokulakrishnanosh@mnj.com',
          'role': 'Online Sale Head (OSH)',
          'roleType': 'employee',
          'dept': 'Online Department',
          'phone': '+91 94420 11002',
          'experienceYears': '5 yrs in Retail Sales',
          'experienceCategory': 'experienced',
          'probationWeeks': 0,
          'probationStatus': 'cleared',
          'probationEndDate': 'Completed',
          'status': 'active',
          'ragStatus': 'green',
          'initials': 'KG',
          'lastActive': 'Active now',
          'dob': '1995-05-12',
          'relationshipStatus': 'Single',
          'anniversaryDate': '',
          'profileCompletion': {
            'percentage': 100,
            'isAuthorized': true,
            'photoVerified': true,
            'addressVerified': true,
            'kycVerified': true,
            'sopRolesAcknowledged': true,
          },
        },
        {
          'id': '33',
          'empNo': '33',
          'name': 'Mithra M',
          'email': 'mithraassvpe@mnj.com',
          'role': 'Assistant Photographer & Videographer (Ass.VPE)',
          'roleType': 'employee',
          'dept': 'Online Department',
          'phone': '+91 94420 11004',
          'experienceYears': '3 yrs in Photography',
          'experienceCategory': 'experienced',
          'probationWeeks': 0,
          'probationStatus': 'cleared',
          'probationEndDate': 'Completed',
          'status': 'active',
          'ragStatus': 'green',
          'initials': 'MM',
          'lastActive': 'Active now',
          'dob': '1997-10-08',
          'relationshipStatus': 'Single',
          'anniversaryDate': '',
          'profileCompletion': {
            'percentage': 100,
            'isAuthorized': true,
            'photoVerified': true,
            'addressVerified': true,
            'kycVerified': true,
            'sopRolesAcknowledged': true,
          },
        },
        {
          'id': '65',
          'empNo': '65',
          'name': 'Kaaviya',
          'email': 'kaaviyaos1@mnj.com',
          'role': 'Online Sale Person 1 (OS1)',
          'roleType': 'employee',
          'dept': 'Online Department',
          'phone': '+91 80567 36999',
          'experienceYears': '3 yrs in Jewelry Sales',
          'experienceCategory': 'experienced',
          'probationWeeks': 0,
          'probationStatus': 'cleared',
          'probationEndDate': 'Completed',
          'status': 'active',
          'ragStatus': 'green',
          'initials': 'KV',
          'lastActive': 'Active now',
          'dob': '1999-07-11',
          'relationshipStatus': 'Single',
          'anniversaryDate': '',
          'profileCompletion': {
            'percentage': 100,
            'isAuthorized': true,
            'photoVerified': true,
            'addressVerified': true,
            'kycVerified': true,
            'sopRolesAcknowledged': true,
          },
        },
        {
          'id': '67',
          'empNo': '67',
          'name': 'Nisha',
          'email': 'nishaos2@mnj.com',
          'role': 'Online Sale Person 2 (OS2)',
          'roleType': 'employee',
          'dept': 'Online Department',
          'phone': '+91 89258 68077',
          'experienceYears': '3 yrs in Customer Care',
          'experienceCategory': 'experienced',
          'probationWeeks': 0,
          'probationStatus': 'cleared',
          'probationEndDate': 'Completed',
          'status': 'active',
          'ragStatus': 'green',
          'initials': 'NS',
          'lastActive': 'Active now',
          'dob': '1999-12-05',
          'relationshipStatus': 'Single',
          'anniversaryDate': '',
          'profileCompletion': {
            'percentage': 100,
            'isAuthorized': true,
            'photoVerified': true,
            'addressVerified': true,
            'kycVerified': true,
            'sopRolesAcknowledged': true,
          },
        },
        {
          'id': 'EXT-VPE',
          'empNo': '',
          'name': 'Aravinda Samy',
          'email': 'aravindasamy@mnj.com',
          'role': 'Chief Photographer, Videographer & Content Video Editor (VPE)',
          'roleType': 'external_support',
          'dept': 'External Support Staff [Online]',
          'phone': '+91 94420 11010',
          'experienceYears': '7 yrs in Videography & Commercial Direction',
          'experienceCategory': 'experienced',
          'probationWeeks': 0,
          'probationStatus': 'cleared',
          'probationEndDate': 'Completed',
          'status': 'active',
          'ragStatus': 'green',
          'initials': 'AS',
          'lastActive': 'Active now',
          'dob': '1992-06-18',
          'relationshipStatus': 'Single',
          'anniversaryDate': '',
          'profileCompletion': {
            'percentage': 100,
            'isAuthorized': true,
            'photoVerified': true,
            'addressVerified': true,
            'kycVerified': true,
            'sopRolesAcknowledged': true,
          },
        },
        {
          'id': 'EXT-AC',
          'empNo': '',
          'name': 'Midhun Kumar',
          'email': 'midhunkumar@mnj.com',
          'role': 'Online Analytical Consultant (AC)',
          'roleType': 'external_support',
          'dept': 'External Support Staff [Online]',
          'phone': '+91 94420 11011',
          'experienceYears': '6 yrs in Performance Ads & Analytics',
          'experienceCategory': 'experienced',
          'probationWeeks': 0,
          'probationStatus': 'cleared',
          'probationEndDate': 'Completed',
          'status': 'active',
          'ragStatus': 'green',
          'initials': 'MK',
          'lastActive': 'Active now',
          'dob': '1994-03-22',
          'relationshipStatus': 'Single',
          'anniversaryDate': '',
          'profileCompletion': {
            'percentage': 100,
            'isAuthorized': true,
            'photoVerified': true,
            'addressVerified': true,
            'kycVerified': true,
            'sopRolesAcknowledged': true,
          },
        },
        {
          'id': 'EXT-OSS',
          'empNo': '',
          'name': 'Subash',
          'email': 'subash@mnj.com',
          'role': 'Online Support and Strategist (OSS)',
          'roleType': 'external_support',
          'dept': 'External Support Staff [Online]',
          'phone': '+91 94420 11012',
          'experienceYears': '5 yrs in Campaign Strategy',
          'experienceCategory': 'experienced',
          'probationWeeks': 0,
          'probationStatus': 'cleared',
          'probationEndDate': 'Completed',
          'status': 'active',
          'ragStatus': 'green',
          'initials': 'SB',
          'lastActive': 'Active now',
          'dob': '1995-11-09',
          'relationshipStatus': 'Single',
          'anniversaryDate': '',
          'profileCompletion': {
            'percentage': 100,
            'isAuthorized': true,
            'photoVerified': true,
            'addressVerified': true,
            'kycVerified': true,
            'sopRolesAcknowledged': true,
          },
        },
        {
          'id': 'EXT-DVP',
          'empNo': '',
          'name': 'K B Eshwar',
          'email': 'kbeshwar@mnj.com',
          'role': 'Developer (DVP)',
          'roleType': 'external_support',
          'dept': 'External Support Staff [Online]',
          'phone': '+91 94420 11013',
          'experienceYears': '6 yrs in Web & Mobile Engineering',
          'experienceCategory': 'experienced',
          'probationWeeks': 0,
          'probationStatus': 'cleared',
          'probationEndDate': 'Completed',
          'status': 'active',
          'ragStatus': 'green',
          'initials': 'KE',
          'lastActive': 'Active now',
          'dob': '1993-09-30',
          'relationshipStatus': 'Single',
          'anniversaryDate': '',
          'profileCompletion': {
            'percentage': 100,
            'isAuthorized': true,
            'photoVerified': true,
            'addressVerified': true,
            'kycVerified': true,
            'sopRolesAcknowledged': true,
          },
        },
        {
          'id': 'EXT-CC',
          'empNo': '',
          'name': 'Sam Roy',
          'email': 'samroy@mnj.com',
          'role': 'Content Creator (CC)',
          'roleType': 'external_support',
          'dept': 'External Support Staff [Online]',
          'phone': '+91 94420 11014',
          'experienceYears': '4 yrs in Content Creation & Creative Scripting',
          'experienceCategory': 'experienced',
          'probationWeeks': 0,
          'probationStatus': 'cleared',
          'probationEndDate': 'Completed',
          'status': 'active',
          'ragStatus': 'green',
          'initials': 'SR',
          'lastActive': 'Active now',
          'dob': '1998-04-14',
          'relationshipStatus': 'Single',
          'anniversaryDate': '',
          'profileCompletion': {
            'percentage': 100,
            'isAuthorized': true,
            'photoVerified': true,
            'addressVerified': true,
            'kycVerified': true,
            'sopRolesAcknowledged': true,
          },
        },
      ];

      for (final acc in accounts) {
        final id = acc['id'] as String;
        final email = (acc['email'] as String).toLowerCase().trim();

        await _employeeCollection.doc(id).set(acc);
        await _usersCollection.doc(email).set({
          'empId': id,
          'name': acc['name'],
          'email': email,
          'role': acc['roleType'],
          'roleType': acc['roleType'],
          'dept': acc['dept'],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Firestore seed error (offline or permission): $e');
    }
  }

  /// Ensure corporate leadership names, authentic passwords, and Online Department scope are always accurate
  Future<void> syncCorporateLeadershipNames() async {
    try {
      final officialAccounts = {
        'MN-CEO01': {'email': 'ceoofmn@mnjpark.com', 'name': 'M N Naveenraaj', 'role': 'Managing Director & CEO', 'roleType': 'ceo', 'dept': 'Executive Board', 'roleCode': 'CEO'},
        '7': {'email': 'hr@mnj.com', 'name': 'Mohankumar G', 'role': 'Head of Human Resources', 'roleType': 'hr', 'dept': 'HR & People Ops', 'roleCode': 'HR'},
        'MN-TL1002': {'email': 'praveenkumarotm@mnj.com', 'name': 'Praveenkumar M', 'role': 'Team Lead', 'roleType': 'team_lead', 'dept': 'Operations', 'roleCode': 'OTM'},
        '6': {'email': 'gokulakrishnanosh@mnj.com', 'name': 'Gokulakrishnan K', 'role': 'Online Sale Head', 'roleType': 'employee', 'dept': 'Sales', 'roleCode': 'OSH'},
        '33': {'email': 'mithraassvpe@mnj.com', 'name': 'Mithra M', 'role': 'Assistant Photographer & Videographer', 'roleType': 'employee', 'dept': 'Media', 'roleCode': 'Ass.VPE'},
        'EXT-ECE': {'email': 'ece@mnj.com', 'name': 'E-Commerce Executive', 'role': 'E-Commerce Executive', 'roleType': 'employee', 'dept': 'Technology', 'roleCode': 'ECE'},
        '65': {'email': 'kaaviyaos1@mnj.com', 'name': 'Kaaviya', 'role': 'Online Sale Person 1', 'roleType': 'employee', 'dept': 'Sales', 'roleCode': 'OS1'},
        '67': {'email': 'nishaos2@mnj.com', 'name': 'Nisha', 'role': 'Online Sale Person 2', 'roleType': 'employee', 'dept': 'Sales', 'roleCode': 'OS2'},
        'EXT-VPE': {'email': 'aravindasamyvpe@mnj.com', 'name': 'Aravinda Samy', 'role': 'Chief Photographer & Video Editor', 'roleType': 'external_support', 'dept': 'Media', 'roleCode': 'VPE'},
        'EXT-AC': {'email': 'midhunkumarac@mnj.com', 'name': 'Midhun Kumar', 'role': 'Online Analytical Consultant', 'roleType': 'external_support', 'dept': 'Accounts', 'roleCode': 'AC'},
        'EXT-OSS': {'email': 'subashoss@mnj.com', 'name': 'Subash', 'role': 'Online Support & Strategist', 'roleType': 'external_support', 'dept': 'Operations', 'roleCode': 'OSS'},
        'EXT-DVP': {'email': 'eshwardvp@mnj.com', 'name': 'K B Eshwar', 'role': 'Developer', 'roleType': 'external_support', 'dept': 'Technology', 'roleCode': 'DVP'},
        'EXT-CC': {'email': 'samroycc@mnj.com', 'name': 'Sam Roy', 'role': 'Content Creator', 'roleType': 'external_support', 'dept': 'Media', 'roleCode': 'CC'},
      };

      for (final entry in officialAccounts.entries) {
        final id = entry.key;
        final info = entry.value;
        final email = info['email']!;

        final deptAssignment = info['dept']!;

        try {
          final empDoc = await _employeeCollection.doc(id).get();
          if (!empDoc.exists) {
            // New doc: Seed default values
            await _employeeCollection.doc(id).set({
              'id': id,
              'name': info['name'],
              'email': email,
              'role': info['role'],
              'roleType': info['roleType'],
              'roleCode': info['roleCode'],
              'dept': deptAssignment,
            }, SetOptions(merge: true));
          } else {
            // Existing doc: NEVER overwrite user-edited password, phone, dob, or gender!
            final data = empDoc.data() ?? {};
            final Map<String, dynamic> patches = {};
            if (data['dept'] == null || data['dept'] == '') {
              patches['dept'] = deptAssignment;
            }
            if (data['roleCode'] == null || data['roleCode'] == '') {
              patches['roleCode'] = info['roleCode'];
            }
            if (id == 'MN-TL1002') {
              if (data['anniversaryDate'] == '2021-11-20') {
                patches['anniversaryDate'] = '';
              }
              if (data['relationshipStatus'] == 'Married') {
                patches['relationshipStatus'] = 'Single';
              }
              if (data['dob'] == '1994-08-15') {
                patches['dob'] = '1999-09-18';
              }
            }
            if (patches.isNotEmpty) {
              await _employeeCollection.doc(id).update(patches);
            }
          }
        } catch (_) {}

        try {
          final userDoc = await _usersCollection.doc(email).get();
          if (!userDoc.exists) {
            await _usersCollection.doc(email).set({
              'empId': id,
              'name': info['name'],
              'email': email,
              'role': info['roleType'],
              'roleType': info['roleType'],
              'roleCode': info['roleCode'],
              'dept': deptAssignment,
            }, SetOptions(merge: true));
          }
        } catch (_) {}

        // Guarantee Mohankumar G / HR and CEO accounts exist in administration_employees collection
        if (id == '7' || id == 'MN-CEO01') {
          try {
            await _firestore.collection('administration_employees').doc(id).set({
              'id': id,
              'empNo': id == '7' ? '7' : '',
              'name': info['name'],
              'email': email,
              'role': info['role'],
              'roleType': info['roleType'],
              'dept': 'Administration',
            }, SetOptions(merge: true));
          } catch (_) {}
        }
      }

      // Ensure CEO document has official identity
      try {
        final ceoDoc = await _employeeCollection.doc('MN-CEO01').get();
        if (!ceoDoc.exists) {
          await _employeeCollection.doc('MN-CEO01').set({
            'name': 'M N Naveenraaj',
            'initials': 'MN',
            'role': 'Managing Director & CEO',
            'dept': 'Administration',
          }, SetOptions(merge: true));
        } else {
          final d = ceoDoc.data() ?? {};
          final name = d['name']?.toString() ?? '';
          if (name.contains('Senthil') || name.isEmpty) {
            await _employeeCollection.doc('MN-CEO01').update({
              'name': 'M N Naveenraaj',
              'initials': 'MN',
              'role': 'Managing Director & CEO',
              'dept': 'Administration',
            });
          }
        }
      } catch (_) {}

      // Actively purge dead/blank notifications from Cloud Firestore
      try {
        await purgeDeadNotifications();
      } catch (_) {}

      // Actively purge duplicate staff accounts and enforce 5-chapter Konar book in Firestore

      // Ensure HR document has official identity
      try {
        final hrDocs = ['7', 'MN-HR1001'];
        for (final docId in hrDocs) {
          final hrDoc = await _employeeCollection.doc(docId).get();
          if (!hrDoc.exists) {
            await _employeeCollection.doc(docId).set({
              'id': docId,
              'empNo': '7',
              'name': 'Mohankumar G',
              'initials': 'MG',
              'role': 'HR Manager & Operations Custodian',
              'dept': 'Administration',
            }, SetOptions(merge: true));
          } else {
            final d = hrDoc.data() ?? {};
            final name = d['name']?.toString() ?? '';
            if (name.isEmpty) {
              await _employeeCollection.doc(docId).update({
                'name': 'Priyanka HR',
                'initials': 'PH',
                'role': 'Head of Human Resources',
                'dept': 'HR & People Ops',
              });
            }
          }
        }
      } catch (_) {}

      // Actively purge dead/blank notifications from Cloud Firestore
      try {
        await purgeDeadNotifications();
      } catch (_) {}

      // Actively purge duplicate staff accounts and enforce 5-chapter Konar book in Firestore

      // Sanitize legacy notifications in Cloud Firestore
      final notifSnap = await _notificationsCollection.get();
      for (final doc in notifSnap.docs) {
        final data = doc.data();
        final sender = data['senderName']?.toString() ?? '';
        final title = data['title']?.toString() ?? '';
        final content = data['content']?.toString() ?? '';
        if (sender.contains('Senthil') || sender.contains('Executive CEO') || content.contains('Senthil') || title.contains('Senthil')) {
          await doc.reference.set({
            'senderName': 'M N Naveenraaj',
            'senderRole': 'Managing Director & CEO',
            'title': title
                .replaceAll('Dr. K. Senthil Nathan', 'M N Naveenraaj')
                .replaceAll('Senthil Nathan', 'M N Naveenraaj')
                .replaceAll('Senthil', 'M N Naveenraaj'),
            'content': content
                .replaceAll('Dr. K. Senthil Nathan', 'M N Naveenraaj')
                .replaceAll('Senthil Nathan', 'M N Naveenraaj')
                .replaceAll('Senthil', 'M N Naveenraaj')
                .replaceAll('CEO & Founder', 'Managing Director & CEO'),
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint('Firestore syncCorporateLeadershipNames note: $e');
    }
  }

  /// Update an employee's role, department, and granular RBAC permissions in Cloud Firestore
  Future<void> updateEmployeeRoleAndPermissions({
    required String employeeId,
    required String newRoleCode,
    required String newRoleType,
    required String newRole,
    required String newDept,
    required RolePermissions permissions,
  }) async {
    // Prevent CEO lockout: MN-CEO01 must always retain CEO permissions
    if (employeeId.toUpperCase() == 'MN-CEO01') {
      if (!permissions.canAccessCeoSuite || !permissions.canManageRoles) {
        throw ArgumentError('Cannot revoke CEO Suite or Role Management permissions from Executive CEO.');
      }
    }

    if (!isFirebaseAvailable) return;
    try {
      final docRef = _employeeCollection.doc(employeeId);
      await docRef.set({
        'roleCode': newRoleCode,
        'roleType': newRoleType,
        'role': newRole,
        'dept': newDept,
        'permissions': permissions.toMap(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore updateEmployeeRoleAndPermissions error: $e');
    }
  }

  /// B-01, P-01: Destructive automatic client-side deduplication removed.
  /// Deduplication must never run automatically on client devices based on name matches.
  Future<void> purgeDuplicateStaffAccounts() async {
    // Deprecated per B-01 / P-01: Client launch must never delete employees who share a name.
    return;
  }

  /// B-06: Ensure default Konar Book exists without overwriting user edits.
  Future<void> forceUpdateOnlineKonarBookTo5Architectures() async {
    if (!isFirebaseAvailable) return;
    try {
      final defaultBook = KonarBookModel.defaultOnlineDepartment();
      for (final docId in ['online_department']) {
        final doc = await _konarBooksCollection.doc(docId).get();
        if (!doc.exists) {
          await _konarBooksCollection.doc(docId).set(
            defaultBook.toJson(),
            SetOptions(merge: true),
          );
          debugPrint('Seeded initial Konar book $docId in Firestore.');
        }
      }
    } catch (e) {
      debugPrint('Error ensuring Konar book: $e');
    }
  }

  /// Creates a user in Firebase Authentication on the cloud without logging out active session
  Future<bool> createAuthUserWithoutSignout({
    required String email,
    required String password,
  }) async {
    FirebaseApp? secondaryApp;
    final cleanEmail = email.trim().toLowerCase();
    if (!cleanEmail.contains('@') || password.length < 6) return false;
    try {
      final appName = 'AuthProvision_${DateTime.now().millisecondsSinceEpoch}';
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      await secondaryAuth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      debugPrint('Successfully registered $cleanEmail directly in enterprise cloud directory.');
      return true;
    } catch (e) {
      debugPrint('Secondary Firebase App user creation note: $e');
      return false;
    } finally {
      try {
        await secondaryApp?.delete();
      } catch (_) {}
    }
  }

  /// Save or update employee document in Firestore within their department collection
  Future<void> saveEmployee(Employee employee) async {
    try {
      final data = employee.toMap();
      final deptColName = getDepartmentCollectionName(employee.dept);
      final col = _firestore.collection(deptColName);
      await col.doc(employee.id).set(data, SetOptions(merge: true));

      // Register department in departments collection
      _departmentsCollection.doc(deptColName).set({
        'name': employee.dept,
        'collection': deptColName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).catchError((_) {});
    } catch (e) {
      debugPrint('Firestore saveEmployee error: $e');
    }
  }

  /// Add new employee (Exclusively allowed for HR and CEO)
  Future<void> addEmployee({
    required Employee employee,
    required String requesterRole,
    String? password,
  }) async {
    final role = requesterRole.toLowerCase();
    if (role != 'hr' && role != 'ceo') {
      throw Exception('Permission Denied: Only HR and CEO are authorized to add new users.');
    }

    final data = employee.toMap();
    data['dept'] = employee.dept.isEmpty ? 'Online Department' : employee.dept;
    data['createdAt'] = FieldValue.serverTimestamp();

    final deptColName = getDepartmentCollectionName(employee.dept);
    final targetCol = _firestore.collection(deptColName);

    // 1. Save in the department's dedicated collection
    await targetCol.doc(employee.id).set(data);

    // If it was previously in online_department_employees by mistake, clean it up
    if (deptColName != 'online_department_employees') {
      await _employeeCollection.doc(employee.id).delete().catchError((_) {});
    }

    // 2. Register department in departments registry
    try {
      await _departmentsCollection.doc(deptColName).set({
        'name': employee.dept,
        'collection': deptColName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}

    // 3. Save in users collection for authentication & role lookup
    final emailKey = employee.email.toLowerCase().trim();
    if (emailKey.isNotEmpty) {
      await _usersCollection.doc(emailKey).set({
        'empId': employee.id,
        'name': employee.name,
        'email': emailKey,
        'role': employee.roleType,
        'roleType': employee.roleType,
        'dept': employee.dept,
        'collection': deptColName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Register user directly into Firebase Authentication
      if (password != null && password.length >= 6) {
        await createAuthUserWithoutSignout(
          email: emailKey,
          password: password,
        );
      }
    }
  }

  /// Explicitly registers a new department in Cloud Firestore (Exclusively allowed for HR and CEO)
  Future<String> createDepartment({
    required String name,
    required String requesterRole,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw Exception('Department name cannot be empty.');
    }
    final role = requesterRole.toLowerCase();
    if (role != 'hr' && role != 'ceo') {
      throw Exception('Permission Denied: Only HR and CEO are authorized to create new departments.');
    }

    final deptColName = getDepartmentCollectionName(cleanName);
    await _departmentsCollection.doc(deptColName).set({
      'name': cleanName,
      'collection': deptColName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return deptColName;
  }

  /// Streams registered department names from Cloud Firestore
  Stream<List<String>> streamDepartmentNames() {
    return _departmentsCollection.snapshots().map((snap) {
      final names = <String>{'Online Department', 'HR & Administration'};
      for (final doc in snap.docs) {
        final dName = doc.data()['name']?.toString().trim();
        if (dName != null && dName.isNotEmpty) {
          final lower = dName.toLowerCase();
          if (lower != 'offline department' && lower != 'offline' && lower != 'administration') {
            names.add(dName);
          }
        }
      }
      return names.toList();
    });
  }

  /// Streams the set of permanently deleted departments from system metadata
  Stream<Set<String>> streamDeletedDepartments() {
    return _firestore
        .collection('system_metadata')
        .doc('departments_metadata')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return <String>{};
      final list = (doc.data()?['deletedDepartments'] as List?)?.map((e) => e.toString().toLowerCase().trim()).toSet() ?? <String>{};
      return list;
    });
  }

  /// Fetches deleted departments blacklist
  Future<Set<String>> getDeletedDepartments() async {
    try {
      final doc = await _firestore.collection('system_metadata').doc('departments_metadata').get();
      if (!doc.exists) return <String>{};
      return (doc.data()?['deletedDepartments'] as List?)?.map((e) => e.toString().toLowerCase().trim()).toSet() ?? <String>{};
    } catch (_) {
      return <String>{};
    }
  }

  /// Completely deletes a department with executive workflow (Strictly CEO Privilege)
  /// - If [deleteEmployees] is true: all employees belonging to this department are removed.
  /// - If [deleteEmployees] is false: all employees are reallocated to [reallocateToDept] and moved in Firestore.
  /// - Deletes department from departments registry, deletes associated KONAR book, and blacklists it from active department lists.
  Future<void> deleteDepartmentWithWorkflow({
    required String deptName,
    required bool deleteEmployees,
    String? reallocateToDept,
    required String requesterRole,
  }) async {
    final role = requesterRole.trim().toLowerCase();
    if (role != 'ceo') {
      throw Exception('Permission Denied: Only the CEO can delete a department completely.');
    }
    final cleanDept = deptName.trim();
    if (cleanDept.isEmpty) return;
    final lowerDept = cleanDept.toLowerCase();
    if (lowerDept == 'administration' || lowerDept == 'executive board') {
      throw Exception('Permission Denied: Core Executive and Administration departments cannot be deleted.');
    }

    final sourceColName = getDepartmentCollectionName(cleanDept);

    // 1. Employee disposition
    if (deleteEmployees) {
      // Delete all employee documents in this department's Firestore collection
      try {
        final snap = await _firestore.collection(sourceColName).get();
        for (final doc in snap.docs) {
          final data = doc.data();
          final email = data['email']?.toString();
          if (email != null && email.isNotEmpty) {
            await _usersCollection.doc(email.toLowerCase().trim()).delete().catchError((_) {});
          }
          await doc.reference.delete().catchError((_) {});
        }
      } catch (e) {
        debugPrint('Error deleting employees in $sourceColName: $e');
      }
    } else {
      // Reallocate employees to reallocateToDept
      final targetDept = (reallocateToDept ?? 'Online Department').trim();
      final targetColName = getDepartmentCollectionName(targetDept);

      try {
        final snap = await _firestore.collection(sourceColName).get();
        for (final doc in snap.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          data['dept'] = targetDept;
          data['department'] = targetDept;
          data['updatedAt'] = FieldValue.serverTimestamp();

          // Write to target department collection
          await _firestore.collection(targetColName).doc(doc.id).set(data, SetOptions(merge: true));
          // Delete from old department collection
          await doc.reference.delete().catchError((_) {});

          // Update user doc in users collection
          final email = data['email']?.toString();
          if (email != null && email.isNotEmpty) {
            await _usersCollection.doc(email.toLowerCase().trim()).update({
              'dept': targetDept,
            }).catchError((_) {});
          }
        }
      } catch (e) {
        debugPrint('Error reallocating employees from $sourceColName to $targetColName: $e');
      }
    }

    // 2. Remove department from 'departments' collection
    try {
      await _departmentsCollection.doc(sourceColName).delete().catchError((_) {});
      final dSnap = await _departmentsCollection.where('name', isEqualTo: cleanDept).get();
      for (final doc in dSnap.docs) {
        await doc.reference.delete().catchError((_) {});
      }
    } catch (_) {}

    // 3. Delete any KONAR books associated with this department
    try {
      await deleteKonarBookForDepartment(cleanDept, requesterRole: requesterRole);
    } catch (_) {}

    // 4. Record in deleted departments blacklist metadata so it NEVER returns
    try {
      await _firestore.collection('system_metadata').doc('departments_metadata').set({
        'deletedDepartments': FieldValue.arrayUnion([lowerDept, cleanDept]),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Toggle KONAR book visibility for department staff (Strictly CEO privilege)
  Future<void> toggleKonarBookVisibility({
    required String bookId,
    required bool isVisible,
    required String requesterRole,
  }) async {
    final role = requesterRole.trim().toLowerCase();
    if (role != 'ceo') {
      throw Exception('Permission Denied: Only the CEO can change KONAR book visibility.');
    }
    await _konarBooksCollection.doc(bookId).set({
      'isVisible': isVisible,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Delete KONAR book by ID (Strictly CEO privilege)
  Future<void> deleteKonarBook({
    required String bookId,
    required String requesterRole,
  }) async {
    if (!isFirebaseAvailable) return;
    final role = requesterRole.trim().toLowerCase();
    if (role != 'ceo') {
      throw Exception('Permission Denied: Only the CEO can delete a KONAR book.');
    }
    try {
      final chunks = await _konarBooksCollection.doc(bookId).collection('pdf_chunks').get();
      for (final c in chunks.docs) {
        await c.reference.delete().catchError((_) {});
      }
    } catch (_) {}
    await _konarBooksCollection.doc(bookId).delete();
  }

  /// Delete KONAR book for a specific department
  Future<void> deleteKonarBookForDepartment(String departmentName, {required String requesterRole}) async {
    final clean = departmentName.trim().toLowerCase();
    try {
      final snap = await _konarBooksCollection.get();
      for (final doc in snap.docs) {
        final d = (doc.data()['department']?.toString() ?? '').trim().toLowerCase();
        final id = doc.id.toLowerCase();
        if (d == clean || id == clean || id == getDepartmentCollectionName(clean)) {
          await deleteKonarBook(bookId: doc.id, requesterRole: requesterRole);
        }
      }
    } catch (_) {}
  }

  /// Remove employee (Exclusively allowed for HR and CEO)
  Future<void> removeEmployee({
    required String employeeId,
    required String requesterRole,
    String? dept,
  }) async {
    final role = requesterRole.toLowerCase();
    if (role != 'hr' && role != 'ceo') {
      throw Exception('Permission Denied: Only HR and CEO are authorized to remove employees.');
    }
    if (employeeId == 'MN-CEO01') {
      throw Exception('Permission Denied: Executive CEO account cannot be removed.');
    }

    // Lookup and delete from their department collection and users collection
    try {
      final col = await _findEmployeeCollection(employeeId, dept);
      final doc = await col.doc(employeeId).get();
      if (doc.exists) {
        final email = doc.data()?['email'] as String?;
        if (email != null && email.isNotEmpty) {
          await _usersCollection.doc(email.toLowerCase().trim()).delete().catchError((_) {});
        }
      }
      await col.doc(employeeId).delete();
    } catch (_) {
      await _employeeCollection.doc(employeeId).delete().catchError((_) {});
      await _offlineEmployeeCollection.doc(employeeId).delete().catchError((_) {});
    }
  }

  /// Authenticate user strictly via Firebase Auth and Cloud Firestore.
  /// Fixed S-01, S-02, S-03, S-04: No hardcoded passwords, no silent user creation,
  /// Firebase Auth is the single source of truth for credentials.
  Future<Map<String, dynamic>?> authenticateUser({
    required String emailOrId,
    required String password,
  }) async {
    final query = emailOrId.trim().toLowerCase();
    if (query.isEmpty || password.isEmpty) {
      throw Exception('Email / Password incorrect');
    }

    // 1. Resolve authentic email
    String targetEmail = query;
    if (query == 'ceoofmn@mnjpark.com' ||
        query == 'ceo@mnj.com' ||
        query == 'mn-ceo01' ||
        query == 'ceo' ||
        query == 'naveenraaj' ||
        query == 'naveen' ||
        query == 'ceoofmn') {
      targetEmail = 'ceoofmn@mnjpark.com';
    } else if (query == 'hr@mnj.com' ||
        query == 'mn-hr1001' ||
        query == '7' ||
        query == 'mohankumar@mnj.com' ||
        query == 'hr' ||
        query == 'mohankumar') {
      targetEmail = 'hr@mnj.com';
    } else if (EcosystemProvider.corporateRegistry[query] != null) {
      // Known login alias (e.g. "gokul", "os1", "gokul@mnj.com") -> official email
      targetEmail = EcosystemProvider.corporateRegistry[query]!.defaultEmail;
    } else if (!query.contains('@')) {
      // Look up user doc or employee doc by ID/empNo
      try {
        for (final col in [_employeeCollection, _offlineEmployeeCollection]) {
          final doc = await col.doc(emailOrId.trim()).get();
          if (doc.exists && doc.data() != null) {
            final e = doc.data()!['email']?.toString().trim().toLowerCase();
            if (e != null && e.contains('@')) {
              targetEmail = e;
              break;
            }
          }
        }
      } catch (_) {}
    }

    if (!targetEmail.contains('@')) {
      throw Exception('Email / Password incorrect');
    }

    // Firebase unavailable outside of tests: refuse to authenticate rather than
    // trusting the typed credentials (previously any password was accepted).
    if (!isFirebaseAvailable && !isTestEnvironment) {
      throw Exception('Login service unavailable. Please check your connection and try again.');
    }

    // Unit-test environment without Firebase initialized
    if (!isFirebaseAvailable) {
      final reg = EcosystemProvider.corporateRegistry[targetEmail] ??
          EcosystemProvider.corporateRegistry[emailOrId.trim().toLowerCase()];
      if (reg != null) {
        return {
          'empId': reg.empId,
          'roleType': reg.roleType,
          'email': reg.defaultEmail,
          'name': reg.empId,
        };
      }
      if (targetEmail.contains('ceo') || emailOrId.toLowerCase().contains('ceo')) {
        return {
          'empId': 'MN-CEO01',
          'roleType': 'ceo',
          'email': 'ceoofmn@mnjpark.com',
          'name': 'M N Naveenraaj',
        };
      } else if (targetEmail == 'hr@mnj.com' || emailOrId.toLowerCase() == 'hr@mnj.com' || emailOrId == '7') {
        return {
          'empId': '7',
          'roleType': 'hr',
          'email': 'hr@mnj.com',
          'name': 'Mohankumar G',
        };
      } else if (targetEmail.contains('otm') || emailOrId.contains('TL1002') || emailOrId.contains('praveen')) {
        return {
          'empId': 'MN-TL1002',
          'roleType': 'dept_head',
          'email': 'praveenkumarotm@mnj.com',
          'name': 'Praveenkumar M',
        };
      }
      return {
        'empId': emailOrId.trim(),
        'roleType': 'employee',
        'email': targetEmail,
        'name': emailOrId.trim(),
      };
    }

    // 2. Perform authentic Firebase Auth sign-in
    try {
      await _auth.signInWithEmailAndPassword(
        email: targetEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth sign-in failed: ${e.code} - ${e.message}');
      throw Exception('Email / Password incorrect');
    } catch (e) {
      debugPrint('Authentication error: $e');
      throw Exception('Email / Password incorrect');
    }

    // 3. User authenticated successfully; fetch role and profile from Firestore
    var profileLookupFailed = false;
    Map<String, dynamic>? staleUserData;
    try {
      final userDoc = await _usersCollection.doc(targetEmail).get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final dept = data['dept']?.toString();
        final empId = data['empId']?.toString() ?? query;
        final col = _deptEmployeeCollection(dept);
        final empDoc = await col.doc(empId).get();
        if (empDoc.exists && empDoc.data() != null) {
          final d = empDoc.data()!;
          return {
            'empId': d['id'] ?? empId,
            'name': d['name'] ?? data['name'],
            'email': d['email'] ?? targetEmail,
            'role': d['roleType'] ?? data['roleType'] ?? (d['role'].toString().toLowerCase().contains('lead') ? 'team_lead' : 'employee'),
            'roleType': d['roleType'] ?? data['roleType'] ?? 'employee',
            'dept': d['dept'] ?? dept ?? 'Online Department',
          };
        }
        // The users doc points at an employee id that does not exist (stale
        // record). Fall through and find the employee by email instead.
        staleUserData = data;
      }

      // Search every department collection, not just online/offline.
      final cols = <CollectionReference<Map<String, dynamic>>>[
        _employeeCollection,
        _offlineEmployeeCollection,
        for (final name in const [
          'administration_employees',
          'accounts_employees',
          'media_employees',
          'operations_employees',
          'technology_employees',
          'sales_employees',
        ])
          _firestore.collection(name),
      ];
      try {
        final depts = await _departmentsCollection.get();
        for (final d in depts.docs) {
          final name = d.data()['collection']?.toString() ?? '';
          if (name.endsWith('_employees') && !cols.any((c) => c.id == name)) {
            cols.add(_firestore.collection(name));
          }
        }
      } catch (_) {}
      for (final col in cols) {
        final emailQuery = await col.where('email', isEqualTo: targetEmail).limit(1).get();
        if (emailQuery.docs.isNotEmpty) {
          final d = emailQuery.docs.first.data();
          return {
            'empId': d['id'] ?? emailQuery.docs.first.id,
            'name': d['name'],
            'email': d['email'] ?? targetEmail,
            'role': d['roleType'] ?? (d['role'].toString().toLowerCase().contains('lead') ? 'team_lead' : 'employee'),
            'roleType': d['roleType'] ?? 'employee',
            'dept': d['dept'] ?? 'Online Department',
          };
        }
      }
    } catch (e) {
      debugPrint('Profile lookup after login note: $e');
      profileLookupFailed = true;
    }

    if (targetEmail == 'ceoofmn@mnjpark.com') {
      return {
        'empId': 'MN-CEO01',
        'name': 'M N Naveenraaj',
        'email': 'ceoofmn@mnjpark.com',
        'role': 'ceo',
        'roleType': 'ceo',
        'dept': 'Executive Board',
      };
    }
    if (targetEmail == 'hr@mnj.com') {
      return {
        'empId': '7',
        'name': 'Mohankumar G',
        'email': 'hr@mnj.com',
        'role': 'hr',
        'roleType': 'hr',
        'dept': 'Human Resources',
      };
    }

    // No employee record found by email either: keep the previous behaviour
    // of trusting the users doc rather than locking the person out.
    if (staleUserData != null) return staleUserData;

    if (profileLookupFailed) {
      try {
        await _auth.signOut();
      } catch (_) {}
      throw Exception('Network error while loading your profile. Please try again.');
    }

    // Authenticated with Firebase, but no staff record exists any more (e.g.
    // relieved from the company). Do not let them into the app.
    try {
      await _auth.signOut();
    } catch (_) {}
    throw Exception('This account is not active. Please contact HR.');
  }

  /// Save specific Pillar data for an Employee to Cloud Firestore in their department collection
  Future<void> saveEmployeePillar({
    required String empId,
    required String pillarKey,
    required dynamic data,
    String? dept,
  }) async {
    if (!isFirebaseAvailable) return;
    try {
      final col = await _findEmployeeCollection(empId, dept);
      await col.doc(empId).set({
        'fourPillars': {
          pillarKey: data,
        },
        'lastActive': 'Just now',
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveEmployeePillar ($pillarKey) error: $e');
      rethrow;
    }
  }

  /// Update specific profile fields within the employee's department collection
  Future<void> updateEmployeeProfileFields({
    required String empId,
    required Map<String, dynamic> fields,
    String? email,
    String? dept,
  }) async {
    if (!isFirebaseAvailable) return;
    try {
      final col = await _findEmployeeCollection(empId, dept);
      await col.doc(empId).set(fields, SetOptions(merge: true));
      final cleanEmail = email?.toLowerCase().trim();
      if (cleanEmail != null && cleanEmail.isNotEmpty) {
        await _usersCollection.doc(cleanEmail).set(fields, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Firestore updateEmployeeProfileFields error: $e');
      rethrow;
    }
  }

  // ---- Personal notes (private per employee; synced across devices) ----
  CollectionReference<Map<String, dynamic>> get _notesCollection =>
      _firestore.collection('personal_notes');

  /// Returns null when the cloud copy could not be read (offline / no Firebase),
  /// so callers never mistake "unavailable" for "no notes".
  Future<List<Map<String, dynamic>>?> loadPersonalNotes(String empId) async {
    if (!isFirebaseAvailable || empId.isEmpty) return null;
    try {
      final snap = await _notesCollection
          .where('ownerEmpId', isEqualTo: empId)
          .get(const GetOptions(source: Source.server));
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('Firestore loadPersonalNotes note: $e');
      return null;
    }
  }

  Future<void> savePersonalNote(Map<String, dynamic> note) async {
    if (!isFirebaseAvailable) return;
    final id = note['id']?.toString() ?? '';
    if (id.isEmpty) return;
    try {
      await _notesCollection.doc(id).set(note);
    } catch (e) {
      debugPrint('Firestore savePersonalNote note: $e');
    }
  }

  Future<void> deletePersonalNote(String noteId) async {
    if (!isFirebaseAvailable || noteId.isEmpty) return;
    try {
      await _notesCollection.doc(noteId).delete();
    } catch (e) {
      debugPrint('Firestore deletePersonalNote note: $e');
    }
  }

  /// Prescriptions are stored in their own documents (not inside the
  /// employee record, which Firestore caps at 1 MB per document).
  Future<void> savePrescription({
    required String leaveId,
    required String empId,
    required String base64,
  }) async {
    if (!isFirebaseAvailable || base64.isEmpty) return;
    await _firestore.collection('leave_prescriptions').doc(leaveId).set({
      'leaveId': leaveId,
      'empId': empId,
      'data': base64,
      'uploadedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> loadPrescription(String leaveId) async {
    if (!isFirebaseAvailable) return null;
    try {
      final doc = await _firestore.collection('leave_prescriptions').doc(leaveId).get();
      return doc.data()?['data']?.toString();
    } catch (e) {
      debugPrint('Firestore loadPrescription note: $e');
      return null;
    }
  }

  /// Email a Firebase password-reset link to [email]. Safe for HR/CEO to call
  /// for another employee because it never touches the signed-in account.
  Future<void> sendPasswordResetEmail(String email) async {
    if (!isFirebaseAvailable) {
      throw Exception('Login service unavailable.');
    }
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No login account exists for $email.');
      }
      throw Exception(e.message ?? e.code);
    }
  }

  /// Changes the password of the CURRENTLY SIGNED-IN user only.
  /// Never use this to reset someone else's password.
  Future<void> updateEmployeePassword({
    required String empId,
    required String email,
    required String newPassword,
    String? dept,
  }) async {
    try {
      if (_auth.currentUser != null) {
        await _auth.currentUser!.updatePassword(newPassword);
      }
    } catch (e) {
      debugPrint('Firebase Auth updatePassword error: $e');
      rethrow;
    }
  }

  /// Load 4-Pillars for the logged-in employee from Firestore from their department collection
  Future<Map<String, dynamic>?> loadEmployeePillars(String empId, [String? dept]) async {
    try {
      final col = await _findEmployeeCollection(empId, dept);
      final doc = await col.doc(empId).get();
      if (doc.exists && doc.data() != null) {
        final d = doc.data()!;
        if (d['fourPillars'] is Map) {
          return Map<String, dynamic>.from(d['fourPillars'] as Map);
        }
      }
    } catch (e) {
      debugPrint('Firestore loadEmployeePillars error: $e');
    }
    return null;
  }

  /// Stream real-time social causes (Pillar 5)
  Stream<List<SocialCauseItem>> streamSocialCauses() {
    if (!isFirebaseAvailable) return const Stream.empty();
    return _socialCausesCollection.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return SocialCauseItem.fromJson(data);
      }).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  /// Save or post a new social cause to Cloud Firestore
  Future<void> saveSocialCause(SocialCauseItem cause) async {
    if (!isFirebaseAvailable) return;
    try {
      await _socialCausesCollection.doc(cause.id).set(cause.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveSocialCause error: $e');
    }
  }

  /// Delete a social cause from Cloud Firestore
  Future<void> deleteSocialCause(String causeId) async {
    if (!isFirebaseAvailable) return;
    try {
      await _socialCausesCollection.doc(causeId).delete();
    } catch (e) {
      debugPrint('Firestore deleteSocialCause error: $e');
    }
  }

  /// Update approval status of a social cause in Cloud Firestore
  Future<void> updateSocialCauseStatus({
    required String causeId,
    required String status,
    required String approvedByName,
    required DateTime approvedAt,
  }) async {
    if (!isFirebaseAvailable) return;
    try {
      await _socialCausesCollection.doc(causeId).set({
        'status': status,
        'approvedByName': approvedByName,
        'approvedAt': approvedAt.toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore updateSocialCauseStatus error: $e');
    }
  }

  /// Update hearts count of a social cause in Cloud Firestore
  Future<void> updateSocialCauseHearts(String causeId, int heartsCount) async {
    if (!isFirebaseAvailable) return;
    try {
      await _socialCausesCollection.doc(causeId).set({
        'heartsCount': heartsCount,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore updateSocialCauseHearts error: $e');
    }
  }

  /// Update likedEmpIds of a social cause in Cloud Firestore
  Future<void> updateSocialCauseLikes(String causeId, List<String> likedEmpIds) async {
    if (!isFirebaseAvailable) return;
    try {
      await _socialCausesCollection.doc(causeId).set({
        'likedEmpIds': likedEmpIds,
        'heartsCount': likedEmpIds.length,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore updateSocialCauseLikes error: $e');
    }
  }

  /// Update likedStaffIds of a company notification in Cloud Firestore
  Future<void> updateCompanyNotificationLikes(String notifId, List<String> likedStaffIds) async {
    if (!isFirebaseAvailable) return;
    try {
      await _notificationsCollection.doc(notifId).set({
        'likedStaffIds': likedStaffIds,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore updateCompanyNotificationLikes error: $e');
    }
  }

  /// Update comments on a company notification in Cloud Firestore
  Future<void> updateCompanyNotificationComments(String notifId, List<NotificationComment> comments) async {
    if (!isFirebaseAvailable) return;
    try {
      await _notificationsCollection.doc(notifId).set({
        'comments': comments.map((c) => c.toJson()).toList(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore updateCompanyNotificationComments error: $e');
    }
  }

  /// Stream real-time company universal notifications (filtering out dead/empty documents)
  Stream<List<CompanyNotification>> streamCompanyNotifications() {
    if (!isFirebaseAvailable) return const Stream.empty();
    return _notificationsCollection.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            return CompanyNotification.fromJson(data);
          })
          .where((n) => n.isValid)
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  /// Save a new notification to Cloud Firestore
  Future<void> saveCompanyNotification(CompanyNotification notif) async {
    if (!isFirebaseAvailable) return;
    if (!isFirebaseAvailable || !notif.isValid) return;
    try {
      await _notificationsCollection.doc(notif.id).set(notif.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveCompanyNotification error: $e');
    }
  }

  /// Mark notification as read in Cloud Firestore (Guards against creating empty stub documents)
  Future<void> markNotificationRead(String notifId, [String? empId]) async {
    if (!isFirebaseAvailable) return;
    try {
      final docRef = _notificationsCollection.doc(notifId);
      final docSnap = await docRef.get();
      if (!docSnap.exists) {
        // Document does not exist in Firestore - do not create a blank stub
        return;
      }
      if (empId != null && empId.isNotEmpty) {
        await docRef.set({
          'readByStaffIds': FieldValue.arrayUnion([empId]),
        }, SetOptions(merge: true));
      } else {
        await docRef.set({
          'isRead': true,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Firestore markNotificationRead error: $e');
    }
  }

  /// Mark notification as dismissed for a particular user in Cloud Firestore
  Future<void> markNotificationDismissed(String notifId, String empId) async {
    if (!isFirebaseAvailable || empId.isEmpty) return;
    try {
      final docRef = _notificationsCollection.doc(notifId);
      final docSnap = await docRef.get();
      if (!docSnap.exists) {
        return;
      }
      await docRef.set({
        'dismissedByStaffIds': FieldValue.arrayUnion([empId]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore markNotificationDismissed error: $e');
    }
  }

  /// Purges corrupted/blank dead notifications from Cloud Firestore
  Future<void> purgeDeadNotifications() async {
    if (!isFirebaseAvailable) return;
    try {
      final snapshot = await _notificationsCollection.get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final title = data['title']?.toString().trim() ?? '';
        final content = data['content']?.toString().trim() ?? '';
        if (title.isEmpty && content.isEmpty) {
          await doc.reference.delete();
        }
      }
      await purgeExpiredCelebrations();
    } catch (e) {
      debugPrint('Firestore purgeDeadNotifications note: $e');
    }
  }

  /// Purges expired birthday and anniversary celebrations from Cloud Firestore so past celebrations are removed automatically
  Future<void> purgeExpiredCelebrations() async {
    if (!isFirebaseAvailable) return;
    try {
      final now = DateTime.now();
      final todayDateStr = '${now.year}_${now.month}_${now.day}';
      final snapshot = await _notificationsCollection.get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type']?.toString().toLowerCase() ?? '';
        final id = doc.id.toLowerCase();
        final isCeleb = type.contains('birthday') ||
            type.contains('anniversary') ||
            id.contains('celeb') ||
            id.contains('birthday') ||
            id.contains('anniversary');

        if (isCeleb) {
          final title = data['title']?.toString() ?? '';
          final content = data['content']?.toString() ?? '';
          if (type.contains('anniversary') || id.contains('anniversary') || title.toLowerCase().contains('anniversary')) {
            if (id.contains('mn-tl1002') || title.contains('Praveenkumar') || content.contains('Praveenkumar')) {
              await doc.reference.delete();
              continue;
            }
          }
          bool isExpired = true;
          if (doc.id.endsWith(todayDateStr)) {
            isExpired = false;
          } else {
            final ts = data['timestamp'];
            if (ts != null) {
              DateTime? docDate;
              if (ts is Timestamp) {
                docDate = ts.toDate();
              } else if (ts is String) {
                docDate = DateTime.tryParse(ts);
              }
              if (docDate != null &&
                  docDate.year == now.year &&
                  docDate.month == now.month &&
                  docDate.day == now.day) {
                isExpired = false;
              }
            }
          }
          if (isExpired) {
            await doc.reference.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Firestore purgeExpiredCelebrations note: $e');
    }
  }

  /// Permanently deletes a single personal notification from Cloud Firestore upon read
  Future<void> deleteCompanyNotification(String notifId) async {
    if (!isFirebaseAvailable) return;
    try {
      await _notificationsCollection.doc(notifId).delete();
    } catch (e) {
      debugPrint('Firestore deleteCompanyNotification error: $e');
    }
  }

  /// Erases operational datasets (notifications, social causes) from Firestore
  /// Keeps employee dossiers, credentials, departments, health metrics, and document vaults completely safe!
  Future<void> resetOperationalData() async {
    if (!isFirebaseAvailable) return;
    try {
      final notifsSnap = await _notificationsCollection.get();
      for (final doc in notifsSnap.docs) {
        await doc.reference.delete();
      }
      final causesSnap = await _socialCausesCollection.get();
      for (final doc in causesSnap.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Firestore resetOperationalData error: $e');
    }
  }

  /// Stream personal To-Dos across all devices for real-time staff & management sync
  Stream<List<TaskItem>> streamPersonalTodos() {
    if (!isFirebaseAvailable) return const Stream.empty();
    return _todosCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return TaskItem.fromMap(data);
      }).toList();
    });
  }

  /// Save or update a personal To-Do in Cloud Firestore
  Future<void> savePersonalTodo(TaskItem task) async {
    if (!isFirebaseAvailable) return;
    try {
      await _todosCollection.doc(task.id).set(task.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore savePersonalTodo error: $e');
    }
  }

  /// Delete a personal To-Do from Cloud Firestore
  Future<void> deletePersonalTodo(String taskId) async {
    if (!isFirebaseAvailable) return;
    try {
      await _todosCollection.doc(taskId).delete();
    } catch (e) {
      debugPrint('Firestore deletePersonalTodo error: $e');
    }
  }

  /// Stream real-time online orders
  Stream<List<OnlineOrderModel>> streamOnlineOrders() {
    if (!isFirebaseAvailable) return const Stream.empty();
    return _ordersCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['orderId'] = doc.id;
        return OnlineOrderModel.fromMap(data);
      }).toList();
    });
  }

  /// Save or update an online order in Cloud Firestore
  Future<void> saveOnlineOrder(OnlineOrderModel order) async {
    if (!isFirebaseAvailable) return;
    try {
      await _ordersCollection.doc(order.orderId).set(order.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveOnlineOrder error: $e');
    }
  }

  /// Delete an online order from Cloud Firestore
  Future<void> deleteOnlineOrder(String orderId) async {
    if (!isFirebaseAvailable) return;
    try {
      await _ordersCollection.doc(orderId).delete();
    } catch (e) {
      debugPrint('Firestore deleteOnlineOrder error: $e');
    }
  }

  /// Atomically approve a social cause using a transaction to prevent duplicate concurrent approvals
  Future<bool> approveSocialCauseAtomic({
    required String causeId,
    required String approvedByName,
    required String approverRole,
    required DateTime approvedAt,
  }) async {
    try {
      final docRef = _socialCausesCollection.doc(causeId);
      return await _firestore.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          return true; // Optimistic fallback if local-only
        }
        final data = snapshot.data();
        if (data != null && data['status'] == 'approved') {
          return false; // Already approved by another admin
        }
        transaction.set(docRef, {
          'status': 'approved',
          'approvedByName': approvedByName,
          'approvedAt': approvedAt.toIso8601String(),
        }, SetOptions(merge: true));
        return true;
      });
    } catch (e) {
      debugPrint('Firestore approveSocialCauseAtomic note: $e');
      return true; // Fallback to allowing local update
    }
  }

  /// Ensure FirebaseAuth has an active authenticated session (S-03: never create accounts on failure)
  Future<void> ensureFirebaseAuthSession(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();
    if (!cleanEmail.contains('@') || cleanPass.isEmpty) return;

    try {
      if (_auth.currentUser != null) return;
      await _auth.signInWithEmailAndPassword(email: cleanEmail, password: cleanPass);
    } catch (e) {
      debugPrint('Firebase Auth session note: $e');
    }
  }

  /// Stream the chat messages [empId] is allowed to see: All-Hands broadcasts,
  /// DMs sent to them and DMs they sent. Never the whole collection — other
  /// staff members' private conversations stay off this device.
  Stream<List<ChatMessage>> streamChatMessages(String empId) {
    if (!isFirebaseAvailable || empId.trim().isEmpty) return Stream.value([]);
    final me = empId.trim();
    final incoming = _chatsCollection
        .where('receiverId', whereIn: ['ALL_HANDS', me])
        .snapshots();
    final outgoing =
        _chatsCollection.where('senderId', isEqualTo: me).snapshots();

    late StreamController<List<ChatMessage>> controller;
    StreamSubscription? subIn;
    StreamSubscription? subOut;
    var latestIn = <ChatMessage>[];
    var latestOut = <ChatMessage>[];
    var gotIn = false;
    var gotOut = false;

    void emit() {
      if (!gotIn || !gotOut) return;
      final byId = <String, ChatMessage>{};
      for (final m in [...latestIn, ...latestOut]) {
        byId[m.id] = m;
      }
      final merged = byId.values.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      controller.add(merged);
    }

    List<ChatMessage> parse(QuerySnapshot<Map<String, dynamic>> snap) =>
        snap.docs.map((doc) => ChatMessage.fromJson(doc.data())).toList();

    controller = StreamController<List<ChatMessage>>(
      onListen: () {
        subIn = incoming.listen((snap) {
          latestIn = parse(snap);
          gotIn = true;
          emit();
        }, onError: controller.addError);
        subOut = outgoing.listen((snap) {
          latestOut = parse(snap);
          gotOut = true;
          emit();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await subIn?.cancel();
        await subOut?.cancel();
      },
    );
    return controller.stream;
  }

  /// Save a chat message to Cloud Firestore
  Future<void> saveChatMessage(ChatMessage message) async {
    if (!isFirebaseAvailable) return;
    final hasContent = message.text.trim().isNotEmpty || (message.attachmentUrl != null && message.attachmentUrl!.isNotEmpty);
    if (!isFirebaseAvailable || !hasContent) return;
    try {
      await _chatsCollection
          .doc(message.id)
          .set(message.toJson());
    } catch (e) {
      debugPrint('Firestore saveChatMessage error: $e');
    }
  }

  /// Mark chat message as read in Cloud Firestore
  Future<void> markChatMessageRead(String messageId, String empId) async {
    if (!isFirebaseAvailable || empId.trim().isEmpty) return;
    try {
      await _chatsCollection.doc(messageId).set({
        'isRead': true,
        'readBy': FieldValue.arrayUnion([empId.trim()]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore markChatMessageRead error: $e');
    }
  }

  /// Toggle like/reaction on chat message in Cloud Firestore
  Future<void> toggleChatMessageLike(String messageId, String empId) async {
    if (!isFirebaseAvailable || empId.trim().isEmpty) return;
    try {
      final docRef = _chatsCollection.doc(messageId);
      final docSnap = await docRef.get();
      if (!docSnap.exists) return;
      final currentLikes = (docSnap.data()?['likedBy'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      if (currentLikes.contains(empId)) {
        await docRef.update({
          'likedBy': FieldValue.arrayRemove([empId]),
        });
      } else {
        await docRef.update({
          'likedBy': FieldValue.arrayUnion([empId]),
        });
      }
    } catch (e) {
      debugPrint('Firestore toggleChatMessageLike error: $e');
    }
  }

  /// Add or remove one emoji reaction by [empId] on a chat message.
  Future<void> setChatReaction(String messageId, String empId, String emoji, bool add) async {
    if (!isFirebaseAvailable || empId.trim().isEmpty) return;
    final entry = '${empId.trim()}|$emoji';
    try {
      await _chatsCollection.doc(messageId).update({
        'reactions': add ? FieldValue.arrayUnion([entry]) : FieldValue.arrayRemove([entry]),
      });
    } catch (e) {
      debugPrint('Firestore setChatReaction error: $e');
    }
  }

  /// Pin a chat message in Cloud Firestore (with optional expiry date)
  Future<void> pinChatMessage(
    String messageId, {
    DateTime? until,
    required String pinnedBy,
  }) async {
    if (!isFirebaseAvailable || messageId.isEmpty) return;
    try {
      await _chatsCollection.doc(messageId).set({
        'isPinned': true,
        'pinnedUntil': until?.toIso8601String(),
        'pinnedBy': pinnedBy,
        'pinnedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore pinChatMessage error: $e');
    }
  }

  /// Unpin a chat message in Cloud Firestore
  Future<void> unpinChatMessage(String messageId) async {
    if (!isFirebaseAvailable || messageId.isEmpty) return;
    try {
      await _chatsCollection.doc(messageId).set({
        'isPinned': false,
        'pinnedUntil': null,
        'pinnedBy': null,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore unpinChatMessage error: $e');
    }
  }

  /// Stream live KONAR Books from Cloud Firestore
  Stream<List<KonarBookModel>> streamKonarBooks() {
    if (!isFirebaseAvailable) {
      return Stream.value([KonarBookModel.defaultOnlineDepartment()]);
    }
    return _konarBooksCollection.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return [KonarBookModel.defaultOnlineDepartment()];
      }
      final books = <KonarBookModel>[];
      for (final doc in snapshot.docs) {
        final book = KonarBookModel.fromJson({...doc.data(), 'id': doc.id});
        if (book.id == 'online_department' || book.id == 'online_dept' || book.department.toLowerCase().contains('online')) {
          if (book.sections.length != 5 || !book.sections.first.title.contains('01 PURPOSE')) {
            // Replace stale 6-chapter version with authentic 5 architectures
            final defaultBook = KonarBookModel.defaultOnlineDepartment();
            books.add(defaultBook);
            _konarBooksCollection.doc(doc.id).set(defaultBook.toJson(), SetOptions(merge: false));
            continue;
          }
        }
        books.add(book);
      }
      return books.isNotEmpty ? books : [KonarBookModel.defaultOnlineDepartment()];
    });
  }

  /// Fetch KONAR Books from Cloud Firestore (auto-seeding default if empty)
  Future<List<KonarBookModel>> getKonarBooks() async {
    if (!isFirebaseAvailable) {
      return [KonarBookModel.defaultOnlineDepartment()];
    }
    try {
      final snapshot = await _konarBooksCollection.get();
      if (snapshot.docs.isEmpty) {
        final defaultBook = KonarBookModel.defaultOnlineDepartment();
        await saveKonarBook(defaultBook);
        return [defaultBook];
      }
      final books = <KonarBookModel>[];
      for (final doc in snapshot.docs) {
        final book = KonarBookModel.fromJson({...doc.data(), 'id': doc.id});
        if (book.id == 'online_department' || book.id == 'online_dept' || book.department.toLowerCase().contains('online')) {
          if (book.sections.length != 5 || !book.sections.first.title.contains('01 PURPOSE')) {
            final defaultBook = KonarBookModel.defaultOnlineDepartment();
            books.add(defaultBook);
            _konarBooksCollection.doc(doc.id).set(defaultBook.toJson(), SetOptions(merge: false));
            continue;
          }
        }
        books.add(book);
      }
      return books.isNotEmpty ? books : [KonarBookModel.defaultOnlineDepartment()];
    } catch (_) {
      return [KonarBookModel.defaultOnlineDepartment()];
    }
  }

  /// Persist KONAR Book changes to Cloud Firestore with automatic subcollection chunking for PDFs
  Future<void> saveKonarBook(KonarBookModel book, {void Function(double progress)? onProgress}) async {
    if (!isFirebaseAvailable) return;
    try {
      final String? base64Data = book.pdfBase64;
      final bool hasNewPdf = base64Data != null && base64Data.isNotEmpty;

      int totalChunks = book.totalPdfChunks ?? 0;
      int fileSize = book.pdfFileSize ?? 0;

      if (hasNewPdf) {
        fileSize = base64Data.length;
        // 400 KB per chunk (approx 409,600 chars), safely under Firestore's 1 MB limit per document
        const int chunkSize = 400 * 1024;
        totalChunks = (base64Data.length / chunkSize).ceil();

        final chunksRef = _konarBooksCollection.doc(book.id).collection('pdf_chunks');

        // Delete any existing chunks first to prevent stale residue
        try {
          final oldChunks = await chunksRef.get();
          if (oldChunks.docs.isNotEmpty) {
            final deleteBatch = _firestore.batch();
            for (final doc in oldChunks.docs) {
              deleteBatch.delete(doc.reference);
            }
            await deleteBatch.commit();
          }
        } catch (e) {
          debugPrint('Note clearing old pdf_chunks: $e');
        }

        // Write chunks in small batches of 4 (approx 1.6 MB per batch, well under Firestore's 10 MB payload limit)
        const int batchSize = 4;
        for (int i = 0; i < totalChunks; i += batchSize) {
          final batch = _firestore.batch();
          final end = (i + batchSize < totalChunks) ? i + batchSize : totalChunks;

          for (int j = i; j < end; j++) {
            final startIdx = j * chunkSize;
            final endIdx = (startIdx + chunkSize < base64Data.length)
                ? startIdx + chunkSize
                : base64Data.length;
            final chunkStr = base64Data.substring(startIdx, endIdx);

            final chunkDoc = chunksRef.doc('chunk_$j');
            batch.set(chunkDoc, {
              'index': j,
              'data': chunkStr,
              'size': chunkStr.length,
              'total': totalChunks,
            });
          }

          await batch.commit();

          if (onProgress != null) {
            onProgress(end / totalChunks);
          }
        }
      }

      // Save main book metadata (WITHOUT large base64 payload to prevent 1MB overflow)
      final bookData = book.toJson(includePdfBase64: false);
      bookData.remove('pdfBase64');
      bookData['hasPdfAttachment'] = hasNewPdf || book.hasPdfAttachment;
      bookData['totalPdfChunks'] = totalChunks > 0 ? totalChunks : book.totalPdfChunks;
      bookData['pdfFileSize'] = fileSize > 0 ? fileSize : book.pdfFileSize;

      await _konarBooksCollection.doc(book.id).set(bookData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveKonarBook error: $e');
      rethrow;
    }
  }

  /// Load and assemble PDF binary bytes from chunked Firestore subcollection
  Future<Uint8List?> loadKonarBookPdfBytes(String bookId) async {
    if (!isFirebaseAvailable) return null;
    try {
      final chunksRef = _konarBooksCollection.doc(bookId).collection('pdf_chunks');
      final snapshot = await chunksRef.orderBy('index').get();

      if (snapshot.docs.isEmpty) return null;

      final buffer = StringBuffer();
      for (final doc in snapshot.docs) {
        final chunkData = doc.data()['data']?.toString() ?? '';
        buffer.write(chunkData);
      }

      final fullBase64 = buffer.toString();
      if (fullBase64.isEmpty) return null;

      final commaIdx = fullBase64.indexOf(',');
      final cleanBase64 = commaIdx != -1 ? fullBase64.substring(commaIdx + 1) : fullBase64;
      return base64Decode(cleanBase64);
    } catch (e) {
      debugPrint('Firestore loadKonarBookPdfBytes error: $e');
      return null;
    }
  }
}
