/**
 * MN FAMILY - MN JEWEL PARK INTERNAL ECOSYSTEM
 * High-performance interactive controller for Mobile Prototype
 * Ready for Flutter architecture translation
 */

// ==========================================
// STATE MANAGEMENT & MOCK DATA
// ==========================================

const APP_STATE = {
  currentRole: 'employee', // 'employee' | 'dept_head' | 'hr' | 'ceo'
  punchedIn: true,
  punchInTime: new Date(Date.now() - 5 * 3600 * 1000 - 42 * 60 * 1000), // ~5h 42m ago
  currentTab: 'home',
  
  userProfiles: {
    employee: {
      name: 'Aishwarya Rajesh',
      role: 'Senior Gold Artisan & Stylist',
      avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
      id: 'MN-EMP-2024-089',
      dob: '14 Jun 1994',
      doj: '12 Jan 2021',
      phone: '+91 98402 44321',
      dept: 'Gold Ornaments & Hallmark QA',
      trafficScore: 'green',
      trafficLabel: 'Grade A (Green)',
      bmi: 21.8,
      familyHours: 3.5,
      dietLogged: true
    },
    dept_head: {
      name: 'Vikram Sundaram',
      role: 'Head of Crafting & BIS Hallmarking',
      avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=200',
      id: 'MN-LEAD-2019-012',
      dob: '22 Aug 1986',
      doj: '05 Mar 2019',
      phone: '+91 98401 55678',
      dept: 'Crafting & Assay Division',
      trafficScore: 'green',
      trafficLabel: 'Exemplary Lead (Green)',
      bmi: 23.4,
      familyHours: 4.0,
      dietLogged: true
    },
    hr: {
      name: 'Sneha Murthy',
      role: 'Head of People & Compliance',
      avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=200',
      id: 'MN-HR-2020-004',
      dob: '19 Nov 1991',
      doj: '10 Aug 2020',
      phone: '+91 98840 99210',
      dept: 'Human Resources & Talent',
      trafficScore: 'green',
      trafficLabel: 'People Champion (Green)',
      bmi: 22.1,
      familyHours: 3.0,
      dietLogged: true
    },
    ceo: {
      name: 'M. Natarajan',
      role: 'Managing Director & CEO',
      avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=200',
      id: 'MN-EXEC-001',
      dob: '08 Dec 1974',
      doj: '15 Aug 2005',
      phone: '+91 98400 00001',
      dept: 'Executive Board',
      trafficScore: 'green',
      trafficLabel: 'Executive Master (Green)',
      bmi: 24.2,
      familyHours: 4.5,
      dietLogged: true
    }
  },

  tasks: [
    {
      id: 1,
      title: '916 BIS Hallmark Verification on Navaratna Choker Lot #402',
      category: 'BIS 916 Hallmarking',
      assignedBy: 'CEO Office',
      assignedType: 'ceo',
      due: '14:30',
      priority: 'Critical SLA',
      completed: false,
      immutable: true
    },
    {
      id: 2,
      title: 'Precision Micro-laser Polish for Temple Bridal Bangles',
      category: 'Gold Crafting & Polishing',
      assignedBy: 'Vikram S. (Dept Head)',
      assignedType: 'lead',
      due: '16:00',
      priority: 'High Priority',
      completed: false,
      immutable: true
    },
    {
      id: 3,
      title: 'Custody Handover of 24K Ingot Bar #MN-884 to Vault',
      category: 'Vault Inventory Count',
      assignedBy: 'Dept Head & HR',
      assignedType: 'lead',
      due: '17:30',
      priority: 'Critical SLA',
      completed: false,
      immutable: true
    },
    {
      id: 4,
      title: 'Submit Monthly Gold Crafting Weight Variance Register',
      category: 'Safety & Quality Assay',
      assignedBy: 'Sneha M. (HR)',
      assignedType: 'lead',
      due: '18:15',
      priority: 'Standard',
      completed: false,
      immutable: true
    },
    {
      id: 5,
      title: 'Study 2026 Gemology Laser Engraving Guideline',
      category: 'Self Assigned Task',
      assignedBy: 'Self',
      assignedType: 'self',
      due: '19:00',
      priority: 'Standard',
      completed: true,
      immutable: false
    }
  ],

  workflowSteps: [
    {
      step: 'STEP 01',
      title: 'Gold Bullion Requisition',
      desc: 'Dual-auth checkout from high security bullion vault.',
      badge: 'Security Vault Dept'
    },
    {
      step: 'STEP 02',
      title: 'Fine Filigree & Alloy Craft',
      desc: 'Precision 22K (91.6%) handcrafted alloying and setting.',
      badge: 'Artisan Workshop'
    },
    {
      step: 'STEP 03',
      title: 'Laser BIS Hallmarking',
      desc: 'Assay spectrometer scan and government HUID engraving.',
      badge: 'Quality & Assay'
    },
    {
      step: 'STEP 04',
      title: 'Velvet Counter Showcase',
      desc: 'Presentation with high-precision 0.001g digital scale.',
      badge: 'Showroom Floor'
    }
  ],

  onboardingModules: [
    {
      id: 1,
      title: '1. BIS Hallmark & 916 Standard Purity Protocol',
      desc: 'Understanding alloy tolerances, cadmium-free soldering and 6-digit HUID tracking.',
      status: 'done'
    },
    {
      id: 2,
      title: '2. High-Security Vault & Dual-Key Sign-in',
      desc: 'Biometric custody procedures, safe transit protocols and daily opening logs.',
      status: 'done'
    },
    {
      id: 3,
      title: '3. Precision Craftsmanship & Stone Calibration',
      desc: 'Filigree integrity, prong safety checks, laser micro-welding SOPs.',
      status: 'done'
    },
    {
      id: 4,
      title: '4. Luxury Customer Presentation & ERP Billing',
      desc: 'Velvet lighting display guidelines, computerized weight receipts, KYC compliance.',
      status: 'current'
    }
  ],

  newsFeed: [
    {
      id: 1,
      tag: 'Heritage Collection Launch',
      title: 'Navaratna Bridal Gold Gala recorded 140% target fulfillment',
      body: 'Hearty congratulations to the Crafting and Sales Department on breaking quarterly milestones across all branches.',
      author: 'M. Natarajan (CEO)',
      time: '2 hours ago',
      likes: 42
    },
    {
      id: 2,
      tag: 'Bullion Market Update',
      title: '24K Raw Gold Reserve bolstered ahead of Festive Season',
      body: 'MN Jewel Park has secured 50kg 999.9 Swiss bullion bars to fulfill upcoming wedding orders with zero raw material delays.',
      author: 'Executive Treasury',
      time: 'Yesterday',
      likes: 38
    },
    {
      id: 3,
      tag: 'Wellness & Culture',
      title: 'Annual MN Family Ayudha Pooja & Gold Smithing Honors',
      body: 'Special incentive distribution for top craftspeople scheduled for Friday evening at the Central Banquet.',
      author: 'HR Department',
      time: '2 days ago',
      likes: 67
    }
  ],

  notifications: [
    {
      id: 1,
      type: 'birthday',
      title: '🎂 Colleague Birthday Today!',
      message: 'Wish Deepika S. (Sales Executive) a very Happy Birthday!',
      time: '1h ago',
      unread: true
    },
    {
      id: 2,
      type: 'anniversary',
      title: '🎉 4th Work Anniversary',
      message: 'Karthik S. (Diamond QA) completes 4 glorious years at MN Jewel Park.',
      time: '3h ago',
      unread: true
    },
    {
      id: 3,
      type: 'task',
      title: '⚡ New CEO Task Assigned',
      message: 'High priority hallmarking review added for shift handover.',
      time: '5h ago',
      unread: true
    },
    {
      id: 4,
      type: 'system',
      title: '💎 Gold Rate Adjusted',
      message: 'Daily 22K 916 gold trading base updated to ₹6,805/g.',
      time: '09:00 AM',
      unread: false
    }
  ],

  trafficAudit: [
    {
      color: 'green',
      score: 'Green (96%)',
      date: 'Oct 01, 2026',
      comment: 'Demonstrated immaculate accuracy on the Navaratna bridal choker crafting. Zero weight variance recorded.',
      author: 'Vikram Sundaram (Dept Head)'
    },
    {
      color: 'green',
      score: 'Green (94%)',
      date: 'Sep 15, 2026',
      comment: 'Completed shift handover on time. Assisted junior artisan with laser soldering protocol.',
      author: 'HR & Dept Lead'
    }
  ]
};

// ==========================================
// INITIALIZATION
// ==========================================

document.addEventListener('DOMContentLoaded', () => {
  initClock();
  renderWorkflowCards();
  renderTasks();
  renderOnboarding();
  renderNewsFeed();
  renderNotifications();
  updateUserInterface();

  // Dismiss Splash Screen smoothly
  setTimeout(() => {
    const splash = document.getElementById('appSplash');
    if (splash) {
      splash.classList.add('fade-out');
      setTimeout(() => splash.remove(), 600);
    }
  }, 1500);
});

// ==========================================
// LIVE GOLD ORNAMENT CALCULATOR (Sales Tool)
// ==========================================

function openGoldCalculatorModal() {
  openModal('goldCalculatorModal');
  recalculateGoldPrice();
}

function recalculateGoldPrice() {
  const ratePerGram = parseFloat(document.getElementById('calcPuritySelect').value) || 6805;
  const weight = parseFloat(document.getElementById('calcWeight').value) || 0;
  const wastagePercent = parseFloat(document.getElementById('calcWastage').value) || 0;

  const baseGoldValue = weight * ratePerGram;
  const makingCharges = (baseGoldValue * wastagePercent) / 100;
  const subtotal = baseGoldValue + makingCharges;
  const gst = subtotal * 0.03; // 3% GST
  const grandTotal = Math.round(subtotal + gst);

  const formatInr = (num) => '₹' + Math.round(num).toLocaleString('en-IN');

  document.getElementById('calcBaseVal').textContent = formatInr(baseGoldValue);
  document.getElementById('calcMakingVal').textContent = '+ ' + formatInr(makingCharges);
  document.getElementById('calcGstVal').textContent = '+ ' + formatInr(gst);
  document.getElementById('calcTotalEstimate').textContent = formatInr(grandTotal);
}

function shareGoldEstimate() {
  const total = document.getElementById('calcTotalEstimate').textContent;
  const weight = document.getElementById('calcWeight').value;
  const quote = `MN JEWEL PARK QUOTATION\nWeight: ${weight}g 916 BIS Hallmark\nTotal Estimate: ${total}\n(Includes 3% GST & Making Charges)`;
  
  if (navigator.clipboard) {
    navigator.clipboard.writeText(quote);
  }
  showToast('📋 Quotation copied to clipboard for WhatsApp sharing!');
  closeModal('goldCalculatorModal');
}

// ==========================================
// ROLE SWITCHER & ADAPTIVE VIEWS
// ==========================================

function switchRole(roleKey) {
  APP_STATE.currentRole = roleKey;
  const user = APP_STATE.userProfiles[roleKey];
  
  // Update Profile & Header displays
  document.getElementById('userNameDisplay').textContent = user.name;
  document.getElementById('userRoleBadge').innerHTML = `<i class="fa-solid fa-certificate gold-text"></i> ${user.role}`;
  document.getElementById('userAvatar').src = user.avatar;
  document.getElementById('headerTrafficText').textContent = user.trafficLabel;

  // Update Vault Card
  if (document.getElementById('cardEmpName')) {
    document.getElementById('cardEmpName').textContent = user.name;
    document.getElementById('cardEmpRole').textContent = user.role;
    document.getElementById('cardEmpDob').textContent = user.dob;
    document.getElementById('cardEmpDoj').textContent = user.doj;
    document.getElementById('cardEmpPhoto') && (document.getElementById('cardEmpPhoto').src = user.avatar);
    document.getElementById('dispLegalName').textContent = user.name;
    document.getElementById('dispMobile').textContent = user.phone;
    document.getElementById('dispDob').textContent = user.dob;
    document.getElementById('dispDoj').textContent = user.doj;
  }

  // Toggle CEO Hub tab in Bottom Navigation
  const ceoNavTab = document.getElementById('nav-ceo');
  if (roleKey === 'ceo') {
    ceoNavTab.classList.remove('hidden');
    showToast(`👑 Switched to CEO Executive Mode: ${user.name}`);
  } else {
    ceoNavTab.classList.add('hidden');
    if (APP_STATE.currentTab === 'ceo') {
      navigateToTab('home');
    }
    showToast(`👤 Logged in as: ${user.name} (${user.role})`);
  }
}

function updateUserInterface() {
  const user = APP_STATE.userProfiles[APP_STATE.currentRole];
  document.getElementById('userNameDisplay').textContent = user.name;
  document.getElementById('userRoleBadge').innerHTML = `<i class="fa-solid fa-certificate gold-text"></i> ${user.role}`;
  document.getElementById('userAvatar').src = user.avatar;
}

// ==========================================
// NAVIGATION & TABS
// ==========================================

function navigateToTab(tabId) {
  APP_STATE.currentTab = tabId;

  // Toggle Tab Panes
  document.querySelectorAll('.tab-pane').forEach(pane => {
    pane.classList.remove('active');
  });
  const targetPane = document.getElementById(`tab-${tabId}`);
  if (targetPane) {
    targetPane.classList.add('active');
  }

  // Toggle Active Nav Button
  document.querySelectorAll('.nav-item').forEach(btn => {
    btn.classList.remove('active');
  });
  const activeBtn = document.getElementById(`nav-${tabId}`);
  if (activeBtn) {
    activeBtn.classList.add('active');
  }

  // Scroll to top of mobile shell
  const mainContent = document.getElementById('mainContent');
  if (mainContent) {
    mainContent.scrollTo({ top: 0, behavior: 'smooth' });
  }
}

// ==========================================
// WORKFLOW RENDERING (Req 2)
// ==========================================

function renderWorkflowCards() {
  const container = document.getElementById('workflowStepsList');
  if (!container) return;

  container.innerHTML = APP_STATE.workflowSteps.map((wf) => `
    <div class="workflow-card">
      <span class="wf-step-num">${wf.step}</span>
      <h4 class="wf-title">${wf.title}</h4>
      <p class="wf-desc">${wf.desc}</p>
      <span class="wf-badge"><i class="fa-solid fa-shield-check text-gold"></i> ${wf.badge}</span>
    </div>
  `).join('');
}

// ==========================================
// TO-DO & TASK PIPELINE (Req 7)
// ==========================================

function renderTasks(filter = 'all') {
  const homeContainer = document.getElementById('tasksList');
  const allTasksContainer = document.getElementById('allTasksList');

  let filtered = APP_STATE.tasks;
  if (filter === 'assigned') {
    filtered = APP_STATE.tasks.filter(t => t.assignedType !== 'self');
  } else if (filter === 'self') {
    filtered = APP_STATE.tasks.filter(t => t.assignedType === 'self');
  } else if (filter === 'completed') {
    filtered = APP_STATE.tasks.filter(t => t.completed);
  }

  const pendingCount = APP_STATE.tasks.filter(t => !t.completed).length;
  if (document.getElementById('pendingTaskCount')) {
    document.getElementById('pendingTaskCount').textContent = `${pendingCount} Pending`;
  }
  if (document.getElementById('navTaskBadge')) {
    document.getElementById('navTaskBadge').textContent = pendingCount;
  }

  const taskHtml = filtered.map(task => `
    <div class="task-item ${task.completed ? 'completed' : ''}" id="task-${task.id}">
      <div class="task-checkbox-wrap">
        <input type="checkbox" class="custom-chk" ${task.completed ? 'checked' : ''} onchange="toggleTaskComplete(${task.id})" />
      </div>
      <div class="task-body">
        <div class="task-header-line">
          <h4 class="task-title">${task.title}</h4>
          ${getAssignerBadge(task)}
        </div>
        <div class="task-meta">
          <span><i class="fa-solid fa-folder-open text-gold"></i> ${task.category}</span>
          <span><i class="fa-regular fa-clock"></i> Due ${task.due}</span>
          ${task.immutable ? `<span class="locked-icon" title="Mandatory assignment: Immutable without Lead approval"><i class="fa-solid fa-lock"></i> Protected</span>` : ''}
        </div>
      </div>
    </div>
  `).join('');

  if (homeContainer) homeContainer.innerHTML = taskHtml;
  if (allTasksContainer) allTasksContainer.innerHTML = taskHtml;
}

function getAssignerBadge(task) {
  if (task.assignedType === 'ceo') {
    return `<span class="assigner-badge ceo"><i class="fa-solid fa-crown text-gold"></i> ${task.assignedBy}</span>`;
  } else if (task.assignedType === 'lead') {
    return `<span class="assigner-badge lead"><i class="fa-solid fa-user-shield"></i> ${task.assignedBy}</span>`;
  } else {
    return `<span class="assigner-badge self"><i class="fa-solid fa-user"></i> My Task</span>`;
  }
}

function toggleTaskComplete(taskId) {
  const task = APP_STATE.tasks.find(t => t.id === taskId);
  if (!task) return;
  task.completed = !task.completed;
  renderTasks();
  if (task.completed) {
    showToast(`✨ Completed: "${task.title.substring(0, 30)}..."`);
  }
}

function filterTasks(filterType, element) {
  document.querySelectorAll('.task-filter-pills .pill').forEach(p => p.classList.remove('active'));
  element.classList.add('active');
  renderTasks(filterType);
}

function openAddTaskModal() {
  openModal('addTaskModal');
}

function saveNewTask() {
  const title = document.getElementById('newTaskTitle').value.trim();
  const category = document.getElementById('newTaskCategory').value;
  const due = document.getElementById('newTaskDue').value || '18:00';
  const priority = document.getElementById('newTaskPriority').value;

  if (!title) {
    showToast('⚠️ Please enter task details before adding.');
    return;
  }

  const newTask = {
    id: Date.now(),
    title,
    category,
    assignedBy: `${APP_STATE.userProfiles[APP_STATE.currentRole].name}`,
    assignedType: 'self',
    due,
    priority,
    completed: false,
    immutable: false
  };

  APP_STATE.tasks.unshift(newTask);
  renderTasks();
  closeModal('addTaskModal');
  showToast('✅ New task added to your daily queue!');
  document.getElementById('newTaskTitle').value = '';
}

// ==========================================
// ONBOARDING ACADEMY (Req 13)
// ==========================================

function renderOnboarding() {
  const container = document.getElementById('onboardingStepsList');
  if (!container) return;

  const total = APP_STATE.onboardingModules.length;
  const done = APP_STATE.onboardingModules.filter(m => m.status === 'done').length;
  const percent = Math.round((done / total) * 100);

  if (document.getElementById('onboardProgressBar')) {
    document.getElementById('onboardProgressBar').style.width = `${percent}%`;
  }
  if (document.getElementById('onboardPercentText')) {
    document.getElementById('onboardPercentText').textContent = `${percent}% Complete`;
  }

  container.innerHTML = APP_STATE.onboardingModules.map(module => `
    <div class="onboarding-step-card ${module.status === 'done' ? 'completed' : ''} ${module.status === 'current' ? 'active-step' : ''}">
      <div class="step-status-icon ${module.status}">
        ${module.status === 'done' ? '<i class="fa-solid fa-check"></i>' : (module.status === 'current' ? '<i class="fa-solid fa-play"></i>' : '<i class="fa-solid fa-lock"></i>')}
      </div>
      <div class="step-details">
        <h4>${module.title}</h4>
        <p>${module.desc}</p>
        ${module.status === 'current' ? `
          <button class="btn-gold-sm" onclick="completeOnboardingModule(${module.id})">
            <i class="fa-solid fa-circle-check"></i> Complete & Verify Module
          </button>
        ` : (module.status === 'done' ? `<span class="doc-status verified"><i class="fa-solid fa-shield-check"></i> Verified by Lead</span>` : '<span class="pill-tag"><i class="fa-solid fa-lock"></i> Locked</span>')}
      </div>
    </div>
  `).join('');
}

function completeOnboardingModule(moduleId) {
  const mod = APP_STATE.onboardingModules.find(m => m.id === moduleId);
  if (mod) {
    mod.status = 'done';
    showToast('🎓 Module completed! Full enterprise clearance granted.');
    renderOnboarding();
  }
}

// ==========================================
// NEWSLETTER & GAZETTE (Req 15)
// ==========================================

function renderNewsFeed() {
  const container = document.getElementById('newsFeedList');
  if (!container) return;

  container.innerHTML = APP_STATE.newsFeed.map(news => `
    <div class="news-preview-card" style="margin-bottom: 12px;">
      <div class="news-tag"><i class="fa-solid fa-crown text-gold"></i> ${news.tag}</div>
      <h4>${news.title}</h4>
      <p>${news.body}</p>
      <div class="news-meta">
        <span><i class="fa-solid fa-user-tie text-gold"></i> ${news.author}</span>
        <span><i class="fa-regular fa-clock"></i> ${news.time}</span>
        <button class="btn-cheer" style="margin-left: auto;" onclick="likeNewsPost(this, ${news.id})">
          <i class="fa-solid fa-heart"></i> ${news.likes}
        </button>
      </div>
    </div>
  `).join('');
}

function likeNewsPost(button, newsId) {
  const item = APP_STATE.newsFeed.find(n => n.id === newsId);
  if (item) {
    item.likes += 1;
    button.innerHTML = `<i class="fa-solid fa-heart" style="color:#ff4d4f"></i> ${item.likes}`;
    showToast('❤️ Reacted to MN Gazette update!');
  }
}

function sendCeoBroadcast() {
  const input = document.getElementById('ceoBroadcastInput');
  const text = input.value.trim();
  if (!text) {
    showToast('⚠️ Please enter an announcement.');
    return;
  }

  const newPost = {
    id: Date.now(),
    tag: 'Executive Announcement',
    title: text,
    body: `Issued by CEO M. Natarajan for immediate transmission across all 150 employees at MN Jewel Park.`,
    author: 'M. Natarajan (CEO Office)',
    time: 'Just now',
    likes: 1
  };

  APP_STATE.newsFeed.unshift(newPost);
  renderNewsFeed();
  input.value = '';
  showToast('📢 Executive Broadcast published to all 150 employees!');
}

// ==========================================
// NOTIFICATIONS & OCCASIONS (Req 5)
// ==========================================

function renderNotifications() {
  const container = document.getElementById('notifItemsList');
  if (!container) return;

  const unreadCount = APP_STATE.notifications.filter(n => n.unread).length;
  if (document.getElementById('notifCount')) {
    document.getElementById('notifCount').textContent = unreadCount;
  }

  container.innerHTML = APP_STATE.notifications.map(notif => `
    <div class="doc-item" style="background: ${notif.unread ? 'rgba(212,175,55,0.08)' : 'rgba(0,0,0,0.3)'}; margin-bottom: 8px;">
      <div class="doc-icon"><i class="fa-solid fa-bell text-gold"></i></div>
      <div class="doc-info">
        <strong>${notif.title}</strong>
        <span>${notif.message}</span>
        <span style="font-size: 8px; color: var(--text-muted); margin-top: 2px;">${notif.time}</span>
      </div>
      ${notif.type === 'birthday' || notif.type === 'anniversary' ? `
        <button class="btn-gold-sm" onclick="triggerCheerToast('${notif.title}')">
          <i class="fa-solid fa-hands-clapping"></i> Wish
        </button>
      ` : ''}
    </div>
  `).join('');
}

function triggerCheerToast(person) {
  showToast(`🎉 Sent warm celebration wishes to ${person}!`);
}

function markAllNotificationsRead() {
  APP_STATE.notifications.forEach(n => n.unread = false);
  renderNotifications();
  showToast('✓ All notifications marked as read.');
}

// ==========================================
// HEALTH, BMI & FAMILY GATEWAY (Req 10 & 11)
// ==========================================

function calculateBmiLive() {
  const weight = parseFloat(document.getElementById('inputWeight').value) || 0;
  const heightCm = parseFloat(document.getElementById('inputHeight').value) || 0;

  if (weight > 0 && heightCm > 0) {
    const heightM = heightCm / 100;
    const bmi = (weight / (heightM * heightM)).toFixed(1);
    
    document.getElementById('bmiScore').textContent = bmi;
    const catElem = document.getElementById('bmiCategory');
    
    if (bmi < 18.5) {
      catElem.textContent = 'Underweight - Increase nutritious calorie intake';
      catElem.className = 'text-warning';
    } else if (bmi >= 18.5 && bmi <= 24.9) {
      catElem.textContent = 'Normal / Healthy Weight (Optimal)';
      catElem.className = 'text-success';
    } else if (bmi >= 25 && bmi <= 29.9) {
      catElem.textContent = 'Overweight - Light cardio suggested';
      catElem.className = 'text-warning';
    } else {
      catElem.textContent = 'High BMI - Wellness advisory consultation';
      catElem.className = 'text-danger';
    }
  }
}

function updateFamilyHoursText(val) {
  document.getElementById('familyHoursDisplay').textContent = `${val} Hours`;
}

function saveWellnessRecord() {
  const weight = document.getElementById('inputWeight').value;
  const height = document.getElementById('inputHeight').value;
  const hours = document.getElementById('familyHoursRange').value;
  const bmi = document.getElementById('bmiScore').textContent;

  document.getElementById('summaryBmi').textContent = `${bmi} (Fit)`;
  document.getElementById('summaryFamily').textContent = `${hours} hrs`;
  document.getElementById('summaryDiet').textContent = 'Logged';

  closeModal('wellnessModal');
  showToast('🌿 Daily Mind, Diet & Family Wellness Gate recorded!');
}

// ==========================================
// TRAFFIC LIGHT PERFORMANCE RATING (Req 12)
// ==========================================

function openTrafficLightModal() {
  openModal('trafficModal');
}

function addTrafficLogEntry() {
  const color = document.querySelector('input[name="newTrafficColor"]:checked').value;
  const comment = document.getElementById('trafficLeadComment').value.trim();

  if (!comment) {
    showToast('⚠️ Please write a supervisory observation comment.');
    return;
  }

  const newEntry = {
    color,
    score: color === 'green' ? 'Green (98%)' : (color === 'yellow' ? 'Yellow (80%)' : 'Red (62%)'),
    date: 'Just now',
    comment: `"${comment}"`,
    author: `${APP_STATE.userProfiles[APP_STATE.currentRole].name} (${APP_STATE.userProfiles[APP_STATE.currentRole].role})`
  };

  APP_STATE.trafficAudit.unshift(newEntry);
  renderTrafficAudit();
  document.getElementById('trafficLeadComment').value = '';
  showToast(`🚦 Logged ${color.toUpperCase()} rating change into immutable audit trail.`);
}

function renderTrafficAudit() {
  const container = document.getElementById('trafficAuditList');
  if (!container) return;

  container.innerHTML = APP_STATE.trafficAudit.map(entry => `
    <div class="audit-item">
      <div class="audit-header">
        <span class="audit-badge ${entry.color}">${entry.score}</span>
        <span class="audit-date">${entry.date}</span>
      </div>
      <p class="audit-comment">${entry.comment}</p>
      <span class="audit-author"><i class="fa-solid fa-user-check text-gold"></i> By ${entry.author}</span>
    </div>
  `).join('');
}

// ==========================================
// ATTENDANCE PUNCH IN/OUT (Req 4)
// ==========================================

function handlePunch(action) {
  const badge = document.getElementById('punchBadge');
  if (action === 'in') {
    APP_STATE.punchedIn = true;
    badge.className = 'punch-state-badge';
    badge.innerHTML = `<i class="fa-solid fa-circle-check text-success"></i> Punched In`;
    showToast('🟢 Punched In successfully at MN Jewel Park Floor 2!');
  } else {
    APP_STATE.punchedIn = false;
    badge.className = 'punch-state-badge out';
    badge.innerHTML = `<i class="fa-solid fa-circle-xmark text-danger"></i> Punched Out`;
    showToast('🔴 Shift punch out recorded. Have a great evening with family!');
  }
}

// ==========================================
// PROFILE EDITING (Req 3)
// ==========================================

function openEditProfileModal() {
  openModal('editProfileModal');
}

function savePersonalProfile() {
  const name = document.getElementById('editName').value.trim();
  const phone = document.getElementById('editPhone').value.trim();
  const dob = document.getElementById('editDob').value;

  if (name) {
    APP_STATE.userProfiles.employee.name = name;
    APP_STATE.userProfiles.employee.phone = phone;
    APP_STATE.userProfiles.employee.dob = dob;

    document.getElementById('userNameDisplay').textContent = name;
    document.getElementById('cardEmpName').textContent = name;
    document.getElementById('dispLegalName').textContent = name;
    document.getElementById('dispMobile').textContent = phone;
    document.getElementById('dispDob').textContent = dob;

    closeModal('editProfileModal');
    showToast('💾 Personal information updated in HR records!');
  }
}

function downloadPayslipMock() {
  showToast('📄 Downloading Encrypted Salary Slip (MN_Payslip_Sep2026.pdf)...');
}

function openDocUploadModal() {
  showToast('📤 Document upload portal ready for BIS Certificate or Police Clearance scan.');
}

function openWorkflowDetailsModal() {
  openModal('workflowModal');
}

function openWellnessModal() {
  openModal('wellnessModal');
}

function openNotificationsModal() {
  openModal('notifModal');
}

function openExecutiveReviewModal() {
  showToast('👑 Executive Evaluation Module opened for leadership review.');
}

// ==========================================
// MODAL HELPERS
// ==========================================

function openModal(modalId) {
  const m = document.getElementById(modalId);
  if (m) {
    m.classList.add('show');
  }
}

function closeModal(modalId) {
  const m = document.getElementById(modalId);
  if (m) {
    m.classList.remove('show');
  }
}

// Device Frame Mode Toggle
function toggleDeviceFrame() {
  const container = document.getElementById('deviceContainer');
  const btn = document.getElementById('toggleFrameBtn');
  if (container.classList.contains('frameless')) {
    container.classList.remove('frameless');
    btn.innerHTML = '<i class="fa-solid fa-mobile-screen-button"></i> Frame Mode';
  } else {
    container.classList.add('frameless');
    btn.innerHTML = '<i class="fa-solid fa-expand"></i> Expanded Mode';
  }
}

// ==========================================
// LIVE CLOCK & TOAST UTILITY
// ==========================================

function initClock() {
  const clockElem = document.getElementById('liveClock');
  function update() {
    const now = new Date();
    if (clockElem) {
      clockElem.textContent = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true });
    }
  }
  update();
  setInterval(update, 1000);
}

function showToast(message) {
  const container = document.getElementById('toastContainer');
  if (!container) return;

  const toast = document.createElement('div');
  toast.className = 'toast';
  toast.innerHTML = `<i class="fa-solid fa-circle-info text-gold"></i> <span>${message}</span>`;
  container.appendChild(toast);

  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateY(10px)';
    toast.style.transition = 'all 0.3s ease';
    setTimeout(() => toast.remove(), 300);
  }, 3200);
}
