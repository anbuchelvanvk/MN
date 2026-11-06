# Complete Architecture & Guide: Connecting eSSL Biometric Hardware & Software to the MN Family App

This document explains exactly how data flows from the physical eSSL biometric fingerprint hardware terminal to the company's software server, and how our Flutter mobile/desktop app connects to it to display live check-in/check-out punches and compute the Sovereign Green Light tier.

---

## 1. High-Level Data Flow Diagram

```
 [Employee Thumb]
        │
        ▼
┌──────────────────────────────────────────────┐
│  eSSL Hardware Terminal                      │
│  (SilkBio-101TC / K90 / MB20 @ 192.168.1.201)│
│  - Reads thumb impression optical template   │
│  - Stores punch in internal EEPROM memory    │
│  - Port 4370 (TCP / UDP)                     │
└──────────────────────┬───────────────────────┘
                       │
       ┌───────────────┴───────────────┐
       ▼                               ▼
[Route A: Official Software]     [Route B: Direct Bridge Service]
eTimeTrackLite / ZKBioTime       essl_bridge_server.js / node-zklib
Running on Office Windows Server  Listening on port 5055 / 4370
       │                               │
       ▼                               ▼
┌──────────────────────────────┐ ┌──────────────────────────────┐
│ eSSL Database                │ │ REST API Endpoints           │
│ (MS SQL / MySQL / Access)    │ │ GET  /api/attendance/today   │
│ Table: `DeviceLogs`          │ │ POST /api/attendance/punch   │
└──────────────┬───────────────┘ └──────────────┬───────────────┘
               │                                │
               └───────────────┬────────────────┘
                               │ JSON over HTTP/Wi-Fi
                               ▼
        ┌──────────────────────────────────────────────┐
        │  MN Family Flutter App                       │
        │  - Pillar 4: eSSL Biometric Attendance       │
        │  - Pillar 1 (Health) + Pillar 2 (Family)     │
        │  - Pillar 3 (Profile Vault Custody)          │
        │  - Sovereign Green Light Holistic Tier       │
        └──────────────────────────────────────────────┘
```

---

## 2. The 3 Methods to Connect eSSL to the App

### Method 1: Connecting to the Official eSSL Software Database (eTimeTrackLite)
*(Recommended if your office already runs eTimeTrackLite on an office computer)*

When your office already has the eSSL desktop software running, it automatically downloads punches from the machine every few minutes and stores them in a database:
- **Database Engine**: MS Access (`C:\Users\achel\Downloads\Attendance\eTimeTrackLite1.mdb`) or Microsoft SQL Server.
- **Target Table**: `DeviceLogs` (Stores raw punches with `LogDate`, `UserId`, `C1`/`Direction` for In, Lunch Break, and Out).

#### Key Database Columns:
| Column Name | Type | Description |
|---|---|---|
| `UserId` / `EnrollNumber` | VARCHAR | Employee ID (e.g. `MN-1024`) |
| `LogDate` | DATETIME | Timestamp of punch (e.g. `2026-10-27 09:14:28`) |
| `Direction` / `C1` | VARCHAR | `in` (Login) or `out` (Logout) |
| `VerificationType` | INT | `1` = Fingerprint/Thumb, `4` = Face, `3` = Card |
| `DeviceId` | INT | Biometric machine terminal number |

#### Simple SQL Query to Fetch Today's Punches:
```sql
SELECT 
    UserId AS enrollNumber,
    LogDate AS timestamp,
    CASE WHEN C1 = 'out' THEN 'logout' ELSE 'login' END AS punchType,
    CASE WHEN VerificationType = 1 THEN 'thumbImpression' ELSE 'face' END AS verifyMethod,
    '192.168.1.201:4370' AS terminalIp
FROM DeviceLogs
WHERE UserId = 'MN-1024'
  AND CAST(LogDate AS DATE) = CAST(GETDATE() AS DATE)
ORDER BY LogDate ASC;
```

A lightweight backend API (in Node.js, Python FastAPI, or C#) runs this query and returns JSON directly to the Flutter app!

---

### Method 2: Direct Machine Communication via Port 4370 (Zero Software Needed)
*(Best for real-time synchronization directly from the hardware without keeping eTimeTrackLite open)*

All eSSL and ZKTeco machines communicate over **TCP/IP port 4370** using the ZK protocol. You can run a lightweight Node.js or Python background daemon directly in the office:

#### Using `node-zklib`:
```bash
npm install node-zklib
```

```javascript
const ZKLib = require('node-zklib');

async function monitorAttendance() {
  const zk = new ZKLib('192.168.1.201', 4370, 10000, 4000);
  
  // Connect to the eSSL terminal
  await zk.createSocket();
  console.log('Connected to eSSL Biometric Scanner at 192.168.1.201:4370');

  // Listen for real-time thumb impression punches
  zk.getRealTimeLogs((punch) => {
    console.log('Live thumb scan detected:', punch);
    // punch contains: { userId: '1024', attTime: '2026-10-27 09:14:28' }
    
    // Broadcast punch to MN Family App via WebSocket or HTTP POST
  });
}

monitorAttendance();
```

---

### Method 3: Using the C# `zkemkeeper.dll` SDK in `DeviceCommunication/`

In the workspace directory `DeviceCommunication/DeviceCommunication/UserInfo/`:
- The file `UserInfoMainTFT.cs` registers real-time biometric callbacks using the official Windows SDK `zkemkeeper.dll`:
```csharp
axCZKEM1.Connect_Net("192.168.1.201", 4370);
axCZKEM1.RegEvent(1, 65535);
this.axCZKEM1.OnAttTransactionEx += new zkemkeeper._IZKEMEvents_OnAttTransactionExEventHandler(axCZKEM1_OnAttTransactionEx);

void axCZKEM1_OnAttTransactionEx(string enrollNumber, int isInValid, int attState, int verifyMethod, int year, int month, int day, int hour, int minute, int second, int workCode)
{
    // Real-time thumb punch event triggered instantly when finger touches the reader!
    string punchType = (attState == 1) ? "logout" : "login";
    DateTime punchTime = new DateTime(year, month, day, hour, minute, second);
    
    // Send to MN Family App REST Bridge
}
```

---

## 3. How the Flutter App Synchronizes

In [`lib/providers/ecosystem_provider.dart`](file:///c:/Users/achel/Downloads/mn-family-app/lib/providers/ecosystem_provider.dart), the app provides:
1. `syncFromEsslDevice()`:
   - Queries `http://<SERVER_IP>:5055/api/attendance/today?empId=MN-1024` over HTTP.
   - Automatically populates the Attendance Pillar cards and Audit Trail ledger.
   - If offline or testing outside office Wi-Fi, gracefully retains local simulated logs without crashing.
2. `recordThumbImpressionPunch()`:
   - Allows instant punch recording directly in the app.
   - Automatically notifies the bridge server via `POST /api/attendance/punch`.
3. **Pillar 4 Impact on Sovereign Green Light Tier**:
   - Punctual biometric login recorded on or before `09:30 AM` contributes positively to the Green Light.
   - Missing or late attendance triggers Yellow or Red Light status and highlights direct corrective navigation in the audit inspector.
