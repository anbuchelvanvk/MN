# eSSL Security Biometric Attendance Device Integration Guide

This guide explains how to connect your **eSSL Security biometric fingerprint / thumb impression device** directly to the **MN Family Enterprise App** to automatically record staff work **Login** and **Logout** times and calculate the **Sovereign Green Light** rating.

---

## 1. How the eSSL Hardware Device Communicates

The eSSL Security terminal communicates over **TCP/IP Ethernet (Port 4370)** using the ZK attendance communication protocol.

- **Default Device IP**: `192.168.1.201`
- **Default Port**: `4370`
- **Machine Number**: `1`
- **Protocol**: ZKTeco / eSSL Standalone SDK (`zkemkeeper.dll`)

### Core SDK Functions in `DeviceCommunication/UserInfo/`
1. `axCZKEM1.Connect_Net(ipAddress, port)`: Connects to physical eSSL device over local LAN.
2. `axCZKEM1.RegEvent(1, 65535)`: Subscribes to real-time events.
3. `OnAttTransactionEx(...)`: Triggered **instantly** when an employee touches the thumb scanner:
   - `sEnrollNumber`: Employee Staff ID (e.g. `MN-1024` or `1024`)
   - `iAttState`: `0` = Login (Check-In), `1` = Logout (Check-Out), `2` = Break-Out, `3` = Break-In
   - `iVerifyMethod`: `1` = Thumb Impression / Fingerprint
   - `iYear, iMonth, iDay, iHour, iMinute, iSecond`: Exact timestamp down to the second!
4. `axCZKEM1.SSR_GetGeneralLogData(...)`: Downloads all stored attendance punch records from device memory into the MN Family ledger.

---

## 2. Setting Up the Physical eSSL Device

1. **Connect Device to Local Network**:
   - Plug an RJ-45 Ethernet cable from the eSSL device into your office network switch or Wi-Fi router.
   - On the eSSL device physical screen, go to:
     `Menu -> Comm. -> Ethernet`
   - Set IP Address: `192.168.1.201` (or your office subnet IP)
   - Subnet Mask: `255.255.255.0`
   - Gateway: `192.168.1.1`
   - Port: `4370`

2. **Register Employee Thumb**:
   - In the device menu: `Menu -> User Mgt. -> New User`
   - Set User ID: `1024` (matches MN-1024 in MN Family)
   - Scan thumb impression 3 times on the optical sensor.

---

## 3. How the MN Family App Records Login & Logout

In **Pillar 4 (Attendance)**:
1. **Live eSSL Terminal Status**: Shows real-time connection status to `192.168.1.201:4370`.
2. **First In (Login)**: The first thumb punch of the day is automatically tagged as **Work Login (Check-In)**. If on or before 09:30 AM, status is marked **Present (On-Time Green)**.
3. **Last Out (Logout)**: The evening punch is tagged as **Work Logout (Check-Out)**. While shift is active, it shows **On Duty (Active Shift)**.
4. **Shift Duration**: Live calculation of working hours and minutes.

---

## 4. How Attendance Affects the Sovereign Green Light Rating

The **Sovereign Green Light** evaluates 4 pillars:
1. **Health (Pillar 1)**: Healthy BMI (18.5 - 26.0) and daily workout logged.
2. **Family (Pillar 2)**: Genuine, unforced quality time shared with family (no artificial quota).
3. **Profile (Pillar 3)**: All mandatory original certificates deposited in the company vault.
4. **Attendance (Pillar 4)**: **On-time login recorded via eSSL thumb impression scanner by 09:30 AM!**

- **Green Light**: When all 4 pillars are satisfied.
- **Yellow Light**: Minor compromise (e.g. late login or 1 document pending).
- **Red Light**: Critical compromise (absent attendance or no documents submitted).
- **Clicking the Green Light Circle**: Opens the full audit breakdown showing which area lags with instant one-click navigation to resolve it!

---

## 5. Running the Local Bridge Server

To pipe real-time punches from your active eTimeTrackLite 12.2 installation (`C:\Users\achel\Downloads\Attendance\eTimeTrackLite1.mdb`) directly into the app:
```bash
node DeviceCommunication/essl_sql_sync.js
```
The bridge server runs on `http://localhost:5055` and connects live to your actual MS Access database file:
- `C:\Users\achel\Downloads\Attendance\eTimeTrackLite1.mdb`
- Exposes: `GET /api/attendance/summary/today` (Workforce In, Lunch & Out times)
- Heartbeat: `GET /api/device/status`
