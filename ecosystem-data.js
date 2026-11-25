/**
 * MN FAMILY - EXECUTIVE OPERATIONAL HUB & NERVE CENTER DATA STORE
 * 
 * Implements 8 Cross-Department Pillars:
 * 1. Inter-Department Handover Pipeline (Workshop -> Assay QA -> Showroom)
 * 2. Cross-Department Blocker & Escalation System
 * 3. CEO Executive Shift Closing & Compliance Index
 * 4. CEO Direct Universal Push Directive
 * 5. 10:00 AM Store Opening "Readiness Gate"
 * 6. Incident & Discrepancy Dispatch (Multi-dept action)
 * 7. Shift Handover & Digital Co-Sign
 * 8. Repeat Delay Pattern & Root Cause Analytics
 * 
 * Plus:
 * - Excel (.CSV) Data Export for CEO/HR Audit
 * - Graphical Charts & Analytics Metrics
 */

const MN_STORE_KEY = 'mn_family_ecosystem_v3';

// Default Departments & SOP Templates
const SOP_TEMPLATES = {
  'Operations': [
    { title: 'Daily 22K/24K Gold Vault Weight Reconciliation', category: 'Vault & Purity Assay', priority: 'Critical SLA', due: '11:00 AM' },
    { title: 'BIS 916 Hallmark & 6-Digit HUID Laser Verification', category: 'BIS 916 Hallmarking', priority: 'Critical SLA', due: '02:30 PM' },
    { title: 'Filigree & Stone Setting Microscope Quality Check', category: 'Quality Assay', priority: 'High', due: '04:30 PM' },
    { title: 'Evening Gold Craft Waste & Sweepings Recovery Log', category: 'Loss Prevention', priority: 'Standard', due: '06:45 PM' }
  ],
  'Sales': [
    { title: 'Morning Velvet Counter Tray Sanitization & Lighting Check', category: 'Showroom SOP', priority: 'High', due: '09:45 AM' },
    { title: 'Customer Gold Savings Scheme & KYC Verification', category: 'Customer Relations', priority: 'Standard', due: '01:00 PM' },
    { title: 'High-Value Bridal Choker & Diamond Solitaire Presentation SOP', category: 'Luxury Sales', priority: 'Critical SLA', due: '04:00 PM' },
    { title: 'End-of-Day POS Cash/Card & Physical Stock Balance', category: 'Financial Audit', priority: 'Critical SLA', due: '07:30 PM' }
  ],
  'Housekeeping': [
    { title: 'Morning Deep Clean: Velvet Display Glass & Mirror Polish', category: 'Hygiene & Ambience', priority: 'High', due: '09:15 AM' },
    { title: 'VIP Lounge Refreshment & Fragrance Diffuser Refill', category: 'Guest Hospitality', priority: 'Standard', due: '11:30 AM' },
    { title: 'Mid-Day Vault Entrance & Floor Dust-Free Sanitization', category: 'Facility Maintenance', priority: 'High', due: '02:00 PM' },
    { title: 'Evening Waste Clearance with Security Dual-Witness Check', category: 'Security Protocol', priority: 'Critical SLA', due: '07:00 PM' }
  ],
  'Vault': [
    { title: 'Morning Dual-Biometric Vault Opening & Logbook Signature', category: 'Vault Security', priority: 'Critical SLA', due: '09:30 AM' },
    { title: 'Ingot Bar Serial Number Assay & Inward Requisition Verification', category: 'Bullion Inward', priority: 'High', due: '12:00 PM' },
    { title: 'Inter-Department Gold Handover Escort & Transit Custody', category: 'Transit Protocol', priority: 'High', due: '03:30 PM' },
    { title: 'Night Vault Seal & CCTV 360-degree Clearance Sign-off', category: 'Vault Security', priority: 'Critical SLA', due: '07:45 PM' }
  ],
  'Finance': [
    { title: 'Daily Gold Trading Base Rate Sync (₹6,805/g 916)', category: 'Bullion Pricing', priority: 'Critical SLA', due: '09:30 AM' },
    { title: 'Supplier Bullion Invoices & GST Tax Reconciliation', category: 'Accounts Payable', priority: 'High', due: '02:00 PM' },
    { title: 'Daily Advance Booking Ledger Verification', category: 'Audit', priority: 'Standard', due: '05:00 PM' }
  ]
};

// Initial Clean Corporate Seed Data (Master CEO Account + 12 Official Konar Book Roles)
const DEFAULT_ECOSYSTEM_DATA = {
  employees: [
    {
      id: 'MN-CEO01',
      name: 'M N Naveenraaj',
      role: 'Managing Director & CEO',
      roleType: 'ceo',
      dept: 'Executive Board',
      phone: '+91 98450 00001',
      email: 'ceoofmn@mnjpark.com',
      avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=200',
      initials: 'MN',
      doj: '2020-01-01',
      experienceYears: '25 yrs in Fine Jewellery & Luxury Retail',
      experienceCategory: 'experienced',
      probationWeeks: 0,
      probationStatus: 'cleared',
      probationEndDate: '2020-01-01',
      password: '', // never stored here; sign-in uses Firebase Authentication
      dob: '1980-05-15',
      relationshipStatus: 'Married',
      anniversaryDate: '2008-11-20',
      trainer: { name: 'Executive Board', role: 'Board of Directors' },
      profileCompletion: {
        percentage: 100,
        isAuthorized: true,
        photoVerified: true,
        addressVerified: true,
        kycVerified: true,
        sopRolesAcknowledged: true,
        authorizedDate: '2020-01-01'
      },
      status: 'active',
      ragStatus: 'green',
      lastActive: 'Active now'
    },
    {
      id: 'MN-HR01',
      name: 'Mohankumar G',
      role: 'Head of Human Resources',
      roleType: 'hr',
      dept: 'HR & People Ops',
      phone: '+91 94433 11000',
      email: 'hr@mnj.com',
      avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=200',
      initials: 'MG',
      doj: '2021-03-01',
      experienceYears: '8 yrs HR Management',
      experienceCategory: 'experienced',
      probationWeeks: 0,
      probationStatus: 'cleared',
      probationEndDate: 'Completed',
      password: '', // never stored here; sign-in uses Firebase Authentication
      dob: '1992-04-10',
      relationshipStatus: 'Married',
      anniversaryDate: '2019-06-12',
      trainer: { name: 'Executive CEO', role: 'Managing Director' },
      profileCompletion: { percentage: 100, isAuthorized: true, photoVerified: true, addressVerified: true, kycVerified: true, sopRolesAcknowledged: true },
      status: 'active',
      ragStatus: 'green',
      lastActive: 'Active now'
    },
    {
      id: 'MN-OTM01',
      name: 'Mr. M. Praveen Kumar',
      role: 'Team Lead (OTM)',
      roleType: 'team_lead',
      dept: 'Operations',
      phone: '+91 98450 11001',
      email: 'praveenkumarotm@mnj.com',
      avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=200',
      initials: 'PK',
      doj: '2021-06-15',
      experienceYears: '6 yrs in Store Operations',
      experienceCategory: 'experienced',
      probationWeeks: 0,
      probationStatus: 'cleared',
      probationEndDate: 'Completed',
      password: '', // never stored here; sign-in uses Firebase Authentication
      dob: '1994-08-22',
      relationshipStatus: 'Single',
      trainer: { name: 'Executive CEO', role: 'Managing Director' },
      profileCompletion: { percentage: 100, isAuthorized: true, photoVerified: true, addressVerified: true, kycVerified: true, sopRolesAcknowledged: true },
      status: 'active',
      ragStatus: 'green',
      lastActive: 'Active now'
    },
    {
      id: 'MN-OSH01',
      name: 'Mr. K. Gokulakrishnan',
      role: 'Online Sale Head (OSH)',
      roleType: 'employee',
      dept: 'Sales',
      phone: '+91 98450 11002',
      email: 'gokulakrishnanosh@mnj.com',
      avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=200',
      initials: 'GK',
      doj: '2022-01-10',
      experienceYears: '5 yrs Luxury Jewellery Sales',
      experienceCategory: 'experienced',
      probationWeeks: 0,
      probationStatus: 'cleared',
      probationEndDate: 'Completed',
      password: '', // never stored here; sign-in uses Firebase Authentication
      dob: '1995-12-05',
      relationshipStatus: 'Married',
      anniversaryDate: '2022-02-14',
      trainer: { name: 'Mr. M. Praveen Kumar', role: 'Team Lead' },
      profileCompletion: { percentage: 100, isAuthorized: true, photoVerified: true, addressVerified: true, kycVerified: true, sopRolesAcknowledged: true },
      status: 'active',
      ragStatus: 'green',
      lastActive: 'Active now'
    },
    {
      id: 'MN-VPE01',
      name: 'Mr. Y. Aravinda Samy',
      role: 'Chief Photographer & Video Editor (VPE)',
      roleType: 'employee',
      dept: 'Media',
      phone: '+91 98450 11003',
      email: 'aravindasamyvpe@mnj.com',
      avatar: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&q=80&w=200',
      initials: 'AS',
      doj: '2022-04-01',
      experienceYears: '4 yrs Jewelry Cinematography',
      experienceCategory: 'experienced',
      probationWeeks: 0,
      probationStatus: 'cleared',
      probationEndDate: 'Completed',
      password: '', // never stored here; sign-in uses Firebase Authentication
      dob: '1996-03-18',
      relationshipStatus: 'Single',
      trainer: { name: 'Mr. M. Praveen Kumar', role: 'Team Lead' },
      profileCompletion: { percentage: 100, isAuthorized: true, photoVerified: true, addressVerified: true, kycVerified: true, sopRolesAcknowledged: true },
      status: 'active',
      ragStatus: 'green',
      lastActive: 'Active now'
    },
    {
      id: 'MN-AVPE01',
      name: 'Mrs. M. Mithra',
      role: 'Assistant Photographer & Videographer (Ass.VPE)',
      roleType: 'employee',
      dept: 'Media',
      phone: '+91 98450 11004',
      email: 'mithraassvpe@mnj.com',
      avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=200',
      initials: 'MM',
      doj: '2022-07-15',
      experienceYears: '3 yrs Media Production',
      experienceCategory: 'experienced',
      probationWeeks: 0,
      probationStatus: 'cleared',
      probationEndDate: 'Completed',
      password: '', // never stored here; sign-in uses Firebase Authentication
      dob: '1997-09-25',
      relationshipStatus: 'Married',
      anniversaryDate: '2023-01-20',
      trainer: { name: 'Mr. Y. Aravinda Samy', role: 'VPE' },
      profileCompletion: { percentage: 100, isAuthorized: true, photoVerified: true, addressVerified: true, kycVerified: true, sopRolesAcknowledged: true },
      status: 'active',
      ragStatus: 'green',
      lastActive: 'Active now'
    },
    {
      id: 'MN-ECE01',
      name: 'E-Commerce Executive',
      role: 'E-Commerce Executive (ECE)',
      roleType: 'employee',
      dept: 'Technology',
      phone: '+91 98450 11005',
      email: 'ece@mnj.com',
      avatar: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&q=80&w=200',
      initials: 'EC',
      doj: '2022-09-01',
      experienceYears: '3 yrs Catalog & Inventory Ops',
      experienceCategory: 'experienced',
      probationWeeks: 0,
      probationStatus: 'cleared',
      probationEndDate: 'Completed',
      password: '', // never stored here; sign-in uses Firebase Authentication
      dob: '1996-11-14',
      relationshipStatus: 'Single',
      trainer: { name: 'Mr. M. Praveen Kumar', role: 'Team Lead' },
      profileCompletion: { percentage: 100, isAuthorized: true, photoVerified: true, addressVerified: true, kycVerified: true, sopRolesAcknowledged: true },
      status: 'active',
      ragStatus: 'green',
      lastActive: 'Active now'
    },
    {
      id: 'MN-OS101',
      name: 'Ms. Kaaviya',
      role: 'Online Sale Person 1 (OS1)',
      roleType: 'employee',
      dept: 'Sales',
      phone: '+91 98450 11006',
      email: 'kaaviyaos1@mnj.com',
      avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
      initials: 'MK',
      doj: '2023-01-05',
      experienceYears: '2.5 yrs Luxury Jewelry Consultation',
      experienceCategory: 'experienced',
      probationWeeks: 0,
      probationStatus: 'cleared',
      probationEndDate: 'Completed',
      password: '', // never stored here; sign-in uses Firebase Authentication
      dob: '1998-02-18',
      relationshipStatus: 'Single',
      trainer: { name: 'Mr. K. Gokulakrishnan', role: 'OSH' },
      profileCompletion: { percentage: 100, isAuthorized: true, photoVerified: true, addressVerified: true, kycVerified: true, sopRolesAcknowledged: true },
      status: 'active',
      ragStatus: 'green',
      lastActive: 'Active now'
    },
    {
      id: 'MN-OS201',
      name: 'Ms. Nisha',
      role: 'Online Sale Person 2 (OS2)',
      roleType: 'employee',
      dept: 'Sales',
      phone: '+91 98450 11007',
      email: 'nishaos2@mnj.com',
      avatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&q=80&w=200',
      initials: 'MN',
      doj: '2023-02-10',
      experienceYears: '2 yrs Jewelry Consultation',
      experienceCategory: 'experienced',
      probationWeeks: 0,
      probationStatus: 'cleared',
      probationEndDate: 'Completed',
      password: '', // never stored here; sign-in uses Firebase Authentication
      dob: '1999-07-30',
      relationshipStatus: 'Single',
      trainer: { name: 'Mr. K. Gokulakrishnan', role: 'OSH' },
      profileCompletion: { percentage: 100, isAuthorized: true, photoVerified: true, addressVerified: true, kycVerified: true, sopRolesAcknowledged: true },
      status: 'active',
      ragStatus: 'green',
      lastActive: 'Active now'
    },
    {
      id: 'MN-AC01',
      name: 'Mr. J. Midhun Kumar',
      role: 'Online Analytical Consultant (AC)',
      roleType: 'employee',
      dept: 'Accounts',
      phone: '+91 98450 11008',
      email: 'midhunkumarac@mnj.com',
      avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=200',
      initials: 'MK',
      doj: '2023-03-01',
      experienceYears: '4 yrs Financial & Inventory Auditing',
      experienceCategory: 'experienced',
      probationWeeks: 0,
      probationStatus: 'cleared',
      probationEndDate: 'Completed',
      password: '', // never stored here; sign-in uses Firebase Authentication
      dob: '1995-10-12',
      relationshipStatus: 'Married',
      anniversaryDate: '2021-05-18',
      trainer: { name: 'Mr. M. Praveen Kumar', role: 'Team Lead' },
      profileCompletion: { percentage: 100, isAuthorized: true, photoVerified: true, addressVerified: true, kycVerified: true, sopRolesAcknowledged: true },
      status: 'active',
      ragStatus: 'green',
      lastActive: 'Active now'
    },
    {
      id: 'MN-OSS01',
      name: 'Mr. Subash',
      role: 'Online Support & Strategist (OSS)',
      roleType: 'employee',
      dept: 'Operations',
      phone: '+91 98450 11009',
      email: 'subashoss@mnj.com',
      avatar: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?auto=format&fit=crop&q=80&w=200',
      initials: 'MS',
      doj: '2023-04-15',
      experienceYears: '3 yrs Dispatch & Packaging Logistics',
      experienceCategory: 'experienced',
      probationWeeks: 0,
      probationStatus: 'cleared',
      probationEndDate: 'Completed',
      password: '', // never stored here; sign-in uses Firebase Authentication
      dob: '1997-06-08',
      relationshipStatus: 'Single',
      trainer: { name: 'Mr. M. Praveen Kumar', role: 'Team Lead' },
      profileCompletion: { percentage: 100, isAuthorized: true, photoVerified: true, addressVerified: true, kycVerified: true, sopRolesAcknowledged: true },
      status: 'active',
      ragStatus: 'green',
      lastActive: 'Active now'
    },
    {
      id: 'MN-DVP01',
      name: 'Mr. K.B. Eshwar',
      role: 'Developer (DVP)',
      roleType: 'employee',
      dept: 'Technology',
      phone: '+91 98450 11010',
      email: 'eshwardvp@mnj.com',
      avatar: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?auto=format&fit=crop&q=80&w=200',
      initials: 'KE',
      doj: '2023-05-01',
      experienceYears: '4 yrs Fullstack Development & Shopify ERP',
      experienceCategory: 'experienced',
      probationWeeks: 0,
      probationStatus: 'cleared',
      probationEndDate: 'Completed',
      password: '', // never stored here; sign-in uses Firebase Authentication
      dob: '1996-01-28',
      relationshipStatus: 'Single',
      trainer: { name: 'Mr. M. Praveen Kumar', role: 'Team Lead' },
      profileCompletion: { percentage: 100, isAuthorized: true, photoVerified: true, addressVerified: true, kycVerified: true, sopRolesAcknowledged: true },
      status: 'active',
      ragStatus: 'green',
      lastActive: 'Active now'
    },
    {
      id: 'MN-CC01',
      name: 'Mr. Sam Roy',
      role: 'Content Creator (CC)',
      roleType: 'employee',
      dept: 'Media',
      phone: '+91 98450 11011',
      email: 'samroycc@mnj.com',
      avatar: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&q=80&w=200',
      initials: 'SR',
      doj: '2023-06-01',
      experienceYears: '3 yrs Social Media & Copywriting',
      experienceCategory: 'experienced',
      probationWeeks: 0,
      probationStatus: 'cleared',
      probationEndDate: 'Completed',
      password: '', // never stored here; sign-in uses Firebase Authentication
      dob: '1998-08-19',
      relationshipStatus: 'Single',
      trainer: { name: 'Mr. Y. Aravinda Samy', role: 'VPE' },
      profileCompletion: { percentage: 100, isAuthorized: true, photoVerified: true, addressVerified: true, kycVerified: true, sopRolesAcknowledged: true },
      status: 'active',
      ragStatus: 'green',
      lastActive: 'Active now'
    }
  ],

  tasks: [],
  handovers: [],
  blockers: [],

  readinessGate: {
    status: 'Pending Setup (0/6 Signed)',
    targetTime: '10:00 AM',
    signedCount: 0,
    totalCount: 6,
    depts: [
      { name: 'Housekeeping', task: 'Floor deep-clean & velvet glass mirror polish verified', signed: false, signedBy: '', time: '--' },
      { name: 'Vault & Logistics', task: 'Morning display trays issued to counters', signed: false, signedBy: '', time: '--' },
      { name: 'Security & CCTV', task: '360° CCTV scan & emergency exit sensor clearance', signed: false, signedBy: '', time: '--' },
      { name: 'Operations & Assay', task: 'Digital 0.001g scales calibrated & hallmarking active', signed: false, signedBy: '', time: '--' },
      { name: 'Showroom Sales', task: 'Staff groomed, velvet spotlights calibrated to 4000K', signed: false, signedBy: '', time: '--' },
      { name: 'Finance & Accounts', task: 'Daily 22K gold rate synchronized on billing', signed: false, signedBy: '', time: '--' }
    ]
  },

  incidents: [],
  shiftHandovers: [],

  delayAnalytics: {
    totalPostponedMonth: 0,
    rootCauses: []
  },

  emergencyDelegations: []
};

// Storage Class
class MNEcosystemStore {
  constructor() {
    this.data = this.loadData();
  }

  loadData() {
    try {
      const raw = localStorage.getItem(MN_STORE_KEY);
      if (raw) {
        return JSON.parse(raw);
      }
    } catch (e) {
      console.warn('Could not parse stored data, resetting', e);
    }
    this.saveData(DEFAULT_ECOSYSTEM_DATA);
    return JSON.parse(JSON.stringify(DEFAULT_ECOSYSTEM_DATA));
  }

  saveData(data = this.data) {
    try {
      localStorage.setItem(MN_STORE_KEY, JSON.stringify(data));
      this.data = data;
    } catch (e) {
      console.error('Error saving data', e);
    }
  }

  getCurrentEmployee(empId = 'MN-1024') {
    return this.data.employees.find(e => e.id === empId) || this.data.employees[0];
  }

  getTasksForEmployee(empId = 'MN-1024') {
    return this.data.tasks.filter(t => t.empId === empId);
  }

  getAllEmployees() {
    return this.data.employees;
  }

  getAllTasks() {
    return this.data.tasks;
  }

  // 1. Inter-Department Handover
  advanceHandover(handoverId) {
    const ho = this.data.handovers.find(h => h.id === handoverId);
    if (!ho) return false;

    const inProgressStep = ho.steps.find(s => s.status === 'in_progress');
    if (inProgressStep) {
      inProgressStep.status = 'done';
      const nextStep = ho.steps.find(s => s.status === 'pending');
      if (nextStep) {
        nextStep.status = 'in_progress';
        ho.stage = `${nextStep.name} (${nextStep.dept})`;
      } else {
        ho.status = 'completed';
        ho.stage = '✓ Handover Chain Completed';
      }
      this.saveData();
      return true;
    }
    return false;
  }

  // 2. Raise Cross-Department Blocker
  raiseBlocker({ raisedByDept, raisedByName, blockingDept, issue }) {
    const newBlk = {
      id: `BLK-${Date.now()}`,
      raisedByDept,
      raisedByName,
      blockingDept,
      issue,
      severity: 'Critical SLA',
      status: 'active',
      time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    };
    this.data.blockers.unshift(newBlk);
    this.saveData();
    return newBlk;
  }

  resolveBlocker(blockerId) {
    const blk = this.data.blockers.find(b => b.id === blockerId);
    if (blk) {
      blk.status = 'resolved';
      this.saveData();
      return true;
    }
    return false;
  }

  // 6. Log Incident
  logIncident({ title, reportedBy, dispatchedTo, severity }) {
    const newInc = {
      id: `INC-${Date.now()}`,
      title,
      reportedBy,
      dispatchedTo: dispatchedTo || 'Facility Maintenance',
      severity: severity || 'High',
      status: 'active',
      time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      resolution: null
    };
    this.data.incidents.unshift(newInc);
    this.saveData();
    return newInc;
  }

  // Task Completion with Proof
  completeTaskWithProof(taskId, proofData) {
    const task = this.data.tasks.find(t => t.id === taskId);
    if (!task) return false;

    task.status = 'completed';
    task.proof = {
      type: proofData.type || 'photo',
      content: proofData.content || 'Proof submitted and verified.',
      photoUrl: proofData.photoUrl || 'https://images.unsplash.com/photo-1610375461246-83df859d849d?auto=format&fit=crop&q=80&w=300',
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    };
    task.postponeInfo = null;

    this.saveData();
    return task;
  }

  // Task Postponement / Reason
  postponeTaskWithReason(taskId, reason, postponeTo) {
    const task = this.data.tasks.find(t => t.id === taskId);
    if (!task) return false;

    task.status = 'postponed';
    task.postponeInfo = {
      reason: reason.trim(),
      postponedTo: postponeTo || 'Tomorrow',
      postponedAt: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    };

    this.saveData();
    return task;
  }

  // Task Assignment
  assignTask({ empId, title, category, priority, due, assignerRole, assignerName }) {
    const newTask = {
      id: `TSK-${Date.now()}`,
      empId,
      title,
      category: category || (assignerRole === 'ceo' ? 'CEO Directive' : 'Lead Assignment'),
      isDefaultSop: false,
      assignedBy: { role: assignerRole, name: assignerName },
      due: due || '06:00 PM',
      priority: priority || 'High',
      status: 'pending',
      proof: null,
      immutable: true
    };

    this.data.tasks.unshift(newTask);
    this.saveData();
    return newTask;
  }

  // Emergency Leave Task Delegation
  delegateEmergencyLeaveTasks({ leaveEmpId, replacementEmpId, reason }) {
    const leaveEmp = this.data.employees.find(e => e.id === leaveEmpId);
    const repEmp = this.data.employees.find(e => e.id === replacementEmpId);

    if (!leaveEmp || !repEmp) return false;

    const pendingTasks = this.data.tasks.filter(t => t.empId === leaveEmpId && t.status !== 'completed');
    let delegatedCount = 0;

    pendingTasks.forEach(task => {
      task.empId = replacementEmpId;
      task.delegatedFrom = {
        originalEmpId: leaveEmpId,
        originalName: leaveEmp.name,
        reason: reason || 'Emergency Leave Coverage',
        delegatedAt: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
      };
      delegatedCount++;
    });

    const record = {
      id: `DEL-${Date.now()}`,
      fromEmp: leaveEmp.name,
      toEmp: repEmp.name,
      taskCount: delegatedCount,
      reason: reason || 'Emergency Medical / Personal Leave',
      date: new Date().toLocaleDateString()
    };

    this.data.emergencyDelegations.unshift(record);
    this.saveData();
    return record;
  }

  // 100% Profile Authorization
  authorizeUserProfile(empId = 'MN-1024') {
    const emp = this.data.employees.find(e => e.id === empId);
    if (!emp) return false;

    emp.profileCompletion = {
      percentage: 100,
      isAuthorized: true,
      photoVerified: true,
      addressVerified: true,
      kycVerified: true,
      sopRolesAcknowledged: true,
      authorizedDate: new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
    };
    emp.status = 'active';

    this.saveData();
    return emp;
  }

  // Add Employee (Restricted to HR)
  addNewEmployee({ name, role, roleType, dept, phone, email, experienceCategory, experienceYears, trainerName }) {
    const isFresher = experienceCategory === 'fresher';
    const initials = name.split(' ').map(e => e ? e[0] : '').slice(0, 2).join('').toUpperCase();
    const newEmp = {
      id: `MN-${1100 + this.data.employees.length}`,
      name,
      role: role || (roleType === 'team_lead' ? 'Operations Team Lead' : 'Operations Executive'),
      roleType: roleType || 'employee',
      dept: dept || 'Operations',
      phone: phone || '',
      email: email || 'staff@mnj.com',
      avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=200',
      initials: initials || 'EM',
      doj: 'Today',
      experienceYears: experienceYears || 'Confirmed Corporate Staff',
      experienceCategory: experienceCategory || 'standard',
      probationWeeks: 0,
      probationStatus: 'cleared',
      probationEndDate: 'Completed',
      trainer: { name: trainerName || 'Praveen Kumar', role: 'Team Lead' },
      profileCompletion: {
        percentage: 100,
        isAuthorized: true,
        photoVerified: true,
        addressVerified: true,
        kycVerified: true,
        sopRolesAcknowledged: true
      },
      status: 'active',
      ragStatus: 'green',
      lastActive: 'Just registered'
    };
    this.data.employees.unshift(newEmp);
    this.saveData();
    return newEmp;
  }

  // Remove Employee (Restricted to HR)
  removeEmployee(empId) {
    const idx = this.data.employees.findIndex(e => e.id === empId);
    if (idx !== -1) {
      const removed = this.data.employees.splice(idx, 1)[0];
      this.saveData();
      return removed;
    }
    return null;
  }

  // EXCEL (.CSV) DATA DOWNLOAD GENERATOR
  exportTasksToCSV() {
    const tasks = this.data.tasks;
    const emps = this.data.employees;

    let csvContent = 'Task ID,Employee ID,Employee Name,Department,Task Title,Category,Priority,Due Time,Status,Proof Note,Postpone Reason,Postponed Target\n';

    tasks.forEach(t => {
      const emp = emps.find(e => e.id === t.empId) || { name: 'Staff', dept: 'Operations' };
      const proofNote = t.proof ? `"${(t.proof.content || '').replace(/"/g, '""')}"` : '""';
      const postponeReason = t.postponeInfo ? `"${(t.postponeInfo.reason || '').replace(/"/g, '""')}"` : '""';
      const postponeTarget = t.postponeInfo ? `"${t.postponeInfo.postponedTo || ''}"` : '""';

      csvContent += `${t.id},${t.empId},"${emp.name}","${emp.dept}","${t.title.replace(/"/g, '""')}","${t.category}","${t.priority}","${t.due}","${t.status}",${proofNote},${postponeReason},${postponeTarget}\n`;
    });

    this.triggerDownloadBlob(csvContent, `MN_JewelPark_Tasks_Audit_${new Date().toISOString().split('T')[0]}.csv`);
  }

  exportDepartmentComplianceCSV() {
    let csvContent = 'Department,Total Staff,SOP Tasks,Completed Proofs,Postponed Tasks,Compliance Rate %,RAG Health Status\n';
    const depts = [
      { name: 'Operations & Crafting', staff: 34, total: 112, completed: 98, postponed: 2, pct: '88%', health: 'Green' },
      { name: 'Showroom Sales', staff: 48, total: 140, completed: 129, postponed: 1, pct: '92%', health: 'Green' },
      { name: 'Housekeeping & Facility', staff: 14, total: 42, completed: 42, postponed: 0, pct: '100%', health: 'Green' },
      { name: 'Vault & Logistics', staff: 18, total: 54, completed: 52, postponed: 0, pct: '96%', health: 'Green' },
      { name: 'Finance & Accounts', staff: 12, total: 36, completed: 34, postponed: 0, pct: '94%', health: 'Green' }
    ];

    depts.forEach(d => {
      csvContent += `"${d.name}",${d.staff},${d.total},${d.completed},${d.postponed},${d.pct},"${d.health}"\n`;
    });

    this.triggerDownloadBlob(csvContent, `MN_JewelPark_Dept_Compliance_${new Date().toISOString().split('T')[0]}.csv`);
  }

  exportBiometricAttendanceCSV() {
    const list = this.getTodayBiometricAttendance();
    let csvContent = 'Employee ID,Staff Name,Department,Role,Shift In Time,Lunch Out Time,Lunch In Time,Lunch Duration (Mins),Shift Out Time,Net Hours Worked,Status\n';
    list.forEach(item => {
      csvContent += `"${item.id}","${item.name}","${item.dept}","${item.role}","${item.inTime}","${item.lunchOut}","${item.lunchIn}",${item.lunchDurationMins},"${item.outTime}","${item.netHours}","${item.status}"\n`;
    });
    this.triggerDownloadBlob(csvContent, `eSSL_Attendance_Roster_${new Date().toISOString().split('T')[0]}.csv`);
  }

  getTodayBiometricAttendance() {
    return [
      { id: 'MN-1024', name: 'Adithi Sharma', dept: 'Operations', role: 'Fine Jewellery Operations Executive', inTime: '09:14 AM', lunchOut: '--', lunchIn: '--', lunchDurationMins: 0, outTime: 'On Duty', netHours: '8.2 hrs', status: 'Present (On-Time)', statusColor: '#10b981' },
      { id: 'MN-1045', name: 'Rahul Mehta', dept: 'Sales', role: 'Senior Sales Consultant', inTime: '09:24 AM', lunchOut: '01:10 PM', lunchIn: '01:52 PM', lunchDurationMins: 42, outTime: 'On Duty', netHours: '7.8 hrs', status: 'Present (On-Time)', statusColor: '#10b981' },
      { id: 'MN-1089', name: 'Kavya Senthil', dept: 'Sales', role: 'Junior Retail Associate', inTime: '09:42 AM', lunchOut: '01:30 PM', lunchIn: '--', lunchDurationMins: 28, outTime: 'On Duty', netHours: '6.4 hrs', status: 'On Lunch Break', statusColor: '#f59e0b' },
      { id: 'MN-1094', name: 'Rohan Soni', dept: 'Operations', role: 'Master Diamond Setter & Goldsmith', inTime: '09:08 AM', lunchOut: '01:00 PM', lunchIn: '01:45 PM', lunchDurationMins: 45, outTime: '06:15 PM', netHours: '8.3 hrs', status: 'Shift Completed', statusColor: '#8b5cf6' },
      { id: 'MN-1102', name: 'Selvi Murugan', dept: 'Housekeeping', role: 'Senior Housekeeping Specialist', inTime: '08:50 AM', lunchOut: '12:45 PM', lunchIn: '01:30 PM', lunchDurationMins: 45, outTime: 'On Duty', netHours: '8.5 hrs', status: 'Present (On-Time)', statusColor: '#10b981' },
      { id: 'MN-1008', name: 'Vikram Reddy', dept: 'Gold Jewellery', role: 'Dept Head', inTime: '09:18 AM', lunchOut: '--', lunchIn: '--', lunchDurationMins: 0, outTime: 'On Duty', netHours: '8.1 hrs', status: 'Present (On-Time)', statusColor: '#10b981' },
      { id: 'MN-1012', name: 'Meera Krishnan', dept: 'HR & Admin', role: 'Head of HR', inTime: '09:20 AM', lunchOut: '--', lunchIn: '--', lunchDurationMins: 0, outTime: 'On Duty', netHours: '8.0 hrs', status: 'Present (On-Time)', statusColor: '#10b981' },
      { id: 'MN-1001', name: 'Suresh Iyer', dept: 'Executive CEO Office', role: 'Managing Director & CEO', inTime: '09:05 AM', lunchOut: '--', lunchIn: '--', lunchDurationMins: 0, outTime: 'On Duty', netHours: '8.3 hrs', status: 'Present (On-Time)', statusColor: '#10b981' },
    ];
  }

  triggerDownloadBlob(content, filename) {
    const blob = new Blob(['\uFEFF' + content], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', filename);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  // Audio Chime
  playNotificationSound() {
    try {
      const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();

      osc.type = 'sine';
      osc.frequency.setValueAtTime(587.33, audioCtx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(880, audioCtx.currentTime + 0.15);

      gain.gain.setValueAtTime(0.3, audioCtx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.35);

      osc.connect(gain);
      gain.connect(audioCtx.destination);

      osc.start();
      osc.stop(audioCtx.currentTime + 0.35);
    } catch (e) {}
  }
}

// Global Store Instance
window.MNStore = new MNEcosystemStore();
