import 'task_model.dart';

class KonarTaskCatalog {
  /// Generates the standard daily SOP tasks for each role based on the Konar Book
  static List<TaskItem> getStandardTasksForEmployee(
    String empId,
    String roleCode,
    String empName, [
    String? roleTitle,
    String? deptName,
  ]) {
    switch (roleCode.toUpperCase()) {
      case 'VPE': // Chief Photographer & Video Editor (Mr. Y. Aravinda Samy)
        return [
          TaskItem(
            id: 'KONAR-VPE-1',
            empId: empId,
            title: 'Shoot & Edit 1 High-Quality Content Reel (Weekly 7 Reels Target)',
            category: 'Content Production',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '02:00 PM',
            priority: 'Critical SLA',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-VPE-2',
            empId: empId,
            title: 'Counter Product Selection with Ass.VPE across GF / 1st / 2nd Floor & Diamond',
            category: 'Content Planning',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '11:30 AM',
            priority: 'High',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-VPE-3',
            empId: empId,
            title: 'Submit Daily Reel & Video to CEO and OTM for Final Approval',
            category: 'Approval Workflow',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '04:30 PM',
            priority: 'High',
            status: 'pending',
          ),
        ];

      case 'ASS.VPE': // Assistant Photographer (Mrs. M. Mithra)
        return [
          TaskItem(
            id: 'KONAR-AVPE-1',
            empId: empId,
            title: 'Coordinate Counter Salespersons (Sandhiya, Suganya, Lakshmipriya) for Shoot',
            category: 'Content Planning',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '11:00 AM',
            priority: 'High',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-AVPE-2',
            empId: empId,
            title: 'Product Photo Shoot & Background Staging (3 Products for Website Asset Master)',
            category: 'Content Production',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '03:00 PM',
            priority: 'High',
            status: 'pending',
          ),
        ];

      case 'OTM': // Online Team Manager & Editor (Mr. M. Praveen Kumar)
        return [
          // 1. Instagram, Vadivam & Social Media
          TaskItem(
            id: 'KONAR-OTM-01',
            empId: empId,
            title: 'Gold carousel post',
            category: 'Instagram, Vadivam & Social Media',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '08:00 AM',
            priority: 'Standard',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OTM-02',
            empId: empId,
            title: 'Gold posts on X, LinkedIn & Pinterest',
            category: 'Instagram, Vadivam & Social Media',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '08:00 AM',
            priority: 'Standard',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OTM-03',
            empId: empId,
            title: 'Gold Instagram Story 1',
            category: 'Instagram, Vadivam & Social Media',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '10:00 AM',
            priority: 'High',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OTM-04',
            empId: empId,
            title: 'Vadivam Instagram Story',
            category: 'Instagram, Vadivam & Social Media',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '11:00 AM',
            priority: 'High',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OTM-05',
            empId: empId,
            title: 'Gold product reel',
            category: 'Instagram, Vadivam & Social Media',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '02:00 PM',
            priority: 'Critical SLA',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OTM-06',
            empId: empId,
            title: 'Gold Instagram Story 2',
            category: 'Instagram, Vadivam & Social Media',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '03:00 PM',
            priority: 'High',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OTM-07',
            empId: empId,
            title: 'Silver product reel',
            category: 'Instagram, Vadivam & Social Media',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '04:00 PM',
            priority: 'Critical SLA',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OTM-08',
            empId: empId,
            title: 'Vadivam carousel post',
            category: 'Instagram, Vadivam & Social Media',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '04:00 PM',
            priority: 'High',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OTM-09',
            empId: empId,
            title: 'Gold content reel',
            category: 'Instagram, Vadivam & Social Media',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '07:00 PM',
            priority: 'Critical SLA',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OTM-10',
            empId: empId,
            title: 'Gold Instagram Story 3',
            category: 'Instagram, Vadivam & Social Media',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '07:00 PM',
            priority: 'High',
            status: 'pending',
          ),

          // 2. YouTube
          TaskItem(
            id: 'KONAR-OTM-11',
            empId: empId,
            title: 'Gold product reel upload',
            category: 'YouTube',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '11:00 AM',
            priority: 'Critical SLA',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OTM-12',
            empId: empId,
            title: 'Gold content reel upload',
            category: 'YouTube',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '05:00 PM',
            priority: 'Critical SLA',
            status: 'pending',
          ),

          // 3. Sales & Customer Follow-ups (Due dates stripped for daily operational routine)
          TaskItem(
            id: 'KONAR-OTM-13',
            empId: empId,
            title: 'Customized Murugan Vel ring delivery follow-up',
            category: 'Sales & Customer Follow-ups',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '01:00 PM',
            priority: 'Critical SLA',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OTM-14',
            empId: empId,
            title: 'US customer chain with pendant follow-up',
            category: 'Sales & Customer Follow-ups',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '02:00 PM',
            priority: 'High',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OTM-15',
            empId: empId,
            title: 'Customized name pendant follow-up',
            category: 'Sales & Customer Follow-ups',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '03:00 PM',
            priority: 'High',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OTM-16',
            empId: empId,
            title: 'Other pending orders and payments follow-up',
            category: 'Sales & Customer Follow-ups',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '05:00 PM',
            priority: 'High',
            status: 'pending',
          ),

          // 4. Production & Influencers (Renuka removed & due dates stripped for daily routine)
          TaskItem(
            id: 'KONAR-OTM-17',
            empId: empId,
            title: 'Plan daily shoots & production schedule',
            category: 'Production & Influencers',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '10:30 AM',
            priority: 'High',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OTM-18',
            empId: empId,
            title: 'App promotional video shoot for Meta Ads',
            category: 'Production & Influencers',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '12:00 PM',
            priority: 'High',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OTM-19',
            empId: empId,
            title: 'Influencer video coordination & review',
            category: 'Production & Influencers',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '03:30 PM',
            priority: 'Critical SLA',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OTM-20',
            empId: empId,
            title: 'Coordinate influencer shoots',
            category: 'Production & Influencers',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '04:30 PM',
            priority: 'High',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OTM-21',
            empId: empId,
            title: 'Vadivam Nisha priority follow-up',
            category: 'Production & Influencers',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '05:30 PM',
            priority: 'Critical SLA',
            status: 'pending',
          ),

          // 5. Website, App & Marketing (Due dates stripped for daily routine)
          TaskItem(
            id: 'KONAR-OTM-22',
            empId: empId,
            title: 'MN Jewel Park and Vadivam broadcasts',
            category: 'Website, App & Marketing',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '11:30 AM',
            priority: 'Critical SLA',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OTM-23',
            empId: empId,
            title: 'Website listing and development follow-up',
            category: 'Website, App & Marketing',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '12:30 PM',
            priority: 'High',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OTM-24',
            empId: empId,
            title: 'MN Family App review preparation',
            category: 'Website, App & Marketing',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '02:30 PM',
            priority: 'Critical SLA',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OTM-25',
            empId: empId,
            title: 'Meta Ads campaign follow-up',
            category: 'Website, App & Marketing',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '04:00 PM',
            priority: 'High',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OTM-26',
            empId: empId,
            title: 'FDX pending work and meeting preparation',
            category: 'Website, App & Marketing',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '05:00 PM',
            priority: 'High',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OTM-27',
            empId: empId,
            title: 'Festival & special campaign preparation',
            category: 'Website, App & Marketing',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '06:00 PM',
            priority: 'Standard',
            status: 'pending',
          ),

          // 6. Today's Updates & Management
          TaskItem(
            id: 'KONAR-OTM-28',
            empId: empId,
            title: 'Morning Online Dept Briefing & Attendance Verification',
            category: 'Today\'s Updates / Pending Notes',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '10:00 AM',
            priority: 'Critical SLA',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OTM-29',
            empId: empId,
            title: 'Daily department updates & pending shift notes log',
            category: 'Today\'s Updates / Pending Notes',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '07:30 PM',
            priority: 'High',
            status: 'pending',
          ),
        ];

      case 'OSH': // Online Sale Head (Mr. K. Gokulakrishnan)
        return [
          TaskItem(
            id: 'KONAR-OSH-1',
            empId: empId,
            title: 'Audit OS1 & OS2 Hot Leads, WhatsApp Conversions & Target Check (₹50L Monthly)',
            category: 'Sales Management',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '11:00 AM',
            priority: 'Critical SLA',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OSH-2',
            empId: empId,
            title: 'Verify Product Details (Weight, Making Charges MC, Value Addition VA) before App/Web Listing',
            category: 'Product Approval',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '01:30 PM',
            priority: 'High',
            status: 'pending',
          ),
        ];

      case 'OS1': // Online Sale Person 1 (Ms. Kaaviya)
        return [
          TaskItem(
            id: 'KONAR-OS1-1',
            empId: empId,
            title: 'Daily Gold Rate Update (Morning 10:30 AM & Evening 04:00 PM)',
            category: 'Engagement Activity',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '10:30 AM',
            priority: 'Critical SLA',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OS1-2',
            empId: empId,
            title: 'WhatsApp Status Broadcast on 2 Official Numbers (80567 36999 & 89258 68077)',
            category: 'WhatsApp Distribution',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '11:00 AM',
            priority: 'High',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OS1-3',
            empId: empId,
            title: 'Process Direct Sales, Payment Confirmation & Dispatch Coordination with Packaging Head',
            category: 'Sales Execution',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '02:30 PM',
            priority: 'High',
            status: 'pending',
          ),
        ];

      case 'OS2': // Online Sale Person 2 (Ms. Nisha)
        return [
          TaskItem(
            id: 'KONAR-OS2-1',
            empId: empId,
            title: 'Vadivam Custom Design Enquiry Response & 24-Hour Concept Coordination',
            category: 'Custom Jewelry',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '11:00 AM',
            priority: 'Critical SLA',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OS2-2',
            empId: empId,
            title: 'CADD & Quotation Confirmation with Order Dept and Accountant',
            category: 'Order Workflow',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '02:00 PM',
            priority: 'High',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OS2-3',
            empId: empId,
            title: 'Share Google Review & Feedback Link with Satisfied Delivery Customers',
            category: 'Customer Delight',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '04:00 PM',
            priority: 'High',
            status: 'pending',
          ),
        ];

      case 'ECE': // E-Commerce Executive
        return [
          TaskItem(
            id: 'KONAR-ECE-1',
            empId: empId,
            title: 'Upload Jewelry Assets to Website & App (Monthly Target: 400 MN / 200 Vadivam)',
            category: 'Digital Catalog',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '12:00 PM',
            priority: 'High',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-ECE-2',
            empId: empId,
            title: 'Check Product Tag Numbers, Spec Descriptions, and Image Alt Tags',
            category: 'Catalog QA',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '03:30 PM',
            priority: 'High',
            status: 'pending',
          ),
        ];

      case 'AC': // Online Analytical Consultant (Mr. J. Midhun Kumar)
        return [
          TaskItem(
            id: 'KONAR-AC-1',
            empId: empId,
            title: 'Audit Google Ads (PMax, Search, Shopping) and Meta Ads Spend vs Leads',
            category: 'Performance Analytics',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '11:30 AM',
            priority: 'Critical SLA',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-AC-2',
            empId: empId,
            title: 'Track Organic Keyword Rankings (Top 5 Target) & Submit Weekly Ad Report to CEO',
            category: 'Executive Reporting',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '04:00 PM',
            priority: 'Critical SLA',
            status: 'pending',
          ),
        ];

      case 'OSS': // Online Support & Strategist (Mr. Subash)
        return [
          TaskItem(
            id: 'KONAR-OSS-1',
            empId: empId,
            title: 'Schedule Galla Box WhatsApp Broadcasts & Social Media Story Sequences',
            category: 'Campaign Strategy',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '11:00 AM',
            priority: 'High',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-OSS-2',
            empId: empId,
            title: 'Hold Campaign Review Meeting with AC for Vadivam Marketing Roadmap',
            category: 'Marketing Strategy',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '03:30 PM',
            priority: 'High',
            status: 'pending',
          ),
        ];

      case 'DVP': // Developer (Mr. K.B. Eshwar)
        return [
          TaskItem(
            id: 'KONAR-DVP-1',
            empId: empId,
            title: 'Technical SEO Check: XML Sitemaps, Schema Markup, Page Speed & Mobile Responsiveness',
            category: 'Engineering & SEO',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '11:00 AM',
            priority: 'High',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-DVP-2',
            empId: empId,
            title: 'Verify Add-to-Cart & Wishlist Lead Capture Flow with Phone Number Sync',
            category: 'Platform Health',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '03:00 PM',
            priority: 'High',
            status: 'pending',
          ),
        ];

      case 'CC': // Content Creator (Mr. Sam Roy)
        return [
          TaskItem(
            id: 'KONAR-CC-1',
            empId: empId,
            title: 'Draft Script & Storyboard for Daily Reel & 3 Stories (1 Day in Advance)',
            category: 'Creative Writing',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '10:30 AM',
            priority: 'Critical SLA',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-CC-2',
            empId: empId,
            title: 'Produce Multi-Platform Content: 7 YouTube Shorts, 5 LinkedIn Posts, 3 X Posts / Week',
            category: 'Social Distribution',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '02:30 PM',
            priority: 'High',
            status: 'pending',
          ),
        ];

      case 'HR':
        return [
          TaskItem(
            id: 'KONAR-HR-01',
            empId: empId,
            title: 'Audit Daily Staff Attendance, Punch Logs & Absence Tracker',
            category: 'HR Compliance',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'HR SOP',
            due: '10:30 AM',
            priority: 'Critical SLA',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-HR-02',
            empId: empId,
            title: 'Verify Frontline & Operations Staff Attire & Grooming Compliance',
            category: 'Grooming Audit',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'HR SOP',
            due: '11:30 AM',
            priority: 'High',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-HR-03',
            empId: empId,
            title: 'Process Pending Leave, Medical Leave & Emergency Permission Submissions',
            category: 'Staff Approvals',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'HR SOP',
            due: '01:00 PM',
            priority: 'High',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-HR-04',
            empId: empId,
            title: 'Review Staff Social Cause & Good Deed Submissions for Approval',
            category: 'Social Cause Review',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'HR SOP',
            due: '03:30 PM',
            priority: 'Medium',
            status: 'pending',
          ),
        ];

      case 'CEO':
        return [
          TaskItem(
            id: 'KONAR-CEO-01',
            empId: empId,
            title: 'Executive Board Review: Daily Revenue, Orders & Operational SLAs',
            category: 'Executive Review',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Board SOP',
            due: '11:00 AM',
            priority: 'Critical SLA',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-CEO-02',
            empId: empId,
            title: 'Approve Escalated Emergency Leave & Strategic Department Blockers',
            category: 'Executive Approvals',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Board SOP',
            due: '02:00 PM',
            priority: 'Critical SLA',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-CEO-03',
            empId: empId,
            title: 'Audit Floor Attendance, Mandates & Operational Privilege Allocations',
            category: 'Governance',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Board SOP',
            due: '05:00 PM',
            priority: 'High',
            status: 'pending',
          ),
        ];

      case 'TL': // Department Team Lead (Offline & other departments)
        final dept = (deptName != null && deptName.isNotEmpty) ? deptName : 'Department';
        return [
          TaskItem(
            id: 'KONAR-TL-01',
            empId: empId,
            title: '$dept Opening Readiness: Staff Attendance, Floor Setup & Daily Briefing',
            category: 'Operations Leadership',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '10:00 AM',
            priority: 'Critical SLA',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-TL-02',
            empId: empId,
            title: 'Mid-Day $dept Deliverables, Counter SLAs & Escalation Review',
            category: 'Deliverables & SLAs',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '01:30 PM',
            priority: 'High',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-TL-03',
            empId: empId,
            title: 'Review Walk-ins, Orders, Customer Requirements & Staff Productivity',
            category: 'Performance Tracking',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '05:00 PM',
            priority: 'High',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-TL-04',
            empId: empId,
            title: '$dept Shift Close: Task Audits, Vault Custody & Evening Handover to Management',
            category: 'Shift Close & Handover',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '08:30 PM',
            priority: 'Critical SLA',
            status: 'pending',
          ),
        ];

      default:
        final title = (roleTitle != null && roleTitle.isNotEmpty) ? roleTitle : 'Department Operations';
        return [
          TaskItem(
            id: 'KONAR-GEN-1',
            empId: empId,
            title: '$title: Morning Opening Readiness & Operational Checklist',
            category: 'Daily Operations',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '10:15 AM',
            priority: 'High',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-GEN-2',
            empId: empId,
            title: '$title: Core Deliverables Execution, Customer Service & Task SLAs',
            category: 'Core Deliverables',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '02:30 PM',
            priority: 'High',
            status: 'pending',
          ),
          TaskItem(
            id: 'KONAR-GEN-3',
            empId: empId,
            title: '$title: Shift Reconciliation, Cleanliness & Evening Department Handover',
            category: 'Shift Handover',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '08:00 PM',
            priority: 'Standard',
            status: 'pending',
          ),
        ];
    }
  }

  /// Resolves the role code ('VPE', 'ASS.VPE', 'OTM', 'TL', 'OSH', 'OS1', 'OS2', 'ECE', 'AC', 'OSS', 'DVP', 'CC', 'HR', 'CEO')
  /// from an employee's role string, email, or id with strict unambiguous matching.
  static String resolveRoleCode(String role, String email, String id, [String? dept]) {
    final r = role.toLowerCase().trim();
    final e = email.toLowerCase().trim();
    final i = id.toUpperCase().trim();
    final d = (dept ?? '').toLowerCase().trim();

    // 1. CEO (Managing Director & CEO - M N Naveenraaj)
    if (e == 'ceoofmn@mnjpark.com' ||
        e.startsWith('ceo@') ||
        i == 'MN-CEO01' ||
        r == 'ceo' ||
        r.contains('managing director') ||
        r.contains('chief executive') ||
        r.contains('executive ceo')) {
      return 'CEO';
    }

    // 2. HR Management (HR Manager & Operations Custodian - Mohankumar G)
    if (e == 'hr@mnj.com' ||
        e.contains('mohankumar') ||
        i == '7' ||
        i == 'MN-HR001' ||
        i == 'MN-HR1001' ||
        r == 'hr' ||
        r.contains('hr manager') ||
        r.contains('operations custodian')) {
      return 'HR';
    }

    // 3. OTM (Online Team Manager & Team Lead - Praveenkumar M)
    if (e == 'praveenkumarotm@mnj.com' ||
        (e.contains('praveen') && !r.contains('offline')) ||
        i == 'MN-TL1002' ||
        ((r.contains('online') || d.contains('online')) && (r.contains('team manager') || r.contains('team lead')))) {
      return 'OTM';
    }

    // 4. Team Lead (Offline & other departments)
    if (r.contains('team lead') ||
        r.contains('dept head') ||
        r.contains('department head') ||
        r.contains('department lead') ||
        r.contains('operations lead') ||
        r.contains('team manager') ||
        i.startsWith('MN-TL')) {
      return 'TL';
    }

    // 4. OSH (Online Sales Head - Gokul)
    if (e.contains('gokul') ||
        i == '6' ||
        r.contains('sale head') ||
        r.contains('sales head') ||
        r == 'osh') {
      return 'OSH';
    }

    // 5. ASS.VPE (Assistant Photographer - Mithra M)
    if (e.contains('mithra') ||
        e.contains('assvpe') ||
        i == '33' ||
        r.contains('ass.vpe') ||
        r.contains('assistant photographer')) {
      return 'ASS.VPE';
    }

    // 6. VPE (Chief Photographer & Video Editor - Y. Aravinda Samy)
    if (e.contains('aravind') ||
        i == 'EXT-VPE' ||
        r.contains('chief photographer') ||
        (r.contains('vpe') && !r.contains('ass'))) {
      return 'VPE';
    }

    // 7. OS1 (Online Sales Person 1 - Kaaviya)
    if (e.contains('kaaviya') ||
        i == '65' ||
        r.contains('sales person 1') ||
        r.contains('person 1') ||
        r == 'os1') {
      return 'OS1';
    }

    // 8. OS2 (Online Sales Person 2 - Nisha)
    if (e.contains('nisha') ||
        i == '67' ||
        r.contains('sales person 2') ||
        r.contains('person 2') ||
        r == 'os2') {
      return 'OS2';
    }

    // 9. AC (Analytical Consultant - Midhun)
    if (e.contains('midhun') ||
        i == 'EXT-AC' ||
        r.contains('analytical consultant') ||
        r == 'ac') {
      return 'AC';
    }

    // 10. OSS (Online Support and Strategist - Subash)
    if (e.contains('subash') ||
        i == 'EXT-OSS' ||
        r.contains('support and strategist') ||
        r == 'oss') {
      return 'OSS';
    }

    // 11. DVP (Developer - Eshwar)
    if (e.contains('eshwar') ||
        i == 'EXT-DVP' ||
        r.contains('developer') ||
        r == 'dvp') {
      return 'DVP';
    }

    // 12. CC (Content Creator / Customer Care - Sam Roy)
    if (e.contains('samroy') ||
        i == 'EXT-CC' ||
        r.contains('content creator') ||
        r == 'cc') {
      return 'CC';
    }

    // ECE fallback
    if (e.contains('ece') || r.contains('commerce')) {
      return 'ECE';
    }

    return 'GEN';
  }
}

