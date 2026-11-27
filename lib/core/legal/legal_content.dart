/// The Privacy Policy and Terms & Conditions, built into the app.
/// Keep in step with web/legal/privacy.html and web/legal/terms.html.
library;

/// One block inside a section.
sealed class LegalBlock {
  const LegalBlock();
}

class LegalPara extends LegalBlock {
  final String text;
  const LegalPara(this.text);
}

class LegalBullets extends LegalBlock {
  final List<String> items;
  final bool numbered;
  const LegalBullets(this.items, {this.numbered = false});
}

/// A highlighted note (e.g. "We do not collect...").
class LegalNote extends LegalBlock {
  final String text;
  const LegalNote(this.text);
}

/// A list of (label, details) rows, shown as small cards.
class LegalRows extends LegalBlock {
  final List<(String, String)> rows;
  const LegalRows(this.rows);
}

/// Contact details with placeholders to fill in.
class LegalContact extends LegalBlock {
  final String heading;
  final List<(String, String)> lines;
  const LegalContact(this.heading, this.lines);
}

class LegalSection {
  final String title;
  final List<LegalBlock> blocks;
  const LegalSection(this.title, this.blocks);
}

class LegalDocument {
  final String title;
  final String lead;
  final String effective;
  final String updated;
  final List<LegalSection> sections;
  const LegalDocument({
    required this.title,
    required this.lead,
    required this.effective,
    required this.updated,
    required this.sections,
  });
}

const _contactLines = [
  ('Name', '[Officer name]'),
  ('Email', '[privacy@your-domain.com]'),
  ('Phone', '[+91 phone number]'),
  ('Address', '[Street address], Vellore, Tamil Nadu, India'),
];

const privacyPolicy = LegalDocument(
  title: 'Privacy Policy',
  lead: 'MN Family is the internal staff app of MN Jewel Park. This policy explains what information the app '
      'collects about you, why, who can see it, and the choices you have.',
  effective: '26 November 2026',
  updated: '26 November 2026',
  sections: [
    LegalSection('Who we are', [
      LegalPara('The MN Family app ("the app") is operated by MN Jewel Park, Vellore, Tamil Nadu, India '
          '("MN Jewel Park", "we", "us"). We decide how personal information in the app is used, and we are '
          'responsible for it.'),
      LegalPara('The app is a workplace tool. It helps our staff with daily tasks, attendance, team communication '
          'and four personal well-being "pillars": Health, Family Time, Work and Social Cause.'),
    ]),
    LegalSection('Who this policy covers', [
      LegalPara('The app is only for people who work with MN Jewel Park: employees, team leads, HR, management, '
          'and outside support staff we invite. There is no public sign-up. Accounts are created by HR or '
          'management, and you sign in with the email and password they give you.'),
      LegalPara('This policy also covers limited information about other people that staff enter while working, '
          'such as online-order customers, and family or friends mentioned in Family Time entries.'),
    ]),
    LegalSection('Information we collect', [
      LegalPara('Most information is entered by you, by HR or by your team lead. Some comes from your phone, '
          'only when you allow it.'),
      LegalRows([
        ('Account and profile',
            'Name, employee ID and number, email, phone number, role, department, date of joining, experience, '
                'date of birth, gender, profile photo. From HR / management, and from you when you edit your profile.'),
        ('Sign-in',
            'Sign-in email and password (the password is handled by Firebase Authentication and is not visible '
                'to us), password-reset requests and HR verification codes.'),
        ('Employment records',
            'Record of original documents held by the company (for example marksheets, degree, Aadhaar, PAN, '
                'experience letters, passport or police verification, medical fitness), with certificate numbers, '
                'status and locker reference; profile verification status. Entered by HR.'),
        ('Attendance',
            'Check-in and check-out times and status from the office biometric attendance sheet, leave, '
                'permission and week-off requests, grooming audit results.'),
        ('Medical leave',
            'Emergency medical leave requests, including a photo of the doctor\'s prescription (compressed to '
                'a small image).'),
        ('Work',
            'Tasks, to-dos, SOP checklists, task reassignments, blocker tickets, daily and monthly scorecards, '
                'team performance figures, Konar Book entries, media files sent for review.'),
        ('Health pillar',
            'Height, weight, BMI, calorie target, meals and calories, workouts, daily steps, water glasses, '
                'sleep hours, your water and sleep goals. Steps can also come from Health Connect or Apple Health '
                'if you allow it.'),
        ('Family Time pillar', 'Time spent with family or friends, the activity, notes and optional photos.'),
        ('Social Cause pillar',
            'Good deeds you post, amount spent, description, photos, approval status, reactions, and your own '
                'amount and good-deed goals.'),
        ('Chat and announcements',
            'Messages, emoji reactions, attachments, comments on company notices, announcements and nudges.'),
        ('Personal notes', 'Private notes you write in the app.'),
        ('Online orders', 'Customer name, order details, sales channel, delivery date and progress checklist.'),
        ('Device and app data',
            'Push-notification token, notification settings, saved app preferences, and a sign-in session '
                'stored securely on your phone.'),
      ]),
      LegalNote('We do not collect your location, contacts, call logs, SMS, browsing history or advertising ID. '
          'The app shows no ads and has no third-party analytics or tracking.'),
    ]),
    LegalSection('Device permissions', [
      LegalPara('The app only asks for a permission when you use the feature that needs it. You can turn any of '
          'them off in your phone settings; the rest of the app keeps working.'),
      LegalBullets([
        'Camera and photos: to take or pick a profile photo, prescription photo, Family Time or Social Cause '
            'photo, or a chat attachment.',
        'Files: to attach documents and to save exported reports (PDF or Excel) when you ask.',
        'Physical activity, Health Connect (Android) or Apple Health (iPhone): to read your step count.',
        'Notifications, alarms and background running: to show reminders for tasks, attendance and '
            'announcements on time, including after your phone restarts.',
        'Internet and network state: to sync your data and tell you when you are offline.',
      ]),
    ]),
    LegalSection('Health and step data', [
      LegalPara('If you turn on automatic steps, the app reads only your daily step count from Health Connect '
          '(Android) or Apple Health (iPhone). It never writes to, changes or deletes your health data there, '
          'and it reads nothing else.'),
      LegalBullets([
        'Step counts are used only to fill in your Health pillar and the step and calorie figures shown to you.',
        'Step data from Health Connect or Apple Health is never used for advertising, never sold, and never '
            'shared outside MN Jewel Park.',
        'You can turn automatic steps off in the app or remove the permission in Health Connect or the iPhone '
            'Health app at any time. Steps already saved stay in your Health history unless you ask us to delete them.',
      ]),
      LegalPara('The use of information received from Health Connect follows the Health Connect Permissions '
          'policy, including its Limited Use requirements.'),
    ]),
    LegalSection('How we use information', [
      LegalBullets([
        'To run your account, sign you in securely and help you reset a forgotten password through HR.',
        'To manage attendance, leave, permissions, tasks and daily work.',
        'To produce daily and monthly scorecards, team reports and exports for management.',
        'To show your own progress on the Health, Family Time, Work and Social Cause pillars, and to let your '
            'team lead or management check team well-being where your role allows it.',
        'To review and approve social causes, media and leave requests.',
        'To send you notifications, reminders, announcements, birthday wishes and chat messages.',
        'To keep the app safe, fix problems, and keep backups so data is not lost.',
      ]),
      LegalPara('We do not sell your information, and we do not use it for advertising.'),
    ]),
    LegalSection('Who can see your information', [
      LegalPara('Access inside the app depends on role and on the permissions management grants:'),
      LegalBullets([
        'You can see all of your own information.',
        'Your team lead can see your team\'s attendance, tasks and scorecards. Where the app allows, they can '
            'also see your Health and Family Time summaries.',
        'HR and assistant HR can see the staff records, attendance, leave and requests of the departments they '
            'are assigned to.',
        'The CEO and management can see information across all departments, approve requests, and make '
            'company backups.',
        'Other staff can see your name, photo, role and department, and anything you post in shared spaces: '
            'group chat, social causes you post, and comments on announcements.',
        'Personal notes are private to you.',
      ]),
      LegalPara('We may also disclose information when the law requires it, to protect the safety of staff or '
          'customers, or as part of a legal process.'),
    ]),
    LegalSection('Service providers', [
      LegalPara('We use a small number of trusted services to run the app. They process data only to provide '
          'their service to us.'),
      LegalRows([
        ('Google Firebase',
            'Authentication, Cloud Firestore, Cloud Functions and Cloud Messaging: sign-in, storing app data, '
                'password-reset and admin functions, push notifications.'),
        ('Google Drive and Apps Script', 'Storing media sent for review and Konar Book PDF files.'),
        ('Google Sheets', 'The attendance sheet from the office biometric system.'),
        ('Health Connect / Apple Health', 'Reading your step count on your phone, only if you allow it.'),
        ('Open Food Facts',
            'Looking up food calories. Only the food name you search for is sent, never your identity.'),
        ('Google Fonts', 'Showing the app\'s typeface.'),
      ]),
      LegalPara('Some of these providers may store data on servers outside India. We use providers that protect '
          'data with industry-standard security.'),
    ]),
    LegalSection('Storage and security', [
      LegalBullets([
        'Data is sent over encrypted connections (HTTPS) and stored in Google Firebase.',
        'Access is controlled by sign-in and by role-based security rules, so each person can only reach what '
            'their role allows.',
        'Your sign-in session is kept in your phone\'s secure storage. Some data is also saved on your phone so '
            'the app works offline.',
        'Company backups can only be made, restored or cleared by the CEO.',
      ]),
      LegalPara('No system is perfectly secure. Please keep your password private and tell HR straight away if '
          'you think someone has used your account.'),
    ]),
    LegalSection('How long we keep it', [
      LegalBullets([
        'We keep your information for as long as you work with MN Jewel Park and your account is active.',
        'When you leave, HR turns off your sign-in. We keep employment, attendance and payroll-related records '
            'for as long as Indian employment, tax and other laws require, then delete them.',
        'Personal pillar data (Health, Family Time, Social Cause goals) and personal notes are deleted within '
            '90 days of your account being closed, unless the law requires us to keep them or you ask us to '
            'delete them sooner.',
        'Backups are overwritten in normal course.',
      ]),
    ]),
    LegalSection('Your rights and choices', [
      LegalPara('Under India\'s Digital Personal Data Protection Act, 2023 and other applicable law, you can:'),
      LegalBullets([
        'Ask what personal information we hold about you and get a summary of it.',
        'Ask us to correct information that is wrong or out of date. You can edit much of your profile and '
            'pillar data yourself.',
        'Ask us to delete information we no longer need, subject to records we must keep by law.',
        'Withdraw consent for optional features, for example by turning off automatic steps, camera or '
            'notification access.',
        'Name another person to act for you if you are unable to.',
        'Raise a complaint with us, and if you are not satisfied, with the Data Protection Board of India.',
      ]),
      LegalPara('Using the four pillars beyond what your job needs is optional. You may leave Health, Family Time '
          'or Social Cause entries blank.'),
    ]),
    LegalSection('Deleting your account', [
      LegalPara('To delete your MN Family account and its data:'),
      LegalBullets([
        'Speak to HR, or email us at the address in "Contact us" from your registered email, with the subject '
            '"Delete my MN Family account".',
        'We confirm it is you, then turn off your sign-in straight away.',
        'Within 30 days we delete your profile, pillar data, personal notes, chat messages you sent and photos '
            'you uploaded.',
      ], numbered: true),
      LegalPara('We keep only the records the law requires (for example attendance and employment records), for '
          'the time the law requires, after which they are deleted.'),
    ]),
    LegalSection('Children', [
      LegalPara('The app is for staff aged 18 and over. We do not knowingly collect information from children. '
          'If a child\'s details are entered by mistake, for example in a Family Time note, please ask us to '
          'remove them.'),
    ]),
    LegalSection('Changes to this policy', [
      LegalPara('We may update this policy when the app or the law changes. We will change the "Last updated" '
          'date above, and for important changes we will tell you in the app before they take effect.'),
    ]),
    LegalSection('Contact us', [
      LegalPara('For any privacy question, request or complaint, contact our grievance officer:'),
      LegalContact('MN Jewel Park: Privacy & Grievance Officer', _contactLines),
      LegalPara('We reply within 7 days and resolve requests within 30 days.'),
    ]),
  ],
);

const termsAndConditions = LegalDocument(
  title: 'Terms & Conditions',
  lead: 'These terms set out the rules for using the MN Family app. They sit alongside your employment or '
      'engagement terms with MN Jewel Park and our company policies.',
  effective: '26 November 2026',
  updated: '26 November 2026',
  sections: [
    LegalSection('Accepting these terms', [
      LegalPara('The MN Family app ("the app") is provided by MN Jewel Park, Vellore, Tamil Nadu, India ("we", '
          '"us"). By signing in and using the app you agree to these terms and to our Privacy Policy. If you do '
          'not agree, please do not use the app and speak to HR.'),
      LegalPara('If these terms conflict with your appointment letter or a written company policy, the '
          'appointment letter or policy applies.'),
    ]),
    LegalSection('Who may use the app', [
      LegalBullets([
        'The app is only for MN Jewel Park employees, team leads, HR, management and outside support staff we invite.',
        'You must be 18 or older.',
        'You may use the app only while you work with us, and only for work and for the well-being features the '
            'app offers.',
      ]),
    ]),
    LegalSection('Your account', [
      LegalBullets([
        'HR or management creates your account. You sign in with the email and password they give you.',
        'Keep your password secret. Do not share your account or let anyone else use the app as you.',
        'You are responsible for what is done through your account. Tell HR straight away if you think someone '
            'else has used it.',
        'If you forget your password, use "Forgot password". HR verifies your request before a new password is set.',
        'Keep your profile details correct, and update them or tell HR when they change.',
      ]),
    ]),
    LegalSection('Roles and access', [
      LegalPara('What you can see and do depends on your role (employee, assistant team lead, team lead, HR, '
          'assistant HR, outside support or CEO) and on the permissions management grants.'),
      LegalBullets([
        'Use only the access you have been given, and only for its purpose. For example, use a team lead\'s view '
            'of the team\'s health or attendance only to support the team.',
        'Do not try to reach screens, records or data your role does not allow, or get around access controls.',
        'Management may change your role and access at any time.',
      ]),
    ]),
    LegalSection('Acceptable use', [
      LegalPara('When using the app, you must not:'),
      LegalBullets([
        'Enter false attendance, tasks, scorecard numbers, meals, steps, social causes or other records, or mark '
            'work done that is not done.',
        'Post anything abusive, harassing, discriminatory, sexual, violent or threatening, or anything that '
            'breaks the law.',
        'Share another person\'s personal details, photos or health information without a work reason, or '
            'outside the app.',
        'Take screenshots of, export, forward or copy colleagues\' or customers\' personal information except as '
            'your job requires.',
        'Upload viruses or harmful files, or try to hack, overload, copy or reverse-engineer the app.',
        'Use the app to sell, advertise or promote anything that is not MN Jewel Park business.',
      ]),
      LegalPara('Breaking these rules may lead to the app being suspended for you and to action under company policy.'),
    ]),
    LegalSection('What you post', [
      LegalBullets([
        'You are responsible for the messages, photos, files, notes and comments you add.',
        'Only upload photos you took or have the right to share. Get permission before posting photos of other '
            'people, including family members.',
        'You allow MN Jewel Park to store, show and use what you post inside the app, and in company reports, '
            'for work purposes.',
        'Managers and HR may remove content that breaks these terms or company policy.',
      ]),
    ]),
    LegalSection('Attendance, tasks and records', [
      LegalBullets([
        'Attendance comes from the office biometric system and the records HR keeps. The app shows this '
            'information; HR\'s official record decides any difference.',
        'Leave, permission and medical-leave requests made in the app need approval under company leave policy. '
            'A request is not approved until the app or HR says so.',
        'Medical-leave requests must include a genuine doctor\'s prescription.',
        'Tasks, scorecards and reports in the app may be used to review your work and the team\'s performance.',
        'Original documents you hand over are held by the company as recorded in the app, and returned '
            'according to company policy.',
      ]),
    ]),
    LegalSection('The four pillars', [
      LegalPara('Health, Family Time, Work and Social Cause are there to encourage a balanced life. Apart from '
          'work records your job requires, entering personal pillar details is your choice.'),
      LegalBullets([
        'Goals you set yourself, such as calories, water, sleep, or social-cause amounts and counts, are '
            'personal targets. You can change them at any time.',
        'Pillar progress may be shown to your team lead or management, as described in the Privacy Policy.',
      ]),
    ]),
    LegalSection('Health information disclaimer', [
      LegalNote('The Health pillar is not medical advice. BMI, calorie targets, protein, carbs, fat and fibre '
          'goals, nutrition estimates and calories burned are general estimates from standard formulas and '
          'typical food values. They may not suit your body or medical condition.'),
      LegalPara('Speak to a doctor or qualified dietitian before changing your diet, exercise or medication, '
          'especially if you are pregnant, have a medical condition or take medicines. In an emergency, contact '
          'a doctor or emergency services, not the app.'),
    ]),
    LegalSection('Social causes', [
      LegalBullets([
        'Good deeds you post must be real. Amounts must be what you actually spent, and photos must show the '
            'actual deed.',
        'Posts are reviewed by HR or management, who may approve, reject or ask for more detail.',
        'Social causes are your own voluntary acts. Unless management agrees in writing, the company does not '
            'refund or pay for them.',
      ]),
    ]),
    LegalSection('Confidential business information', [
      LegalPara('Sales figures, scorecards, orders, customer details, Konar Book content, SOPs, pricing, designs '
          'and media in the app are confidential MN Jewel Park information. Do not share them outside the '
          'company, during or after your time with us, unless you have written permission.'),
    ]),
    LegalSection('Ownership', [
      LegalPara('The app, its design, logos, the MN Jewel Park and Vadivam names, and company content belong to '
          'MN Jewel Park. You may use them only to do your work through the app. Work you create for the '
          'company through the app belongs to the company, as set out in your employment terms.'),
    ]),
    LegalSection('Availability and updates', [
      LegalBullets([
        'We try to keep the app working, but it may sometimes be slow or unavailable, for example during '
            'updates or without internet.',
        'Install updates when asked. Older versions may stop working.',
        'We may add, change or remove features at any time.',
      ]),
    ]),
    LegalSection('Suspension and leaving', [
      LegalBullets([
        'We may suspend or close your access if you break these terms or company policy, or for security reasons.',
        'When you leave MN Jewel Park, your access ends and HR turns off your sign-in. Your data is then '
            'handled as described in the Privacy Policy.',
        'Sections 6, 11, 12, 15 and 16 continue to apply after your access ends.',
      ]),
    ]),
    LegalSection('Limits of liability', [
      LegalPara('The app is provided as a work tool "as is". As far as the law allows, MN Jewel Park is not '
          'responsible for:'),
      LegalBullets([
        'Decisions you make based on health estimates or other general information in the app.',
        'Loss caused by your sharing your password or by misuse of your account by someone you let use it.',
        'Problems caused by your phone, internet connection, or third-party services such as Health Connect '
            'or Apple Health.',
      ]),
      LegalPara('Nothing in these terms takes away rights you have by law that cannot be limited.'),
    ]),
    LegalSection('Governing law and disputes', [
      LegalPara('These terms are governed by the laws of India. Please raise any problem with HR or our grievance '
          'officer first, and we will try to resolve it. If it cannot be resolved, the courts in Vellore, '
          'Tamil Nadu have jurisdiction.'),
    ]),
    LegalSection('Changes to these terms', [
      LegalPara('We may update these terms. We will change the "Last updated" date above, and for important '
          'changes we will tell you in the app. If you keep using the app after a change, you accept the new terms.'),
    ]),
    LegalSection('Contact us', [
      LegalContact('MN Jewel Park: HR & Grievance Officer', [
        ('Name', '[Officer name]'),
        ('Email', '[hr@your-domain.com]'),
        ('Phone', '[+91 phone number]'),
        ('Address', '[Street address], Vellore, Tamil Nadu, India'),
      ]),
    ]),
  ],
);
