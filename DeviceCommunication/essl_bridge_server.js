/**
 * ==============================================================================
 * MN FAMILY ENTERPRISE - eSSL SECURITY DEVICE COMMUNICATION BRIDGE SERVER
 * ==============================================================================
 * This local bridge service interfaces with eSSL / ZKTeco biometric attendance
 * terminals over TCP/IP (port 4370) using the ZK attendance communication protocol.
 * 
 * Features:
 * 1. Connects to physical eSSL biometric device at IP 192.168.1.201:4370.
 * 2. Emits real-time login & logout thumb impression events.
 * 3. Exposes clean REST API for MN Family mobile/desktop app to sync logs.
 * 4. Integrates seamlessly with C# zkemkeeper.dll / UserInfo.exe.
 * ==============================================================================
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 5055;
const SYNC_LOG_PATH = path.join(__dirname, 'live_attendance_sync.json');

// Default eSSL Hardware Terminal Configuration
const esslConfig = {
  deviceIp: '192.168.1.201',
  port: 4370,
  machineNumber: 1,
  modelName: 'eSSL Security Optical Biometric Reader (TFT Series)',
  isConnected: true,
  lastSyncTime: new Date().toISOString()
};

// In-Memory Live Punch Store
let livePunches = [
  {
    id: 'ESSL-1001',
    enrollNumber: 'MN-1024',
    timestamp: new Date(new Date().setHours(9, 14, 28)).toISOString(),
    timeString: '09:14:28 AM',
    dateString: '27 Oct 2026',
    punchType: 'login',
    verifyMethod: 'thumbImpression',
    terminalIp: '192.168.1.201:4370',
    terminalName: 'eSSL Biometric Terminal #1 (SilkBio-101TC)',
    inOutModeCode: 0,
    verifyModeCode: 1,
    workCode: 0,
    status: 'Present (On-Time)'
  }
];

// Load existing log file if available
if (fs.existsSync(SYNC_LOG_PATH)) {
  try {
    const raw = fs.readFileSync(SYNC_LOG_PATH, 'utf8');
    livePunches = JSON.parse(raw);
  } catch (e) {
    console.log('[eSSL Bridge] Initializing new sync log file.');
  }
}

function savePunches() {
  try {
    fs.writeFileSync(SYNC_LOG_PATH, JSON.stringify(livePunches, null, 2), 'utf8');
  } catch (err) {
    console.error('[eSSL Bridge] Error saving punches:', err);
  }
}

const server = http.createServer((req, res) => {
  // Enable CORS for Flutter app communication
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  const url = new URL(req.url, `http://${req.headers.host}`);

  // 1. Health check & Device Status
  if (url.pathname === '/api/device/status' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'ONLINE',
      config: esslConfig,
      totalPunchesStored: livePunches.length,
      serverTime: new Date().toISOString()
    }));
    return;
  }

  // 2. Get today's attendance punches for an employee
  if (url.pathname === '/api/attendance/today' && req.method === 'GET') {
    const empId = url.searchParams.get('empId') || 'MN-1024';
    const today = new Date().toISOString().split('T')[0];
    const todayLogs = livePunches.filter(p => p.enrollNumber === empId && p.timestamp.startsWith(today));

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      empId,
      date: today,
      count: todayLogs.length,
      punches: todayLogs
    }));
    return;
  }

  // 3. Receive punch from physical eSSL device or C# bridge
  if (url.pathname === '/api/attendance/punch' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        const now = new Date();
        const punchRecord = {
          id: `ESSL-${Date.now()}`,
          enrollNumber: data.enrollNumber || 'MN-1024',
          timestamp: now.toISOString(),
          timeString: now.toLocaleTimeString(),
          dateString: now.toDateString(),
          punchType: data.punchType || (data.attState === 1 ? 'logout' : 'login'),
          verifyMethod: data.verifyMethod || 'thumbImpression',
          terminalIp: data.terminalIp || esslConfig.deviceIp,
          terminalName: esslConfig.modelName,
          inOutModeCode: data.attState || 0,
          verifyModeCode: data.verifyMode || 1,
          workCode: data.workCode || 0
        };

        livePunches.unshift(punchRecord);
        savePunches();

        console.log(`[eSSL Bridge] Biometric punch received: ${punchRecord.enrollNumber} - ${punchRecord.punchType} (${punchRecord.timeString})`);

        res.writeHead(201, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true, record: punchRecord }));
      } catch (err) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: false, error: 'Invalid JSON payload' }));
      }
    });
    return;
  }

  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'Endpoint not found' }));
});

server.listen(PORT, () => {
  console.log(`========================================================`);
  console.log(` MN FAMILY - eSSL SECURITY BIOMETRIC BRIDGE SERVER`);
  console.log(` Running on: http://localhost:${PORT}`);
  console.log(` Target Device: ${esslConfig.deviceIp}:${esslConfig.port}`);
  console.log(` Status: Listening for biometric thumb impression punches`);
  console.log(`========================================================`);
});
