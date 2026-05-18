/* EEELunarRover Operator Console
 *
 * Talks to the rover's HTTP API defined in CONTROLLER_PLAN.md.
 *
 * Control priority:
 *   1. Xbox / standard gamepad left stick (primary)
 *   2. On-screen mini D-pad and WASD/arrow keys (fallback, always live)
 *
 * Default API base is the same origin. Override with ?api=http://192.168.0.8
 * when connecting to a real rover hosted from a different origin.
 */

const CONFIG = {
  apiBase: new URLSearchParams(location.search).get('api') || '',
  pollIntervalMs: 200,      // /status poll rate
  driveHeartbeatMs: 150,    // re-send /drive while a command is held
  staleAfterMs: 500,
  deadAfterMs: 2000,
  maxPwm: 255,
  stickDeadzone: 0.13,      // ignore small stick drift
};

const state = {
  pressed: new Set(),       // held keyboard/button directions
  drive: { l: 0, r: 0 },
  speedPct: 50,
  lastStatusAt: 0,
  lastStatus: null,
  lastSendAt: 0,
  savedReadings: loadReadings(),
};

const gamepad = { index: null, id: '', prevButtons: [] };

let scanning = false;

/* ---------- helpers ---------- */

const $ = (id) => document.getElementById(id);
function setText(id, t) { const el = $(id); if (el) el.textContent = t; }

async function api(path) {
  try {
    const res = await fetch(CONFIG.apiBase + path);
    if (!res.ok) return { error: 'HTTP ' + res.status };
    return await res.json();
  } catch (e) {
    return { error: e.message };
  }
}

function clampPair(l, r, max) {
  return {
    l: Math.max(-max, Math.min(max, Math.round(l))),
    r: Math.max(-max, Math.min(max, Math.round(r))),
  };
}

function speedMax() {
  return Math.round(CONFIG.maxPwm * state.speedPct / 100);
}

/* ---------- gamepad ---------- */

window.addEventListener('gamepadconnected', (e) => {
  gamepad.index = e.gamepad.index;
  gamepad.id = e.gamepad.id;
  renderGamepad();
});

window.addEventListener('gamepaddisconnected', (e) => {
  if (gamepad.index === e.gamepad.index) {
    gamepad.index = null;
    gamepad.id = '';
    gamepad.prevButtons = [];
    renderGamepad();
  }
});

function activeGamepad() {
  if (gamepad.index === null) return null;
  return navigator.getGamepads()[gamepad.index] || null;
}

function buttonPressed(gp, i) {
  return !!(gp && gp.buttons[i] && gp.buttons[i].pressed);
}

// Edge-detect the A (scan) and B (stop) buttons.
function pollGamepadButtons(gp) {
  const A = 0, B = 1;
  const cur = gp.buttons.map((b) => b.pressed);
  if (cur[B] && !gamepad.prevButtons[B]) sendStop();
  if (cur[A] && !gamepad.prevButtons[A]) triggerScan();
  gamepad.prevButtons = cur;
}

// Drive command from the gamepad, or null if no gamepad / neutral.
function driveFromGamepad() {
  const gp = activeGamepad();
  if (!gp) return null;

  const dz = (v) => (Math.abs(v) < CONFIG.stickDeadzone ? 0 : v);
  const x = dz(gp.axes[0] || 0);      // left stick X (right positive)
  const y = dz(gp.axes[1] || 0);      // left stick Y (up negative)

  // The controller's own d-pad (buttons 12-15) also drives.
  let dx = 0, dy = 0;
  if (buttonPressed(gp, 12)) dy -= 1;
  if (buttonPressed(gp, 13)) dy += 1;
  if (buttonPressed(gp, 14)) dx -= 1;
  if (buttonPressed(gp, 15)) dx += 1;

  const forward = (-y) + (-dy);
  const turn    = x + dx;
  if (forward === 0 && turn === 0) return { l: 0, r: 0, active: false };

  const max = speedMax();
  const c = clampPair((forward + turn) * max, (forward - turn) * max, max);
  return { l: c.l, r: c.r, active: true };
}

/* ---------- drive from keyboard / on-screen buttons ---------- */

function driveFromKeys() {
  const max = speedMax();
  let l = 0, r = 0;
  if (state.pressed.has('fwd'))   { l += max; r += max; }
  if (state.pressed.has('rev'))   { l -= max; r -= max; }
  if (state.pressed.has('left'))  { l -= max / 2; r += max / 2; }
  if (state.pressed.has('right')) { l += max / 2; r -= max / 2; }
  return clampPair(l, r, max);
}

// Gamepad stick wins when it is being moved; otherwise keys/buttons.
function resolveDrive() {
  const gpd = driveFromGamepad();
  if (gpd && gpd.active) return { l: gpd.l, r: gpd.r };
  return driveFromKeys();
}

/* ---------- control loop ---------- */

function controlLoop() {
  const gp = activeGamepad();
  if (gp) pollGamepadButtons(gp);

  const cmd = resolveDrive();
  const now = performance.now();
  const changed = cmd.l !== state.drive.l || cmd.r !== state.drive.r;
  const moving = cmd.l !== 0 || cmd.r !== 0;

  // Send immediately on change, then heartbeat while moving so the
  // firmware's 500 ms watchdog stays satisfied.
  if (changed || (moving && now - state.lastSendAt > CONFIG.driveHeartbeatMs)) {
    state.drive = cmd;
    state.lastSendAt = now;
    api(`/drive?l=${cmd.l}&r=${cmd.r}`);
  }
  renderDrive(cmd);
  requestAnimationFrame(controlLoop);
}

function sendStop() {
  state.pressed.clear();
  state.drive = { l: 0, r: 0 };
  state.lastSendAt = performance.now();
  renderButtons();
  api('/stop');
}

/* ---------- key / button input ---------- */

const KEY_TO_DIR = {
  w: 'fwd', arrowup: 'fwd',
  s: 'rev', arrowdown: 'rev',
  a: 'left', arrowleft: 'left',
  d: 'right', arrowright: 'right',
};

document.addEventListener('keydown', (e) => {
  const k = e.key.toLowerCase();
  const dir = KEY_TO_DIR[k];
  if (dir) {
    if (!e.repeat) { state.pressed.add(dir); renderButtons(); }
    e.preventDefault();
    return;
  }
  if (k === ' ' || k === 'x' || k === 'escape') {
    e.preventDefault();
    sendStop();
  }
});

document.addEventListener('keyup', (e) => {
  const dir = KEY_TO_DIR[e.key.toLowerCase()];
  if (dir) {
    state.pressed.delete(dir);
    renderButtons();
    e.preventDefault();
  }
});

function bindButton(id, dir) {
  const el = $(id);
  const down = (e) => { e.preventDefault(); el.setPointerCapture(e.pointerId); state.pressed.add(dir); renderButtons(); };
  const up   = (e) => { e.preventDefault(); state.pressed.delete(dir); renderButtons(); };
  el.addEventListener('pointerdown', down);
  el.addEventListener('pointerup', up);
  el.addEventListener('pointercancel', up);
  el.addEventListener('lostpointercapture', up);
}

bindButton('btn-fwd', 'fwd');
bindButton('btn-rev', 'rev');
bindButton('btn-left', 'left');
bindButton('btn-right', 'right');
$('btn-stop').addEventListener('click', sendStop);

const speedSlider = $('speed');
speedSlider.addEventListener('input', () => {
  state.speedPct = Number(speedSlider.value);
  setText('speed-val', state.speedPct + '%');
});

/* ---------- status polling ---------- */

async function pollStatus() {
  const status = await api('/status');
  if (!status.error) {
    state.lastStatus = status;
    state.lastStatusAt = performance.now();
    renderStatus(status);
  }
  renderConnection();
}
setInterval(pollStatus, CONFIG.pollIntervalMs);
setInterval(renderConnection, 200);

/* ---------- classification ---------- */

function classify(irRate, ultrasound, magnet) {
  if (irRate == null || ultrasound == null || magnet == null) return null;
  const fast = irRate >= 430;          // midpoint of the 312 / 547 Poisson rates
  const u = !!ultrasound;
  const m = String(magnet).toLowerCase();
  if (fast  && u  && m === 'down') return 'Basaltoid';
  if (!fast && !u && m === 'down') return 'Gravion';
  if (!fast && u  && m === 'up')   return 'Regolix';
  if (fast  && !u && m === 'up')   return 'Lunarite';
  return 'Unknown';
}

function classifyReason(irRate, ultrasound, magnet) {
  const fast = irRate >= 430;
  return `IR ${fast ? 'high' : 'low'}  ·  ultrasound ${ultrasound ? 'present' : 'absent'}  ·  magnet ${magnet}`;
}

function ageString(s) {
  if (!s || typeof s !== 'string' || s.length < 4 || s[0] !== '#') return null;
  const digits = s.slice(1);
  const billion = parseFloat(`${digits[0]}.${digits.slice(1)}`);
  if (isNaN(billion)) return s;
  return `${billion.toFixed(2)} billion years`;
}

/* ---------- rendering ---------- */

function renderDrive(cmd) {
  const f = (n) => (n >= 0 ? ' ' : '') + n;
  setText('drive-readout', `L ${f(cmd.l)}   R ${f(cmd.r)}`);
}

function renderButtons() {
  for (const dir of ['fwd', 'rev', 'left', 'right']) {
    $('btn-' + dir).classList.toggle('active', state.pressed.has(dir));
  }
}

function renderGamepad() {
  const connected = gamepad.index !== null;
  $('gamepad-dot').className = 'dot ' + (connected ? 'ok' : 'bad');
  setText('gamepad-value', connected ? 'ready' : 'none');

  const status = $('gamepad-status');
  status.classList.toggle('connected', connected);
  setText('gp-text', connected ? 'Gamepad connected' : 'No gamepad detected - using keyboard / on-screen');
  setText('gp-id', connected ? shortGamepadId(gamepad.id) : '');
}

function shortGamepadId(id) {
  // Trim the verbose vendor/product suffix browsers append.
  return id.replace(/\s*\(.*$/, '').trim() || id;
}

function tile(idBase, valid, displayValue, stale) {
  const el = $('tile-' + idBase);
  el.classList.toggle('is-valid', valid && !stale);
  el.classList.toggle('is-stale', valid && stale);
  el.classList.toggle('is-none', !valid);
  setText('sens-' + idBase, valid ? displayValue : '-');
}

function renderStatus(s) {
  const sens = s.sensors || {};
  setText('state-value', s.state || 'unknown');

  tile('age', !!sens.age_valid, sens.age || '-');
  tile('ir',  !!sens.ir_valid,  sens.ir_valid ? sens.ir_rate_hz + ' Hz' : '-');
  tile('us',  !!sens.ultrasound_valid,
       sens.ultrasound_present ? 'present' : 'absent');
  tile('mag', !!sens.magnet_valid, sens.magnet || '-');

  const ready = sens.ir_valid && sens.ultrasound_valid && sens.magnet_valid;
  if (ready) {
    renderClassification(sens);
  }
}

function renderClassification(sens, flash) {
  const type = classify(sens.ir_rate_hz, sens.ultrasound_present, sens.magnet);
  const hero = $('hero');

  hero.className = 'card hero';
  if (type && type !== 'Unknown') hero.classList.add('t-' + type.toLowerCase());
  if (flash) {
    hero.classList.add('flash');
    setTimeout(() => hero.classList.remove('flash'), 600);
  }

  setText('cls-type', type || 'unknown');
  const age = ageString(sens.age);
  setText('cls-age', age || 'age signal not locked');
  setText('cls-reason',
    classifyReason(sens.ir_rate_hz, sens.ultrasound_present, sens.magnet));
}

function renderConnection() {
  const dot = $('conn-dot');
  const val = $('conn-value');
  if (state.lastStatusAt === 0) {
    dot.className = 'dot bad';
    val.textContent = 'offline';
    return;
  }
  const ageMs = performance.now() - state.lastStatusAt;
  if (ageMs > CONFIG.deadAfterMs)       { dot.className = 'dot bad';  val.textContent = 'lost'; }
  else if (ageMs > CONFIG.staleAfterMs) { dot.className = 'dot warn'; val.textContent = 'stale'; }
  else                                  { dot.className = 'dot ok';   val.textContent = 'live'; }
}

/* ---------- scan ---------- */

async function triggerScan() {
  if (scanning) return;
  scanning = true;
  const btn = $('btn-scan');
  btn.disabled = true;
  btn.classList.add('busy');
  btn.textContent = 'Scanning';

  const result = await api('/scan');

  scanning = false;
  btn.disabled = false;
  btn.classList.remove('busy');
  btn.textContent = 'Scan rock';
  if (result.error) return;

  const sens = {
    age: result.age, age_valid: !!result.age,
    ir_rate_hz: result.ir_rate_hz, ir_valid: true,
    ultrasound_present: result.ultrasound_present, ultrasound_valid: true,
    magnet: result.magnet, magnet_valid: true,
  };
  tile('age', sens.age_valid, sens.age || '-');
  tile('ir',  true, sens.ir_rate_hz + ' Hz');
  tile('us',  true, sens.ultrasound_present ? 'present' : 'absent');
  tile('mag', true, sens.magnet || '-');
  renderClassification(sens, true);
}

$('btn-scan').addEventListener('click', triggerScan);

/* ---------- saved readings ---------- */

$('btn-save').addEventListener('click', () => {
  const sens = (state.lastStatus && state.lastStatus.sensors) || {};
  state.savedReadings.unshift({
    t: new Date().toISOString(),
    age: sens.age || null,
    ir: sens.ir_rate_hz ?? null,
    ultrasound: sens.ultrasound_present ?? null,
    magnet: sens.magnet || null,
    type: classify(sens.ir_rate_hz, sens.ultrasound_present, sens.magnet),
  });
  saveReadings(state.savedReadings);
  renderSaved();
});

$('btn-clear').addEventListener('click', () => {
  state.savedReadings = [];
  saveReadings(state.savedReadings);
  renderSaved();
});

function loadReadings() {
  try { return JSON.parse(localStorage.getItem('readings') || '[]'); }
  catch { return []; }
}
function saveReadings(arr) {
  try { localStorage.setItem('readings', JSON.stringify(arr.slice(0, 50))); }
  catch { /* storage full or disabled - ignore */ }
}

function renderSaved() {
  const ul = $('saved-list');
  ul.innerHTML = '';
  if (state.savedReadings.length === 0) {
    const li = document.createElement('li');
    li.className = 'empty';
    li.textContent = 'no readings saved yet';
    ul.appendChild(li);
    return;
  }
  state.savedReadings.slice(0, 12).forEach((r) => {
    const li = document.createElement('li');
    const time = r.t ? r.t.slice(11, 19) : '?';
    const us = r.ultrasound === true ? 'Y' : (r.ultrasound === false ? 'N' : '?');
    li.textContent =
      `${time}   ${(r.type || '?').padEnd(10)} age ${r.age || '?'}   IR ${r.ir ?? '?'}Hz   US ${us}   M ${r.magnet || '?'}`;
    ul.appendChild(li);
  });
}

/* ---------- safety: stop drive when the tab loses focus ---------- */

window.addEventListener('blur', () => { if (state.drive.l || state.drive.r) sendStop(); });
document.addEventListener('visibilitychange', () => {
  if (document.hidden && (state.drive.l || state.drive.r)) sendStop();
});

/* ---------- init ---------- */

renderGamepad();
renderButtons();
renderSaved();
renderDrive(state.drive);
pollStatus();
requestAnimationFrame(controlLoop);
