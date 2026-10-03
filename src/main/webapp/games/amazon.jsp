<%@ page contentType="text/html;charset=UTF-8" %>
<%@ include file="/WEB-INF/auth.jspf" %>
<!DOCTYPE html>
<html><head><title>Amazon Rainforest Survival</title><%@ include file="/WEB-INF/head.jspf" %></head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="amazon-container" style="max-width:960px">
 <div class="amazon-card center gamebox" id="gamebox" data-touch="lr" style="padding:1.2rem"><button class="btn-amazon-secondary fs-btn" onclick="Arcade.toggleFull()">Fullscreen</button>
  <div class="hud">
    <span class="pill">Level <b id="lv">-</b></span>
    <span class="pill">Prey <b id="prog">0/0</b></span>
    <span class="pill">Score <b id="score">0</b></span>
    <span class="pill">Energy <span class="bar"><div id="ebar" style="width:100%;background:#43a047"></div></span></span>
    <span class="pill hide-m"><small class="muted" id="formula"></small></span>
  </div>
  <div class="quest" id="quest">Choose a level</div>
  <div id="msg"></div>
  <div class="wrap">
    <canvas id="c" width="900" height="560"></canvas>
    <div class="ov" id="menu" style="display:flex"></div>
    <div class="ov" id="chal">
      <h2 id="chalWho" style="color:#fb7185"></h2>
      <h1 id="chalQ" style="color:#fcd34d;margin:10px"></h1>
      <div id="chalOpts"></div>
      <div class="bar" style="width:260px;margin-top:12px"><div id="cbar" style="width:100%;background:#ef5350"></div></div>
      <p class="muted"><span class="kb">Press 1, 2 or 3</span><span class="tc">Tap an answer</span></p>
    </div>
    <div class="ov" id="end"></div>
  </div>
  <p class="muted" style="margin-top:8px"><span class="kb"><b>&larr; &rarr;</b> or <b>A / D</b> to steer.</span><span class="tc">Hold the &#9664; &#9654; buttons (or the left / right side of the board) to steer.</span> Energy drains: E(t) = 100 &minus; &lambda;t. Eat the prey carrying the correct answer; wrong prey is toxic.</p>
  <p id="invline" class="muted"><small>Loading your store items...</small></p>
 </div>
</div>
<script>
var cv = document.getElementById("c"), ctx = cv.getContext("2d"), W = cv.width, H = cv.height;
var RV = { y1: 175, y2: 265 }, GAP = 6, SPEED = 2.6, TURN = 0.058;
var inv = {}, keys = { l: false, r: false }, state = "menu", clk = 0, frame = 0;
var head, heading, trail, segs, score, energy, t, quest, preys, preds, floaters, cd, chal, curLevel = 1, L, eaten = 0;

/* Levels: target = prey to eat; spd = predator speed; jag/caim = number of predators;
   ctime = seconds to answer a danger question; decay = energy drain multiplier */
var LV = [
  { name: "Tropical Shallows", desc: "Eat 5 prey",  target: 5,  spd: 0.80, jag: 1, caim: 1, ctime: 7, decay: 1.0 },
  { name: "Deep Canopy",       desc: "Eat 7 prey",  target: 7,  spd: 0.90, jag: 1, caim: 1, ctime: 7, decay: 1.1 },
  { name: "Flood Season",      desc: "Eat 9 prey &middot; 2 jaguars", target: 9, spd: 1.00, jag: 2, caim: 1, ctime: 6, decay: 1.2 },
  { name: "Night Hunt",        desc: "Eat 11 prey &middot; 2 caimans", target: 11, spd: 1.10, jag: 2, caim: 2, ctime: 6, decay: 1.3 },
  { name: "Apex Storm",        desc: "Eat 13 prey &middot; 3 jaguars", target: 13, spd: 1.25, jag: 3, caim: 2, ctime: 5, decay: 1.4 }
];

function $(id) { return document.getElementById(id); }
function rnd(a, b) { return Math.floor(Math.random() * (b - a + 1)) + a; }
function rf(a, b) { return a + Math.random() * (b - a); }
function dist(a, b) { return Math.hypot(a.x - b.x, a.y - b.y); }
function clamp(v, a, b) { return Math.max(a, Math.min(b, v)); }
function angDiff(a, b) { var d = a - b; while (d > Math.PI) d -= 6.2832; while (d < -Math.PI) d += 6.2832; return d; }
function ell(x, y, rx, ry, f) { ctx.beginPath(); ctx.ellipse(x, y, rx, ry, 0, 0, 6.2832); ctx.fillStyle = f; ctx.fill(); }
function circ(x, y, r, f) { ctx.beginPath(); ctx.arc(x, y, r, 0, 6.2832); ctx.fillStyle = f; ctx.fill(); }
function level() { return curLevel; }
function lambda() { return (inv.elixir ? 0.75 : 1.5) * L.decay; }   // energy decay rate per second
function mathQ(lv) { return Arcade.mathTier(Math.min(3, Math.ceil(lv / 2))); }
function qText(m) { return Arcade.qText(m); }
function options(a, n) { return Arcade.options(a, n); }

/* ================= SCENERY (pre-rendered) ================= */
var bg = document.createElement("canvas"), fg = document.createElement("canvas");
var pads = [];
function buildScenery() {
  bg.width = fg.width = W; bg.height = fg.height = H;
  var b = bg.getContext("2d"), f = fg.getContext("2d"), i, k;
  var g = b.createLinearGradient(0, 0, 0, H);
  g.addColorStop(0, "#0a2a18"); g.addColorStop(0.5, "#14401f"); g.addColorStop(1, "#0b2a16");
  b.fillStyle = g; b.fillRect(0, 0, W, H);
  for (i = 0; i < 260; i++) {
    b.save(); b.translate(rf(0, W), rf(0, H)); b.rotate(rf(0, 6.28));
    b.fillStyle = "rgba(" + rnd(20, 60) + "," + rnd(90, 150) + "," + rnd(30, 60) + "," + rf(0.12, 0.35) + ")";
    b.beginPath(); b.ellipse(0, 0, rf(8, 26), rf(3, 9), 0, 0, 6.2832); b.fill(); b.restore();
  }
  b.strokeStyle = "rgba(40,120,50,.45)"; b.lineWidth = 2;
  for (i = 0; i < 40; i++) {
    var fx = rf(0, W), fy = rf(0, H);
    for (k = 0; k < 7; k++) {
      var a = -1.2 + k * 0.4;
      b.beginPath(); b.moveTo(fx, fy);
      b.quadraticCurveTo(fx + Math.cos(a) * 18, fy + Math.sin(a) * 18 - 6, fx + Math.cos(a) * 34, fy + Math.sin(a) * 34);
      b.stroke();
    }
  }
  for (i = 0; i < 5; i++) {
    var lx = rf(0, W), lg = b.createLinearGradient(lx, 0, lx + 120, H);
    lg.addColorStop(0, "rgba(255,245,170,.10)"); lg.addColorStop(1, "rgba(255,245,170,0)");
    b.fillStyle = lg; b.beginPath(); b.moveTo(lx, 0); b.lineTo(lx + 50, 0); b.lineTo(lx + 190, H); b.lineTo(lx + 90, H); b.fill();
  }
  for (i = 0; i < 46; i++) {
    var e = rnd(0, 3), ex, ey;
    if (e === 0) { ex = rf(0, W); ey = rf(-10, 30); } else if (e === 1) { ex = rf(0, W); ey = rf(H - 30, H + 10); }
    else if (e === 2) { ex = rf(-10, 30); ey = rf(0, H); } else { ex = rf(W - 30, W + 10); ey = rf(0, H); }
    f.save(); f.translate(ex, ey); f.rotate(rf(0, 6.28));
    var rg = f.createRadialGradient(0, 0, 2, 0, 0, 70);
    rg.addColorStop(0, "rgba(6,40,16,.95)"); rg.addColorStop(1, "rgba(6,40,16,0)");
    f.fillStyle = rg; f.beginPath(); f.ellipse(0, 0, 70, 32, 0, 0, 6.2832); f.fill(); f.restore();
  }
  f.strokeStyle = "rgba(20,70,25,.85)"; f.lineWidth = 3;
  for (i = 0; i < 8; i++) {
    var vx = rf(0, W); f.beginPath(); f.moveTo(vx, 0);
    f.bezierCurveTo(vx + rf(-30, 30), 40, vx + rf(-30, 30), 70, vx + rf(-20, 20), rf(80, 130)); f.stroke();
  }
  for (i = 0; i < 7; i++) pads.push({ x: rf(40, W - 40), y: rf(RV.y1 + 18, RV.y2 - 18), r: rf(7, 12), p: rf(0, 6) });
}

function drawRiver() {
  var g = ctx.createLinearGradient(0, RV.y1, 0, RV.y2), x, i;
  g.addColorStop(0, "#0b3b44"); g.addColorStop(0.5, "#1a7480"); g.addColorStop(1, "#0b3b44");
  ctx.beginPath(); ctx.moveTo(0, RV.y1);
  for (x = 0; x <= W; x += 20) ctx.lineTo(x, RV.y1 + Math.sin(x * 0.03) * 5);
  for (x = W; x >= 0; x -= 20) ctx.lineTo(x, RV.y2 + Math.sin(x * 0.025 + 1) * 5);
  ctx.closePath(); ctx.fillStyle = g; ctx.fill();
  ctx.strokeStyle = "#3e2f1c"; ctx.lineWidth = 4; ctx.stroke();
  ctx.strokeStyle = "rgba(255,255,255,.18)"; ctx.lineWidth = 1.5;
  for (i = 0; i < 7; i++) {
    ctx.beginPath();
    for (x = 0; x <= W; x += 10) { var yy = RV.y1 + 12 + i * 12 + Math.sin(x * 0.04 + clk * 2 + i) * 3; if (x === 0) ctx.moveTo(x, yy); else ctx.lineTo(x, yy); }
    ctx.stroke();
  }
  pads.forEach(function (p) {
    var by = p.y + Math.sin(clk * 1.5 + p.p) * 1.5;
    ell(p.x, by, p.r, p.r * 0.7, "#2e8b3d"); ell(p.x - 2, by - 1, p.r * 0.5, p.r * 0.3, "#47b559");
  });
}

/* ================= ANIMALS ================= */
function drawJaguar(p) {
  ctx.save(); ctx.translate(p.x, p.y); ctx.rotate(p.h);
  var s = Math.sin(p.ph) * 5;
  ell(2, 9, 32, 9, "rgba(0,0,0,.28)");
  ctx.strokeStyle = "#c98320"; ctx.lineWidth = 6; ctx.lineCap = "round";
  ctx.beginPath(); ctx.moveTo(-26, 0); ctx.bezierCurveTo(-40, 6 + s, -48, -6 - s, -56, 2 + s); ctx.stroke();
  ctx.strokeStyle = "#2a1505"; ctx.lineWidth = 6; ctx.beginPath(); ctx.moveTo(-52, 0 + s * 0.5); ctx.lineTo(-57, 2 + s); ctx.stroke();
  ell(-16, -10 + s, 6, 4, "#b8741a"); ell(-16, 10 - s, 6, 4, "#b8741a");
  ell(14, -10 - s, 6, 4, "#b8741a"); ell(14, 10 + s, 6, 4, "#b8741a");
  var bg2 = ctx.createLinearGradient(0, -14, 0, 14);
  bg2.addColorStop(0, "#e6a02e"); bg2.addColorStop(0.6, "#cf8421"); bg2.addColorStop(1, "#ecc98a");
  ell(0, 0, 29, 13, bg2);
  var ros = [[-20, -5], [-11, 5], [-3, -6], [6, 4], [14, -4], [-22, 5], [1, 0], [-12, -2]];
  ctx.strokeStyle = "#3a1c06"; ctx.lineWidth = 2;
  ros.forEach(function (r) { ctx.beginPath(); ctx.arc(r[0], r[1], 3.2, 0, 6.2832); ctx.stroke(); circ(r[0], r[1], 1, "#3a1c06"); });
  var hg = ctx.createRadialGradient(31, -2, 2, 31, 0, 12);
  hg.addColorStop(0, "#f0b13d"); hg.addColorStop(1, "#c27a1c");
  ell(31, 0, 11, 9.5, hg);
  circ(27, -8, 3.5, "#c27a1c"); circ(27, 8, 3.5, "#c27a1c"); circ(27, -8, 1.6, "#2a1505"); circ(27, 8, 1.6, "#2a1505");
  ell(38, 0, 5.5, 4.5, "#f3dcae"); circ(42, 0, 1.8, "#2a1505");
  circ(33, -4.5, 2.2, "#9be15d"); circ(33, 4.5, 2.2, "#9be15d");
  ctx.fillStyle = "#000"; ctx.fillRect(33.3, -6, 1, 3.4); ctx.fillRect(33.3, 2.8, 1, 3.4);
  ctx.strokeStyle = "rgba(255,255,255,.6)"; ctx.lineWidth = 0.7;
  ctx.beginPath(); ctx.moveTo(40, -2); ctx.lineTo(47, -5); ctx.moveTo(40, 2); ctx.lineTo(47, 5); ctx.stroke();
  ctx.restore();
}

function drawCaiman(p) {
  ctx.save(); ctx.translate(p.x, p.y);
  ctx.strokeStyle = "rgba(255,255,255,.25)"; ctx.lineWidth = 1.5;
  ctx.beginPath(); ctx.ellipse(0, 0, 48 + Math.sin(clk * 3) * 3, 18, 0, 0, 6.2832); ctx.stroke();
  ctx.rotate(p.h);
  var s = Math.sin(p.ph) * 4;
  ctx.fillStyle = "#1c2a1a";
  ctx.beginPath(); ctx.moveTo(-20, -9); ctx.quadraticCurveTo(-45, s, -72, 0 + s * 1.5); ctx.quadraticCurveTo(-45, s + 2, -20, 9); ctx.fill();
  ell(-12, -12, 7, 3.5, "#142014"); ell(-12, 12, 7, 3.5, "#142014");
  ell(10, -12, 7, 3.5, "#142014"); ell(10, 12, 7, 3.5, "#142014");
  var bgc = ctx.createLinearGradient(0, -13, 0, 13);
  bgc.addColorStop(0, "#2f4a2a"); bgc.addColorStop(0.5, "#1f331e"); bgc.addColorStop(1, "#111c11");
  ell(0, 0, 32, 13, bgc);
  ctx.fillStyle = "#0e170e";
  for (var i = -24; i <= 22; i += 7) { ctx.beginPath(); ctx.moveTo(i, -4); ctx.lineTo(i + 3.5, -9); ctx.lineTo(i + 7, -4); ctx.fill(); }
  ctx.fillStyle = "#223a20";
  ctx.beginPath(); ctx.moveTo(24, -9); ctx.quadraticCurveTo(46, -7, 58, -3); ctx.lineTo(58, 3); ctx.quadraticCurveTo(46, 7, 24, 9); ctx.fill();
  ctx.fillStyle = "#f3f0e2";
  for (i = 30; i < 56; i += 5) { ctx.beginPath(); ctx.moveTo(i, -3); ctx.lineTo(i + 2, -0.5); ctx.lineTo(i + 3.5, -3); ctx.fill(); ctx.beginPath(); ctx.moveTo(i, 3); ctx.lineTo(i + 2, 0.5); ctx.lineTo(i + 3.5, 3); ctx.fill(); }
  circ(26, -7, 3.2, "#2f4a2a"); circ(26, 7, 3.2, "#2f4a2a"); circ(26, -7, 1.9, "#f2c230"); circ(26, 7, 1.9, "#f2c230");
  ctx.fillStyle = "#000"; ctx.fillRect(25.6, -8.5, 0.9, 3); ctx.fillRect(25.6, 5.5, 0.9, 3);
  circ(56, -1.5, 1, "#000"); circ(56, 1.5, 1, "#000");
  ctx.restore();
}

function drawCapy(p) {
  ctx.save(); ctx.translate(p.x, p.y); ctx.rotate(p.h);
  var s = Math.sin(p.ph) * 2;
  ell(1, 8, 20, 6, "rgba(0,0,0,.25)");
  ell(-8, -9 + s, 4, 3, "#5c3412"); ell(-8, 9 - s, 4, 3, "#5c3412"); ell(9, -9 - s, 4, 3, "#5c3412"); ell(9, 9 + s, 4, 3, "#5c3412");
  var g = ctx.createLinearGradient(0, -12, 0, 12);
  g.addColorStop(0, "#9a6a3a"); g.addColorStop(1, "#6e4622");
  ell(0, 0, 19, 11.5, g);
  ctx.strokeStyle = "rgba(60,30,10,.5)"; ctx.lineWidth = 1;
  for (var i = -14; i < 14; i += 4) { ctx.beginPath(); ctx.moveTo(i, -8); ctx.lineTo(i + 3, -3); ctx.moveTo(i, 4); ctx.lineTo(i + 3, 9); ctx.stroke(); }
  ell(19, -1, 9.5, 8, "#85572b");
  ell(25, 1, 5.5, 6, "#6b4423"); ell(27, -2, 2.2, 1.6, "#1c0f05");
  ell(15, -7, 2.4, 3, "#5c3412");
  circ(20, -5, 1.9, "#f8f0e0"); circ(20.4, -5, 1.1, "#000");
  ctx.restore();
}

function drawFrog(p) {
  var hop = Math.max(0, Math.sin(p.ph));
  ctx.save(); ctx.translate(p.x, p.y - hop * 6); ctx.rotate(p.h);
  ell(0, 6 + hop * 6, 10, 4, "rgba(0,0,0,.25)");
  ell(-7, -7, 6, 3, "#1565c0"); ell(-7, 7, 6, 3, "#1565c0");
  var g = ctx.createRadialGradient(-2, -2, 1, 0, 0, 12);
  g.addColorStop(0, "#42a5f5"); g.addColorStop(1, "#0d47a1");
  ell(0, 0, 11, 8, g);
  circ(-3, -2, 1.9, "#050a14"); circ(2, 3, 1.6, "#050a14"); circ(-6, 3, 1.4, "#050a14"); circ(4, -3, 1.3, "#050a14");
  ell(8, -4, 3.6, 3.6, "#1976d2"); ell(8, 4, 3.6, 3.6, "#1976d2");
  circ(8.5, -4, 2, "#f2c230"); circ(8.5, 4, 2, "#f2c230"); circ(9, -4, 1, "#000"); circ(9, 4, 1, "#000");
  ctx.restore();
}

function badge(x, y, txt, col, pulse) {
  ctx.font = "bold 13px Arial"; ctx.textAlign = "center"; ctx.textBaseline = "middle";
  if (pulse) { ctx.strokeStyle = "rgba(255,235,59," + (0.5 + 0.5 * Math.sin(clk * 6)) + ")"; ctx.lineWidth = 3; ctx.beginPath(); ctx.arc(x, y + 14, 26, 0, 6.2832); ctx.stroke(); }
  ctx.fillStyle = "rgba(4,16,10,.88)"; ctx.strokeStyle = col; ctx.lineWidth = 1.5;
  ctx.beginPath(); ctx.rect(x - 16, y - 9, 32, 18); ctx.fill(); ctx.stroke();
  ctx.fillStyle = "#fff"; ctx.fillText(txt, x, y + 1);
}

/* ================= SNAKE ================= */
function segPos(i) { return trail[Math.min(i * GAP, trail.length - 1)]; }
function drawSnake() {
  var gold = !!inv.golden_skin;
  var c1 = gold ? "#e3b32b" : "#4d8f34", c2 = gold ? "#a9751b" : "#2f6b24", dk = gold ? "#5a3b0a" : "#16301a";
  var i, p, r;
  for (i = segs - 1; i >= 1; i--) {
    p = segPos(i); r = Math.max(4.5, 9.5 - (i / segs) * 5);
    ell(p.x + 2, p.y + 3, r, r * 0.8, "rgba(0,0,0,.25)");
    ell(p.x, p.y, r, r, i % 2 ? c1 : c2);
    if (i % 3 === 0) ell(p.x, p.y, r * 0.55, r * 0.55, dk);
  }
  ctx.save(); ctx.translate(head.x, head.y); ctx.rotate(heading);
  ell(1, 3, 14, 10, "rgba(0,0,0,.25)");
  ell(0, 0, 13, 9.5, c1); ell(-3, 0, 7, 4, c2);
  circ(5, -5.5, 2.8, "#ffd54f"); circ(5, 5.5, 2.8, "#ffd54f");
  ctx.fillStyle = "#000"; ctx.fillRect(5, -7.3, 1.2, 3.6); ctx.fillRect(5, 3.7, 1.2, 3.6);
  circ(11, -2, 0.9, dk); circ(11, 2, 0.9, dk);
  if (Math.sin(clk * 9) > 0.55) {
    ctx.strokeStyle = "#e53935"; ctx.lineWidth = 1.5;
    ctx.beginPath(); ctx.moveTo(13, 0); ctx.lineTo(20, 0); ctx.lineTo(24, -3); ctx.moveTo(20, 0); ctx.lineTo(24, 3); ctx.stroke();
  }
  ctx.restore();
}

/* ================= GAME LOGIC ================= */
function newQuest() {
  quest = mathQ(curLevel);
  var vals = options(quest.a, 3);
  preys = vals.map(function (v) {
    var x, y, g = 0;
    do { x = rf(50, W - 50); y = rf(50, H - 50); g++; } while ((dist({ x: x, y: y }, head) < 140 || (y > RV.y1 - 15 && y < RV.y2 + 15 && Math.random() < 0.7)) && g < 50);
    return { x: x, y: y, h: rf(0, 6.28), val: v, ok: v === quest.a, type: Math.random() < 0.5 ? "frog" : "capy", ph: rf(0, 6) };
  });
  $("quest").textContent = qText(quest);
}

function spawnPred(type) {
  if (type === "caiman") return { type: type, x: rf(100, W - 100), y: (RV.y1 + RV.y2) / 2, h: 0, ph: 0, stun: 0, dirx: Math.random() < 0.5 ? 1 : -1 };
  return { type: type, x: rf(60, W - 60), y: rf(300, H - 40), h: 0, ph: 0, stun: 0, tx: 0, ty: 0 };
}

function showMenu() {
  state = "menu"; $("end").style.display = "none"; $("chal").style.display = "none";
  $("quest").textContent = "Choose a level";
  Arcade.levelMenu($("menu"), "amazon", "Amazon Rainforest Survival", LV, begin);
}

function begin(lv) {
  curLevel = lv; L = LV[lv - 1];
  head = { x: 120, y: 400 }; heading = 0; segs = 6; score = 0; energy = 100; t = 0; cd = 2; floaters = []; eaten = 0;
  trail = []; for (var k = 0; k <= segs * GAP + 2; k++) trail.push({ x: head.x - k * SPEED, y: head.y });
  preds = [];
  for (k = 0; k < L.jag; k++) preds.push(spawnPred("jaguar"));
  for (k = 0; k < L.caim; k++) preds.push(spawnPred("caiman"));
  state = "play";
  ["menu", "end", "chal"].forEach(function (id) { $(id).style.display = "none"; });
  setMsg("");
  newQuest(); hud();
}

function setMsg(m, c) { var e = $("msg"); e.textContent = m; e.style.color = c || "#ecfdf5"; }
function hud() {
  $("score").textContent = score; $("lv").textContent = curLevel; $("prog").textContent = eaten + "/" + L.target;
  var e = $("ebar"); e.style.width = Math.max(0, energy) + "%";
  e.style.background = energy > 50 ? "#43a047" : (energy > 25 ? "#fb8c00" : "#e53935");
  $("formula").textContent = "E(t) = 100 \u2212 " + lambda().toFixed(2) + "\u00B7t   (t = " + t.toFixed(0) + "s)";
}
function floatText(x, y, txt, col) { floaters.push({ x: x, y: y, txt: txt, col: col, life: 60 }); }

function updPrey(p) {
  p.ph += 0.12;
  var sp = p.type === "frog" ? Math.max(0, Math.sin(p.ph)) * 1.1 : 0.35;
  p.h += rf(-0.05, 0.05);
  if (dist(p, head) < 80) { p.h = Math.atan2(p.y - head.y, p.x - head.x); sp *= 1.5; }
  p.x += Math.cos(p.h) * sp; p.y += Math.sin(p.h) * sp;
  if (p.x < 40 || p.x > W - 40 || p.y < 40 || p.y > H - 40) p.h = Math.atan2(H / 2 - p.y, W / 2 - p.x);
}

function moveToward(p, tx, ty, sp, turnRate) {
  var a = Math.atan2(ty - p.y, tx - p.x);
  p.h += angDiff(a, p.h) * turnRate;
  p.x += Math.cos(p.h) * sp; p.y += Math.sin(p.h) * sp;
}

function updJaguar(p) {
  p.ph += 0.2;
  var hidden = inv.cloak && t < 30;
  var sp;
  if (p.stun > 0) { p.stun -= 1 / 60; sp = 1.1; }
  else if (!hidden && dist(p, head) < 260) { p.tx = head.x; p.ty = head.y; sp = 2.0 * L.spd; }
  else {
    if (!p.tx || Math.hypot(p.tx - p.x, p.ty - p.y) < 20) { p.tx = rf(40, W - 40); p.ty = Math.random() < 0.5 ? rf(40, RV.y1 - 25) : rf(RV.y2 + 25, H - 40); }
    sp = 0.9 * L.spd;
  }
  moveToward(p, p.tx, p.ty, sp, 0.08);
  if (p.y > RV.y1 - 12 && p.y < RV.y2 + 12) p.y = p.y < (RV.y1 + RV.y2) / 2 ? RV.y1 - 12 : RV.y2 + 12;
  p.x = clamp(p.x, 30, W - 30); p.y = clamp(p.y, 30, H - 30);
}

function updCaiman(p) {
  p.ph += 0.1;
  var inRiver = head.y > RV.y1 - 25 && head.y < RV.y2 + 25;
  var tx, ty, sp;
  if (p.stun > 0) { p.stun -= 1 / 60; }
  if (p.stun <= 0 && inRiver && Math.abs(head.x - p.x) < 320) { tx = head.x; ty = clamp(head.y, RV.y1 + 20, RV.y2 - 20); sp = 1.9 * L.spd; }
  else {
    tx = p.dirx > 0 ? W - 60 : 60; ty = (RV.y1 + RV.y2) / 2 + Math.sin(p.ph) * 25; sp = 0.9 * L.spd;
    if (Math.abs(p.x - tx) < 12) p.dirx *= -1;
  }
  moveToward(p, tx, ty, sp, 0.1);
  p.y = clamp(p.y, RV.y1 + 15, RV.y2 - 15); p.x = clamp(p.x, 40, W - 40);
}

function startChallenge(p) {
  state = "challenge";
  chal = { p: p, m: mathQ(curLevel), time: L.ctime, max: L.ctime };
  chal.opts = options(chal.m.a, 3);
  $("chalWho").textContent = p.type === "jaguar" ? "A JAGUAR IS POUNCING!" : "THE BLACK CAIMAN STRIKES!";
  $("chalQ").textContent = qText(chal.m);
  var box = $("chalOpts"); box.innerHTML = "";
  chal.opts.forEach(function (v, i) {
    var b = document.createElement("button");
    b.className = "opt"; b.textContent = (i + 1) + ":  " + v;
    b.onclick = function () { answer(i); };
    box.appendChild(b);
  });
  $("chal").style.display = "flex";
}

function answer(i) {
  if (state !== "challenge") return;
  if (chal.opts[i] === chal.m.a) {
    var p = chal.p;
    score += 25; floatText(head.x, head.y - 20, "+25 Escaped!", "#ffd54f");
    p.stun = 4; cd = 3;
    if (p.type === "jaguar") { p.x = head.x < W / 2 ? W - 60 : 60; p.y = head.y < H / 2 ? H - 50 : 300; p.tx = p.x; p.ty = p.y; }
    else { p.x = head.x < W / 2 ? W - 80 : 80; p.y = (RV.y1 + RV.y2) / 2; }
    state = "play"; $("chal").style.display = "none";
    setMsg("Correct! " + qText(chal.m).replace("?", chal.m.a) + " \u2014 the " + p.type + " backs off.", "#34d399");
    hud();
  } else {
    lose(chal.p.type === "jaguar" ? "Pounced on by the Jaguar!" : "Dragged under by the Black Caiman!");
  }
}

function step() {
  if (state === "challenge") {
    chal.time -= 1 / 60; $("cbar").style.width = Math.max(0, chal.time / chal.max * 100) + "%";
    if (chal.time <= 0) lose("Too slow! The " + chal.p.type + " got you.");
    return;
  }
  if (state !== "play") return;
  t += 1 / 60; cd -= 1 / 60; frame++;
  energy -= lambda() / 60;
  heading += ((keys.r ? 1 : 0) - (keys.l ? 1 : 0)) * TURN;
  head.x += Math.cos(heading) * SPEED; head.y += Math.sin(heading) * SPEED;
  if (head.x < 0) head.x += W; if (head.x > W) head.x -= W;
  if (head.y < 0) head.y += H; if (head.y > H) head.y -= H;
  trail.unshift({ x: head.x, y: head.y });
  while (trail.length > segs * GAP + 2) trail.pop();
  for (var i = 8; i < segs; i++) if (dist(head, segPos(i)) < 8) { lose("Tangled in your own coils!"); return; }

  preys.forEach(updPrey);
  for (i = 0; i < preys.length; i++) {
    var p = preys[i];
    if (dist(head, p) < 20) {
      if (p.ok) {
        score += 10; eaten++; energy = Math.min(100, energy + 25); segs += 2;
        floatText(p.x, p.y - 20, "+10  " + qText(quest).replace("?", quest.a), "#34d399");
        setMsg("Delicious! Correct answer: " + quest.a, "#34d399");
        if (eaten >= L.target) { hud(); win(); return; }
        newQuest();
      } else {
        energy -= 20; floatText(p.x, p.y - 20, "Toxic! -20", "#fb7185");
        setMsg("Toxic prey! " + qText(quest).replace("?", quest.a) + ", not " + p.val, "#fb7185");
        preys.splice(i, 1);
      }
      break;
    }
  }
  for (i = 0; i < preds.length; i++) {
    var d = preds[i];
    if (d.type === "jaguar") updJaguar(d); else updCaiman(d);
    if (cd <= 0 && d.stun <= 0 && dist(d, head) < 75) { startChallenge(d); break; }
  }
  floaters.forEach(function (f) { f.life--; f.y -= 0.6; });
  floaters = floaters.filter(function (f) { return f.life > 0; });
  if (energy <= 0) { energy = 0; hud(); lose("Starved! Your energy ran out."); return; }
  if (frame % 6 === 0) hud();
}

function lose(cause) {
  state = "over"; hud();
  $("chal").style.display = "none";
  Arcade.saveScore("amazon", score);
  Arcade.endScreen($("end"), { good: false, title: cause, text: "You ate " + eaten + " of " + L.target + " prey on level " + curLevel + ". Score " + score + ".",
    retry: function () { begin(curLevel); }, menu: showMenu });
}
function win() {
  state = "over";
  var final = score + Math.round(energy) + curLevel * 50;
  Arcade.levelDone("amazon", curLevel); Arcade.saveScore("amazon", final);
  var more = curLevel < LV.length;
  Arcade.endScreen($("end"), { good: true, title: more ? "Level " + curLevel + " survived!" : "You rule the Amazon!",
    text: "Score " + final + " (includes " + Math.round(energy) + " energy bonus). Spend points in the Store.",
    next: more ? function () { begin(curLevel + 1); } : null, retry: function () { begin(curLevel); }, menu: showMenu });
}

/* ================= RENDER ================= */
function render(alpha) {
  ctx.drawImage(bg, 0, 0);
  drawRiver();
  if (state === "menu") { ctx.drawImage(fg, 0, 0); return; }
  preds.forEach(function (p) { if (p.type === "caiman") drawCaiman(p); });
  preys.forEach(function (p) { if (p.type === "frog") drawFrog(p); else drawCapy(p); });
  preds.forEach(function (p) { if (p.type === "jaguar") drawJaguar(p); });
  drawSnake();
  preys.forEach(function (p) { badge(p.x, p.y - 24, p.val, p.ok && inv.hint ? "#ffeb3b" : "#7be07b", p.ok && inv.hint); });
  ctx.drawImage(fg, 0, 0);
  ctx.font = "bold 15px Arial"; ctx.textAlign = "center";
  floaters.forEach(function (f) { ctx.globalAlpha = Math.min(1, f.life / 30); ctx.fillStyle = f.col; ctx.fillText(f.txt, f.x, f.y); });
  ctx.globalAlpha = 1;
  if (state === "play" && energy < 25) { ctx.fillStyle = "rgba(200,0,0," + (0.08 + 0.06 * Math.sin(clk * 8)) + ")"; ctx.fillRect(0, 0, W, H); }
  if (state === "play") preds.forEach(function (d) {
    if (d.stun <= 0 && dist(d, head) < 150) { ctx.fillStyle = "#ff5252"; ctx.font = "bold 16px Arial"; ctx.fillText("\u26A0 " + d.type.toUpperCase() + " NEARBY", d.x, d.y - 32); }
  });
}

document.addEventListener("keydown", function (e) {
  var k = e.key;
  if (k === "ArrowLeft" || k === "a" || k === "A") keys.l = true;
  if (k === "ArrowRight" || k === "d" || k === "D") keys.r = true;
  if (state === "challenge" && (k === "1" || k === "2" || k === "3")) answer(parseInt(k, 10) - 1);
  if (k.indexOf("Arrow") === 0 || k === " ") e.preventDefault();
});
document.addEventListener("keyup", function (e) {
  var k = e.key;
  if (k === "ArrowLeft" || k === "a" || k === "A") keys.l = false;
  if (k === "ArrowRight" || k === "d" || k === "D") keys.r = false;
});

// AJAX: load the store items this player owns
function loadInventory() {
  Arcade.req("GET", "/inventory", null, function (s, text) {
    var names = { hint: "Botanist Lens", elixir: "Metabolic Elixir", golden_skin: "Golden Viper Skin", cloak: "Apex Cloak" }, have = [];
    if (s === 200 && text) text.split(",").forEach(function (c) { inv[c] = true; have.push(names[c] || c); });
    $("invline").innerHTML = "<small>Active store items: " + (have.length ? have.join(", ") : "none yet &mdash; visit the Store") + "</small>";
  });
}

L = LV[0];
buildScenery();
loadInventory();
head = { x: 0, y: 0 }; preds = []; preys = []; floaters = []; segs = 6; trail = [{ x: 0, y: 0 }];
Arcade.loop({ tickMs: function () { return state === "menu" ? 0 : 16.667; }, step: step, render: function (a) { clk = Date.now() / 1000; render(a); } });
showMenu();
</script>
</body></html>
