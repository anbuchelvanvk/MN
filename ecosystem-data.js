/**
 * MN FAMILY - INTERNAL ECOSYSTEM UNIFIED DATA STORE
 * Handles:
 * 1. Date of Joining & Experience-based Probation (2 weeks vs 1 month)
 * 2. Trainer/Mentor Assignment & Mandatory Training Agendas
 * 3. Predefined SOP "Things to Do" (Immutable for staff)
 * 4. Task Assignment Hierarchy (CEO -> All, Dept Head -> Dept, HR -> Emergency Delegation)
 * 5. Task Completion with Proof Attachment & "Not Finished" Reason + Postpone Flow
 * 6. 100% Profile Completion & Activation Authorization Gateway
 * 7. Resistance / Daily Reminder Notification Triggers & Nudges
 */

const MN_STORE_KEY = 'mn_family_ecosystem_v2';

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

// Initial Seed Data
const DEFAULT_ECOSYSTEM_DATA = {
  employees: [
    {
      id: 'MN-1024',
      name: 'Adithi Sharma',
      role: 'Fine Jewellery Operations Executive',
      dept: 'Operations',
      phone: '+91 98450 12345',
      email: 'adithi.s@mnjewelpark.com',
      avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
      initials: 'AS',
      doj: '2025-01-15',
      experienceYears: '3.5 yrs in Jewellery Industry',
      experienceCategory: 'experienced',
      probationWeeks: 2,
      probationStatus: 'cleared',
      probationEndDate: '2025-01-29',
      trainer: { name: 'Vikram Reddy', role: 'Head of Operations' },
      profileCompletion: {
        percentage: 100,
        isAuthorized: true,
        photoVerified: true,
        addressVerified: true,
        kycVerified: true,
        sopRolesAcknowledged: true,
        authorizedDate: '2026-02-10'
      },
      status: 'active',
      ragStatus: 'green',
      lastActive: 'Just now'
    },
    {
      id: 'MN-1045',
      name: 'Rahul Mehta',
      role: 'Senior Sales Consultant',
      dept: 'Sales',
      phone: '+91 98450 22334',
      email: 'rahul.m@mnjewelpark.com',
      avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=200',
      initials: 'RM',
      doj: '2024-06-10',
      experienceYears: '5 yrs in Jewellery Industry',
      experienceCategory: 'experienced',
      probationWeeks: 2,
      probationStatus: 'cleared',
      probationEndDate: '2024-06-24',
      trainer: { name: 'Ananya Sen', role: 'Sales Lead' },
      profileCompletion: {
        percentage: 100,
        isAuthorized: true,
        photoVerified: true,
        addressVerified: true,
        kycVerified: true,
        sopRolesAcknowledged: true,
        authorizedDate: '2026-01-14'
      },
      status: 'active',
      ragStatus: 'green',
      lastActive: '15 mins ago'
    },
    {
      id: 'MN-1089',
      name: 'Kavya Senthil',
      role: 'Junior Retail Associate',
      dept: 'Sales',
      phone: '+91 98450 77889',
      email: 'kavya.s@mnjewelpark.com',
      avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=200',
      initials: 'KS',
      doj: '2026-10-01',
      experienceYears: 'Fresher (0 yrs)',
      experienceCategory: 'fresher',
      probationWeeks: 4, // 1 month for fresher
      probationStatus: 'active',
      probationEndDate: '2026-10-31',
      trainer: { id: 'MN-1045', name: 'Rahul Mehta', role: 'Senior Sales Consultant' },
      trainingAgenda: [
        { id: 1, title: '1. Luxury Showroom Greeting & Velvet Tray Presentation', desc: 'Understanding customer body language and 916 hallmarked bridal trays.', done: true, verifiedBy: 'Rahul Mehta' },
        { id: 2, title: '2. 22K & 24K Gold Rate Calculation with Making Charges & 3% GST', desc: 'Operating POS billing terminal and gold estimate calculator.', done: true, verifiedBy: 'Rahul Mehta' },
        { id: 3, title: '3. Gold Savings Scheme (Swarna Nidhi) Enrollment SOP', desc: 'Collecting customer KYC, Aadhaar copy, and issuing digital passbooks.', done: false, verifiedBy: null },
        { id: 4, title: '4. High-Security Solitaire Return & Weighing Scale Verification', desc: '0.001g digital scale calibration before customer handover.', done: false, verifiedBy: null }
      ],
      dailyReviews: [
        { day: 'Day 1', date: 'Oct 01, 2026', learnings: 'Learned showroom opening protocol and velvet lighting adjustments.', trainerRating: 'Excellent (5/5)' },
        { day: 'Day 2', date: 'Oct 02, 2026', learnings: 'Practiced 916 gold rate formula: Base + 12% Making + 3% GST.', trainerRating: 'Good (4/5)' },
        { day: 'Day 3', date: 'Oct 03, 2026', learnings: 'Observed diamond solitaire trial counter and customer objection handling.', trainerRating: 'Excellent (5/5)' }
      ],
      profileCompletion: {
        percentage: 65,
        isAuthorized: false,
        photoVerified: true,
        addressVerified: true,
        kycVerified: false,
        sopRolesAcknowledged: false,
        authorizedDate: null
      },
      status: 'onboarding',
      ragStatus: 'yellow',
      lastActive: '1 hr ago'
    },
    {
      id: 'MN-1094',
      name: 'Rohan Soni',
      role: 'Master Diamond Setter & Goldsmith',
      dept: 'Operations',
      phone: '+91 98450 33445',
      email: 'rohan.s@mnjewelpark.com',
      avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=200',
      initials: 'RS',
      doj: '2026-10-01',
      experienceYears: '3.5 yrs in Jewellery Industry',
      experienceCategory: 'experienced',
      probationWeeks: 2, // 2 weeks for 3+ yrs experienced
      probationStatus: 'active',
      probationEndDate: '2026-10-15',
      trainer: { id: 'MN-1008', name: 'Vikram Reddy', role: 'Head of Operations' },
      trainingAgenda: [
        { id: 1, title: '1. BIS Hallmark Laser Inscription & HUID Compliance', desc: '6-digit alphanumeric code registration with government portal.', done: true, verifiedBy: 'Vikram Reddy' },
        { id: 2, title: '2. High-Precision Micro-Prong Diamond Setting', desc: 'Microscope claw calibration for VVS1 solitaires with zero weight loss.', done: true, verifiedBy: 'Vikram Reddy' },
        { id: 3, title: '3. Daily Sweepings Recovery & Vault Inward Balance', desc: 'Dust trap filtration and 0.001g alloy variance signoff.', done: false, verifiedBy: null }
      ],
      dailyReviews: [
        { day: 'Day 1', date: 'Oct 01, 2026', learnings: 'Calibrated micro-welding station and gold bullion requisition paperwork.', trainerRating: 'Outstanding (5/5)' },
        { day: 'Day 2', date: 'Oct 02, 2026', learnings: 'Completed 18K antique bridal choker prong alignment test.', trainerRating: 'Outstanding (5/5)' }
      ],
      profileCompletion: {
        percentage: 85,
        isAuthorized: false,
        photoVerified: true,
        addressVerified: true,
        kycVerified: true,
        sopRolesAcknowledged: false,
        authorizedDate: null
      },
      status: 'onboarding',
      ragStatus: 'green',
      lastActive: '30 mins ago'
    },
    {
      id: 'MN-1102',
      name: 'Selvi Murugan',
      role: 'Senior Housekeeping & Sanitation Specialist',
      dept: 'Housekeeping',
      phone: '+91 98450 99112',
      email: 'selvi.m@mnjewelpark.com',
      avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=200',
      initials: 'SM',
      doj: '2025-03-01',
      experienceYears: '4 yrs in Hospitality/Housekeeping',
      experienceCategory: 'experienced',
      probationWeeks: 2,
      probationStatus: 'cleared',
      probationEndDate: '2025-03-15',
      trainer: { name: 'K. Natarajan', role: 'Facility Lead' },
      profileCompletion: {
        percentage: 100,
        isAuthorized: true,
        photoVerified: true,
        addressVerified: true,
        kycVerified: true,
        sopRolesAcknowledged: true,
        authorizedDate: '2026-03-01'
      },
      status: 'active',
      ragStatus: 'green',
      lastActive: '5 mins ago'
    }
  ],

  tasks: [
    {
      id: 'TSK-101',
      empId: 'MN-1024',
      title: 'Daily 22K Gold Vault Weight Reconciliation',
      category: 'Vault & Purity Assay',
      isDefaultSop: true,
      assignedBy: { role: 'system', name: 'Predefined SOP' },
      due: '11:00 AM',
      priority: 'Critical SLA',
      status: 'completed',
      proof: {
        type: 'photo',
        content: 'Vault weight balance sheet verified: 4,820.450g matched with master ledger #MN-V22.',
        photoUrl: 'https://images.unsplash.com/photo-1610375461246-83df859d849d?auto=format&fit=crop&q=80&w=300',
        timestamp: '10:45 AM'
      },
      immutable: true
    },
    {
      id: 'TSK-102',
      empId: 'MN-1024',
      title: 'BIS 916 Hallmark & 6-Digit HUID Laser Verification for Batch #402',
      category: 'BIS 916 Hallmarking',
      isDefaultSop: true,
      assignedBy: { role: 'dept_head', name: 'Vikram Reddy (Dept Head)' },
      due: '02:30 PM',
      priority: 'Critical SLA',
      status: 'pending',
      proof: null,
      immutable: true
    },
    {
      id: 'TSK-103',
      empId: 'MN-1024',
      title: 'Executive Navaratna Bridal Necklace Expedited Polish',
      category: 'CEO Special Directive',
      isDefaultSop: false,
      assignedBy: { role: 'ceo', name: 'Suresh Iyer (CEO)' },
      due: '05:00 PM',
      priority: 'Critical SLA',
      status: 'pending',
      proof: null,
      immutable: true
    },
    {
      id: 'TSK-104',
      empId: 'MN-1024',
      title: 'Evening Gold Craft Waste & Sweepings Recovery Log',
      category: 'Loss Prevention',
      isDefaultSop: true,
      assignedBy: { role: 'system', name: 'Predefined SOP' },
      due: '06:45 PM',
      priority: 'Standard',
      status: 'postponed',
      proof: null,
      postponeInfo: {
        reason: 'Late bridal jewellery custom sizing order delayed workshop furnace shutdown by 1 hour.',
        postponedTo: 'Tomorrow 08:30 AM',
        postponedAt: '06:15 PM'
      },
      immutable: true
    },
    {
      id: 'TSK-105',
      empId: 'MN-1045',
      title: 'Morning Velvet Counter Tray Sanitization & Lighting Check',
      category: 'Showroom SOP',
      isDefaultSop: true,
      assignedBy: { role: 'system', name: 'Predefined SOP' },
      due: '09:45 AM',
      priority: 'High',
      status: 'completed',
      proof: {
        type: 'photo',
        content: 'All 14 velvet counter trays sanitized. LED jewel spotlights calibrated to 4000K daylight.',
        photoUrl: 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?auto=format&fit=crop&q=80&w=300',
        timestamp: '09:35 AM'
      },
      immutable: true
    },
    {
      id: 'TSK-106',
      empId: 'MN-1089',
      title: 'Customer Gold Savings Scheme & KYC Verification',
      category: 'Customer Relations',
      isDefaultSop: true,
      assignedBy: { role: 'system', name: 'Predefined SOP' },
      due: '01:00 PM',
      priority: 'Standard',
      status: 'pending',
      proof: null,
      immutable: true
    }
  ],

  emergencyDelegations: [],

  reminders: [
    {
      id: 'REM-1',
      title: '⏰ 09:30 AM Shift Routine Reminder',
      message: 'Please review your 4 predefined daily SOP "Things to Do". Mark completion with photo proof as you execute each step.',
      time: '09:30 AM',
      type: 'routine'
    },
    {
      id: 'REM-2',
      title: '🔔 Midday Proof Check',
      message: 'Upload verification photo for BIS 916 Hallmark Lot #402 before shift handover.',
      time: '02:00 PM',
      type: 'proof'
    }
  ]
};

// Storage Utilities
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
      console.warn('Could not parse stored data, resetting to defaults', e);
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

  // Onboard New Employee with Experience-based Probation & Trainer
  addNewEmployee({ name, id, dept, role, phone, email, doj, experienceCategory, trainerId }) {
    const isExperienced = experienceCategory === 'experienced';
    const probationWeeks = isExperienced ? 2 : 4; // 2 weeks for experienced (3+ yrs), 4 weeks (1 mo) for fresher
    
    // Calculate Probation End Date
    const dojDate = new Date(doj || Date.now());
    const endDate = new Date(dojDate.getTime() + probationWeeks * 7 * 24 * 60 * 60 * 1000);
    const probationEndDate = endDate.toISOString().split('T')[0];

    const trainerEmp = this.data.employees.find(e => e.id === trainerId) || { name: 'Department Head', role: 'Head of ' + dept };
    const initials = name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase();

    // Default Training Modules based on Department
    const deptAgendas = {
      'Operations': [
        { id: 1, title: '1. BIS Hallmark & 916 Standard Purity Protocol', desc: 'Understanding alloy tolerances, cadmium-free soldering and 6-digit HUID tracking.', done: false, verifiedBy: null },
        { id: 2, title: '2. High-Security Vault & Dual-Key Sign-in', desc: 'Biometric custody procedures, safe transit protocols and daily opening logs.', done: false, verifiedBy: null },
        { id: 3, title: '3. Precision Craftsmanship & Stone Calibration', desc: 'Filigree integrity, prong safety checks, laser micro-welding SOPs.', done: false, verifiedBy: null }
      ],
      'Sales': [
        { id: 1, title: '1. Luxury Showroom Greeting & Velvet Tray Presentation', desc: 'Understanding customer body language and 916 hallmarked bridal trays.', done: false, verifiedBy: null },
        { id: 2, title: '2. 22K & 24K Gold Rate Calculation with Making Charges & 3% GST', desc: 'Operating POS billing terminal and gold estimate calculator.', done: false, verifiedBy: null },
        { id: 3, title: '3. Gold Savings Scheme (Swarna Nidhi) Enrollment SOP', desc: 'Collecting customer KYC, Aadhaar copy, and issuing digital passbooks.', done: false, verifiedBy: null }
      ],
      'Housekeeping': [
        { id: 1, title: '1. Microfiber Display Cleaning & Diamond Counter Shine', desc: 'Scratchless velvet polishing and glass sanitization chemicals.', done: false, verifiedBy: null },
        { id: 2, title: '2. Vault Area Perimeter Dust & Waste Protocol', desc: 'Dual security presence during floor vacuuming near bullion vault.', done: false, verifiedBy: null },
        { id: 3, title: '3. Emergency Spill & Glass Fracture SOP', desc: 'Immediate velvet partition barrier deployment and reporting.', done: false, verifiedBy: null }
      ],
      'Vault': [
        { id: 1, title: '1. Biometric Vault Dual-Key Protocol', desc: 'Dual staff authentication before heavy steel door rotation.', done: false, verifiedBy: null },
        { id: 2, title: '2. 999.9 Swiss Bullion Inward Inspection', desc: 'Assay bar weight validation and barcode scanning.', done: false, verifiedBy: null }
      ]
    };

    const trainingAgenda = deptAgendas[dept] || deptAgendas['Operations'];

    const newEmp = {
      id: id || `MN-${Math.floor(1100 + Math.random() * 900)}`,
      name,
      role,
      dept,
      phone: phone || '+91 98450 00000',
      email: email || `${name.toLowerCase().replace(/\s+/g, '.')}@mnjewelpark.com`,
      avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
      initials,
      doj: doj || new Date().toISOString().split('T')[0],
      experienceYears: isExperienced ? '3+ Years in Jewelry Industry' : 'Fresher (0 Years)',
      experienceCategory,
      probationWeeks,
      probationStatus: 'active',
      probationEndDate,
      trainer: {
        id: trainerEmp.id,
        name: trainerEmp.name,
        role: trainerEmp.role
      },
      trainingAgenda,
      dailyReviews: [
        { day: 'Day 1', date: 'Joining Day', learnings: 'Joined MN Family, completed biometric intake and met mentor.', trainerRating: 'Enrolled' }
      ],
      profileCompletion: {
        percentage: 35,
        isAuthorized: false,
        photoVerified: true,
        addressVerified: false,
        kycVerified: false,
        sopRolesAcknowledged: false,
        authorizedDate: null
      },
      status: 'onboarding',
      ragStatus: 'yellow',
      lastActive: 'Just registered'
    };

    this.data.employees.unshift(newEmp);

    // Auto-generate Predefined SOP Things to Do for this employee
    const defaultSops = SOP_TEMPLATES[dept] || SOP_TEMPLATES['Operations'];
    defaultSops.forEach((sop, idx) => {
      this.data.tasks.push({
        id: `TSK-${Date.now()}-${idx}`,
        empId: newEmp.id,
        title: sop.title,
        category: sop.category,
        isDefaultSop: true,
        assignedBy: { role: 'system', name: 'Predefined SOP' },
        due: sop.due,
        priority: sop.priority,
        status: 'pending',
        proof: null,
        immutable: true
      });
    });

    this.saveData();
    return newEmp;
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

  // Task Postponement / Not Finished with Mandatory Reason
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

  // Task Assignment by Authority
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

  // HR Emergency Leave Task Delegation
  delegateEmergencyLeaveTasks({ leaveEmpId, replacementEmpId, reason }) {
    const leaveEmp = this.data.employees.find(e => e.id === leaveEmpId);
    const repEmp = this.data.employees.find(e => e.id === replacementEmpId);

    if (!leaveEmp || !repEmp) return false;

    // Find all pending tasks of the leave employee
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

  // 100% Profile Verification & Authorization
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

  // Complete Training Module (Trainer / Trainee action)
  toggleTrainingModule(empId, moduleId, trainerName = 'Trainer') {
    const emp = this.data.employees.find(e => e.id === empId);
    if (!emp || !emp.trainingAgenda) return false;

    const module = emp.trainingAgenda.find(m => m.id === moduleId);
    if (module) {
      module.done = !module.done;
      module.verifiedBy = module.done ? trainerName : null;

      // Update completion %
      const doneCount = emp.trainingAgenda.filter(m => m.done).length;
      const total = emp.trainingAgenda.length;
      emp.profileCompletion.percentage = Math.round(35 + (doneCount / total) * 50);

      if (doneCount === total) {
        emp.probationStatus = 'review_pending';
      }

      this.saveData();
      return module;
    }
    return false;
  }

  // Add Daily Learning Diary Review
  addDailyReview(empId, learningsText, trainerRating = 'Under Review') {
    const emp = this.data.employees.find(e => e.id === empId);
    if (!emp) return false;

    if (!emp.dailyReviews) emp.dailyReviews = [];

    const dayNum = emp.dailyReviews.length + 1;
    const newEntry = {
      day: `Day ${dayNum}`,
      date: new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
      learnings: learningsText,
      trainerRating
    };

    emp.dailyReviews.unshift(newEntry);
    this.saveData();
    return newEntry;
  }

  // Trigger Sound Chime Notification
  playNotificationSound() {
    try {
      const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();

      osc.type = 'sine';
      osc.frequency.setValueAtTime(587.33, audioCtx.currentTime); // D5
      osc.frequency.exponentialRampToValueAtTime(880, audioCtx.currentTime + 0.15); // A5

      gain.gain.setValueAtTime(0.3, audioCtx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.35);

      osc.connect(gain);
      gain.connect(audioCtx.destination);

      osc.start();
      osc.stop(audioCtx.currentTime + 0.35);
    } catch (e) {
      // AudioContext may be restricted by browser policy before user interaction
    }
  }
}

// Global Store Instance
window.MNStore = new MNEcosystemStore();
