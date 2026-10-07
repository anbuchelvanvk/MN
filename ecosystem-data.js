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
      probationWeeks: 4,
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
        { day: 'Day 2', date: 'Oct 02, 2026', learnings: 'Practiced 916 gold rate formula: Base + 12% Making + 3% GST.', trainerRating: 'Good (4/5)' }
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
      probationWeeks: 2,
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
        content: 'All 14 velvet counter trays sanitized. LED spotlights calibrated to 4000K daylight.',
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

  // 1. Inter-Department Handover Pipeline
  handovers: [
    {
      id: 'HO-801',
      batch: 'Navaratna Bridal Choker Lot #402 (184.5g)',
      stage: 'Step 2: Quality & Assay BIS Hallmarking',
      fromDept: 'Workshop Crafting',
      toDept: 'Quality & Assay QA',
      assignedTo: 'Adithi Sharma (Operations)',
      status: 'in_progress',
      handoffTime: '11:30 AM',
      steps: [
        { name: '1. Fine Filigree & Setting', dept: 'Workshop', status: 'done', completedBy: 'Rohan Soni' },
        { name: '2. Laser BIS 916 Hallmarking', dept: 'Assay QA', status: 'in_progress', completedBy: 'Adithi Sharma' },
        { name: '3. Velvet Counter Showcase', dept: 'Showroom', status: 'pending', completedBy: 'Rahul Mehta' }
      ]
    },
    {
      id: 'HO-802',
      batch: '24K Swiss Gold Ingot Bar Custody #MN-992 (1000g)',
      stage: 'Step 3: Vault Secure Custody Receipt',
      fromDept: 'Executive Treasury',
      toDept: 'Vault Security',
      assignedTo: 'Major R. Pillai',
      status: 'completed',
      handoffTime: '09:45 AM',
      steps: [
        { name: '1. Inward Assay & Barcode Scan', dept: 'Treasury', status: 'done', completedBy: 'Finance Lead' },
        { name: '2. Security Escort Transit', dept: 'Security', status: 'done', completedBy: 'Escort Guard #4' },
        { name: '3. Dual-Key Vault Lockup', dept: 'Vault', status: 'done', completedBy: 'Major R. Pillai' }
      ]
    }
  ],

  // 2. Cross-Department Blockers & Escalations
  blockers: [
    {
      id: 'BLK-101',
      raisedByDept: 'Showroom Sales',
      raisedByName: 'Rahul Mehta',
      blockingDept: 'Workshop Crafting',
      issue: 'Custom 22K bridal bangle sizing not handed over by 3 PM; customer arriving at 4:30 PM for wedding trial.',
      severity: 'High Priority',
      status: 'active',
      time: '03:15 PM'
    }
  ],

  // 5. 10:00 AM Store Opening Readiness Gate (6 Depts)
  readinessGate: {
    status: '100% Ready (Green)',
    targetTime: '10:00 AM',
    signedCount: 6,
    totalCount: 6,
    depts: [
      { name: 'Housekeeping', task: 'Floor deep-clean & velvet glass mirror polish verified', signed: true, signedBy: 'Selvi M.', time: '09:20 AM' },
      { name: 'Vault & Logistics', task: 'Morning display trays issued to counters & dual-signed', signed: true, signedBy: 'Major R. Pillai', time: '09:35 AM' },
      { name: 'Security & CCTV', task: '360° CCTV scan & emergency exit sensor clearance', signed: true, signedBy: 'Security Lead', time: '09:40 AM' },
      { name: 'Operations & Assay', task: 'Digital 0.001g scales calibrated & hallmarking active', signed: true, signedBy: 'Vikram Reddy', time: '09:45 AM' },
      { name: 'Showroom Sales', task: 'Staff groomed, velvet spotlights calibrated to 4000K', signed: true, signedBy: 'Ananya Sen', time: '09:50 AM' },
      { name: 'Finance & Accounts', task: 'Daily 22K gold rate (₹6,805/g) synchronized on billing', signed: true, signedBy: 'Sunita Iyer', time: '09:52 AM' }
    ]
  },

  // 6. Cross-Department Incident Dispatch
  incidents: [
    {
      id: 'INC-201',
      title: 'AC Condensation Leak near Vault Entrance Perimeter',
      reportedBy: 'Housekeeping (Selvi Murugan)',
      dispatchedTo: 'Facility Maintenance & Security',
      severity: 'Medium',
      status: 'resolved',
      time: '11:15 AM',
      resolution: 'Drain pipe unclogged by maintenance team. Area dry and dual-witness cleared.'
    }
  ],

  // 7. Shift Handover Co-Sign Logs
  shiftHandovers: [
    {
      id: 'SH-501',
      shift: 'Morning → Evening Shift Transition',
      date: 'Today',
      outgoingLead: 'Vikram Reddy (Operations)',
      incomingLead: 'Karan Verma (Senior Goldsmith)',
      pendingItems: '1 task postponed to tomorrow (Furnace shutdown). Hallmarking batch #402 in progress.',
      status: 'Co-Signed & Logged'
    }
  ],

  // 8. Repeat Delay Pattern & Root Cause Analytics
  delayAnalytics: {
    totalPostponedMonth: 18,
    rootCauses: [
      { cause: 'Late Bridal Custom Sizing Order', count: 7, dept: 'Operations', pct: 39 },
      { cause: 'Customer Rescheduled Appointment', count: 4, dept: 'Sales', pct: 22 },
      { cause: 'POS / Gov Hallmarking Portal Network Latency', count: 4, dept: 'Finance/QA', pct: 22 },
      { cause: 'Supplier Raw Ingot Flight Delay', count: 3, dept: 'Vault', pct: 17 }
    ]
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
