# 🏆 MN Family App — Flutter & Firebase Architecture Blueprint
**Company:** MN Jewel Park  
**Target Platform:** Flutter (iOS / Android / Web)  
**Backend:** Firebase (Auth, Firestore, Cloud Functions, Cloud Storage) — *Blaze Pay-As-You-Go Plan ($0 – $2/month)*

---

## 1. Flutter Project Structure & Folder Hierarchy

```
mn_family_app/
├── android/
├── ios/
├── assets/
│   ├── images/
│   │   └── logo.svg               # Vector brand logo
│   └── fonts/
│       ├── Cinzel-Bold.ttf
│       └── PlusJakartaSans-Regular.ttf
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart    # Luxury Black & Gold Palette
│   │   │   ├── app_typography.dart
│   │   │   └── app_theme.dart
│   │   ├── network/
│   │   └── utils/
│   │       ├── bmi_calculator.dart
│   │       └── gold_price_calculator.dart
│   ├── models/
│   │   ├── user_model.dart        # Role, DOB, DOJ, Traffic Rating
│   │   ├── task_model.dart        # Title, SLA, AssignedBy, Immutable
│   │   ├── attendance_model.dart  # PunchIn, PunchOut, GeoLocation
│   │   ├── health_gate_model.dart # BMI, FamilyHours, DietLogs
│   │   ├── salary_slip_model.dart # Breakdown, Incentives, PF
│   │   └── onboarding_step_model.dart
│   ├── providers/ / blocs/
│   │   ├── auth_provider.dart
│   │   ├── task_provider.dart
│   │   ├── health_gate_provider.dart
│   │   ├── attendance_provider.dart
│   │   └── ceo_radar_provider.dart
│   ├── views/
│   │   ├── splash/
│   │   │   └── splash_screen.dart # Animated Gold Monogram
│   │   ├── auth/
│   │   │   └── login_screen.dart  # Role based entry
│   │   ├── home/
│   │   │   ├── home_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── live_gold_ticker.dart
│   │   │   │   ├── wellness_gate_card.dart
│   │   │   │   ├── attendance_punch_card.dart
│   │   │   │   ├── workflow_carousel.dart
│   │   │   │   └── task_pipeline_list.dart
│   │   ├── tasks/
│   │   │   └── task_management_screen.dart
│   │   ├── vault/
│   │   │   ├── employee_vault_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── digital_gold_id_card.dart
│   │   │   │   └── salary_breakdown_sheet.dart
│   │   ├── onboarding/
│   │   │   └── academy_progress_screen.dart
│   │   ├── ceo_hub/
│   │   │   ├── ceo_executive_dashboard.dart
│   │   │   └── widgets/
│   │   │       ├── dept_kpi_cards.dart
│   │   │       └── delay_bottleneck_spotter.dart
│   │   └── gazette/
│   │       └── newsletter_feed_screen.dart
│   └── main.dart
└── pubspec.yaml
```

---

## 2. Core Flutter Design Tokens (`app_colors.dart`)

```dart
import 'package:flutter/material.dart';

class AppColors {
  // Metallic Gold Gradient Constants
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF6E27A);
  static const Color goldBright = Color(0xFFFFF2A3);
  static const Color goldDark = Color(0xFF997D1E);

  // Obsidian & Dark Neutral Backgrounds
  static const Color bgDarkest = Color(0xFF070709);
  static const Color bgApp = Color(0xFF0E0F13);
  static const Color bgCard = Color(0xFF16181E);
  static const Color borderGold = Color(0x47D4AF37);

  // Performance Traffic Lights
  static const Color trafficGreen = Color(0xFF10B981);
  static const Color trafficYellow = Color(0xFFF59E0B);
  static const Color trafficRed = Color(0xFFEF4444);

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF9E381), Color(0xFFD4AF37), Color(0xFF997D1E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
```

---

## 3. Firestore Database Schema Design (Low Cost / High Efficiency)

Optimized for 150 employees with **< 10,000 document reads/writes daily** (costs under **$1.50/month** on Firebase Blaze):

1. **`users/{userId}`**
   - `name`: string
   - `role`: `'artisan' | 'lead' | 'hr' | 'ceo'`
   - `department`: string
   - `dob`, `doj`, `phone`: string
   - `trafficScore`: `'green' | 'yellow' | 'red'`
   - `currentBmi`: float
   - `onboardingCompleted`: bool

2. **`attendance/{date_userId}`**
   - `punchIn`: timestamp
   - `punchOut`: timestamp
   - `location`: GeoPoint (Showroom / Workshop)
   - `hoursWorked`: float

3. **`tasks/{taskId}`**
   - `assignedTo`: userId
   - `assignedBy`: `'CEO Office' | 'Lead' | 'Self'`
   - `title`: string
   - `isImmutable`: bool (Requires Admin role to mutate/delete)
   - `completed`: bool
   - `dueTime`: timestamp

4. **`wellness_logs/{date_userId}`**
   - `bmi`: float
   - `familyHours`: float
   - `dietChecked`: bool
   - `mentalCalmRating`: string

5. **`performance_audit/{auditId}`**
   - `employeeId`: userId
   - `reviewerId`: userId
   - `score`: string
   - `color`: `'green' | 'yellow' | 'red'`
   - `leadComment`: string
   - `timestamp`: serverTimestamp()

6. **`gazette_news/{newsId}`**
   - `title`, `body`, `author`, `tag`: string
   - `likesCount`: int
   - `publishedAt`: timestamp

---

## 4. Key Flutter Packages Recommended

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_svg: ^2.0.9            # Crisp rendering of MN Logo
  provider: ^6.1.1               # State management
  firebase_core: ^2.27.0         # Firebase Base
  firebase_auth: ^4.17.8         # Authentication
  cloud_firestore: ^4.15.8       # Real-time Database
  google_fonts: ^6.1.0           # Plus Jakarta Sans & Cinzel
  intl: ^0.19.0                  # Currency & Date formatting
  flutter_animate: ^4.5.0        # Smooth gold shimmer & entrance micro-animations
```
