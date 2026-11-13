import 'task_model.dart';

class KonarTaskCatalog {
  /// Generates the standard daily SOP tasks for each role based on the Konar Book
  static List<TaskItem> getStandardTasksForEmployee(String empId, String roleCode, String empName) {
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

      default:
        return [
          TaskItem(
            id: 'KONAR-GEN-1',
            empId: empId,
            title: 'Daily Department SOP & Deliverables Execution',
            category: 'Daily Operations',
            isDefaultSop: true,
            assignedByRole: 'system',
            assignedByName: 'Konar SOP',
            due: '11:00 AM',
            priority: 'High',
            status: 'pending',
          ),
        ];
    }
  }

  /// Resolves the role code ('VPE', 'ASS.VPE', 'OTM', 'OSH', 'OS1', 'OS2', 'ECE', 'AC', 'OSS', 'DVP', 'CC')
  /// from an employee's role string, email, or id.
  static String resolveRoleCode(String role, String email, String id) {
    final r = role.toLowerCase();
    final e = email.toLowerCase();
    final i = id.toUpperCase();

    // Check CEO and HR first so they never get mistakenly assigned department roles!
    if (e.contains('ceoofmn') || e.contains('ceo') || r.contains('ceo') || i.contains('CEO')) {
      return 'CEO';
    }
    if (e.contains('mohankumar') || e.contains('hr') || r.contains('hr') || i.contains('HR')) {
      return 'HR';
    }

    // OTM is strictly for Praveen Kumar (praveenkumarotm@mnj.com / MN-TL1002)
    if (e == 'praveenkumarotm@mnj.com' ||
        e.contains('praveen') ||
        i == 'MN-TL1002' ||
        r.contains('online team manager') ||
        (r.contains('otm') && !r.contains('photographer'))) {
      return 'OTM';
    }
    if (e.contains('gokul') || e.contains('osh') || r.contains('osh') || r.contains('sale head')) {
      return 'OSH';
    }
    if (e.contains('mithra') || e.contains('assvpe') || r.contains('ass.vpe') || r.contains('assistant photographer')) {
      return 'ASS.VPE';
    }
    if (e.contains('aravind') || e.contains('vpe') || r.contains('vpe') || r.contains('chief photographer')) {
      return 'VPE';
    }
    if (e.contains('ece') || r.contains('ece') || r.contains('commerce')) {
      return 'ECE';
    }
    if (e.contains('kaaviya') || e.contains('os1') || r.contains('os1') || r.contains('person 1')) {
      return 'OS1';
    }
    if (e.contains('nisha') || e.contains('os2') || r.contains('os2') || r.contains('person 2')) {
      return 'OS2';
    }
    if (e.contains('midhun') || e.contains('ac') || r.contains('analytical')) {
      return 'AC';
    }
    if (e.contains('subash') || e.contains('oss') || r.contains('strategist')) {
      return 'OSS';
    }
    if (e.contains('eshwar') || e.contains('dvp') || r.contains('developer')) {
      return 'DVP';
    }
    if (e.contains('samroy') || e.contains('cc') || r.contains('content creator')) {
      return 'CC';
    }

    return 'GEN';
  }
}

