<%@ page contentType="text/html;charset=UTF-8" %>
<%@ include file="/WEB-INF/auth.jspf" %>
<!DOCTYPE html>
<html><head><title>Snake Duel</title><%@ include file="/WEB-INF/head.jspf" %></head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="amazon-container" style="max-width:800px">
 <div class="amazon-card center gamebox" id="gamebox" data-touch="dpad"><button class="btn-amazon-secondary fs-btn" onclick="Arcade.toggleFull()">Fullscreen</button>
  <h2>Snake Duel: You vs the Crimson Viper</h2>
  <div class="quest" id="question">Choose a level</div>
  <div class="hud" style="margin-top:8px">
    <span class="pill">Level <b id="lv">-</b></span>
    <span class="pill" style="border-color:#10b981">You <b id="ps">0</b>/<b id="tg1">0</b> <span class="bar"><div id="pbar" style="background:#10b981"></div></span></span>
    <span class="pill" style="border-color:#f43f5e">Bot <b id="bs">0</b>/<b id="tg2">0</b> <span class="bar"><div id="bbar" style="background:#f43f5e"></div></span></span>
  </div>
  <div id="msg"></div>
  <div class="wrap">
    <canvas id="c" width="720" height="480"></canvas>
    <div class="ov" id="menu"></div>
    <div class="ov" id="end"></div>
  </div>
  <p class="muted" style="margin-top:10px"><span class="kb">Arrow keys / WASD to steer. </span><span class="tc">Swipe on the board or use the arrow pad to steer. </span>Eat the food with the <b>correct answer</b> before the bot does. Wrong food costs a point. Crashing costs a point and respawns you.</p>
 </div>
</div>
<script>
var COLS = 30, ROWS = 20, CS = 24;
var LV = [
  { name: "Tropical Shallows", desc: "First to 5 &middot; slow bot",   target: 5,  tick: 130, bspd: 0.5,  err: 0.30 },
  { name: "Floodplain",        desc: "First to 6",                      target: 6,  tick: 125, bspd: 0.7,  err: 0.20 },
  { name: "Deep Canopy",       desc: "First to 7",                      target: 7,  tick: 115, bspd: 0.85, err: 0.12 },
  { name: "Night Hunt",        desc: "First to 8 &middot; fast bot",    target: 8,  tick: 105, bspd: 1,    err: 0.07 },
  { name: "Apex Showdown",     desc: "First to 10 &middot; expert bot", target: 10, tick: 95,  bspd: 1,    err: 0.02 }
];
var DIRS = [{ dx: 1, dy: 0 }, { dx: -1, dy: 0 }, { dx: 0, dy: 1 }, { dx: 0, dy: -1 }];
var PAL_ME = { a: "#34d399", b: "#10b981", dark: "#065f46" };
var PAL_BOT = { a: "#fb7185", b: "#e11d48", dark: "#7f1d1d" };
var cv = document.getElementById("c"), ctx = cv.getContext("2d");
var lv = 1, L = LV[0], me, bot, foods = [], q, pS = 0, bS = 0, state = "menu", botAcc = 0, bg;

function $(id) { return document.getElementById(id); }
function cp(c) { return { x: c.x, y: c.y }; }
function rnd(a, b) { return Arcade.rnd(a, b); }
function setMsg(t, c) { var m = $("msg"); m.textContent = t; m.style.color = c || "#ecfdf5"; }

bg = document.createElement("canvas"); bg.width = COLS * CS; bg.height = ROWS * CS;
(function () {
  var b = bg.getContext("2d");
  for (var y = 0; y < ROWS; y++) for (var x = 0; x < COLS; x++) { b.fillStyle = (x + y) % 2 ? "#0c2f1e" : "#0a2a1a"; b.fillRect(x * CS, y * CS, CS, CS); }
  for (var i = 0; i < 160; i++) { b.fillStyle = "rgba(52,211,153,.06)"; b.beginPath(); b.arc(Math.random() * COLS * CS, Math.random() * ROWS * CS, rnd(2, 8), 0, 6.2832); b.fill(); }
})();

function mk(x, y, dx, dy, len) {
  var body = [];
  for (var i = 0; i < len; i++) body.push({ x: x - dx * i, y: y - dy * i });
  return { body: body, prev: body.map(cp), dir: { dx: dx, dy: dy }, next: { dx: dx, dy: dy }, spawn: { x: x, y: y, dx: dx, dy: dy, len: len } };
}

function showMenu() {
  state = "menu"; $("end").style.display = "none"; $("question").textContent = "Choose a level";
  Arcade.levelMenu($("menu"), "duel", "Snake Duel vs Bot", LV, start);
}

function free(x, y) {
  if (x < 0 || y < 0 || x >= COLS || y >= ROWS) return false;
  function on(c) { return c.x === x && c.y === y; }
  return !me.body.some(on) && !bot.body.some(on);
}
function newRound() {
  q = Arcade.mathTier(Math.min(3, Math.ceil(lv / 2)));
  var vals = Arcade.options(q.a, 3);
  foods = [];
  vals.forEach(function (v) {
    var x, y, g = 0;
    do { x = rnd(1, COLS - 2); y = rnd(1, ROWS - 2); g++; }
    while ((!free(x, y) || foods.some(function (f) { return f.x === x && f.y === y; })) && g < 200);
    foods.push({ x: x, y: y, val: v, ok: v === q.a });
  });
  $("question").textContent = Arcade.qText(q);
}

function start(l) {
  lv = l; L = LV[l - 1];
  me = mk(5, 10, 1, 0, 4); bot = mk(24, 10, -1, 0, 4);
  pS = 0; bS = 0; botAcc = 0; foods = [];
  setMsg("Go!", "#fcd34d"); newRound();
  $("menu").style.display = "none"; $("end").style.display = "none";
  state = "play"; hud();
}
function hud() {
  $("lv").textContent = lv; $("ps").textContent = pS; $("bs").textContent = bS;
  $("tg1").textContent = L.target; $("tg2").textContent = L.target;
  $("pbar").style.width = Math.min(100, pS / L.target * 100) + "%";
  $("bbar").style.width = Math.min(100, bS / L.target * 100) + "%";
}

/* ---------- Bot AI: breadth-first search to the correct answer ---------- */
function bfs(start, goal) {
  var blocked = {}, seen = {}, queue = [];
  function key(x, y) { return y * COLS + x; }
  me.body.concat(bot.body).forEach(function (c) { blocked[key(c.x, c.y)] = 1; });
  foods.forEach(function (f) { if (!f.ok) blocked[key(f.x, f.y)] = 1; });     // the bot avoids wrong food
  seen[key(start.x, start.y)] = 1;
  function push(x, y, first) {
    if (x < 0 || y < 0 || x >= COLS || y >= ROWS) return;
    var k = key(x, y);
    if (blocked[k] || seen[k]) return;
    seen[k] = 1; queue.push({ x: x, y: y, first: first });
  }
  DIRS.forEach(function (d) { push(start.x + d.dx, start.y + d.dy, d); });
  while (queue.length) {
    var c = queue.shift();
    if (c.x === goal.x && c.y === goal.y) return c.first;
    DIRS.forEach(function (d) { push(c.x + d.dx, c.y + d.dy, c.first); });
  }
  return null;
}
function botThink() {
  var h = bot.body[0];
  var safe = DIRS.filter(function (d) { return !(d.dx === -bot.dir.dx && d.dy === -bot.dir.dy) && free(h.x + d.dx, h.y + d.dy); });
  if (!safe.length) { bot.next = bot.dir; return; }
  if (Math.random() < L.err) { bot.next = safe[rnd(0, safe.length - 1)]; return; }   // mistakes: weaker on low levels
  var goal = foods.filter(function (f) { return f.ok; })[0];
  var s = goal ? bfs(h, goal) : null;
  bot.next = (s && safe.some(function (d) { return d.dx === s.dx && d.dy === s.dy; })) ? s : safe[0];
}

/* ---------- one game tick ---------- */
function hit(h, self, other, otherHead) {
  function on(c) { return c.x === h.x && c.y === h.y; }
  return h.x < 0 || h.y < 0 || h.x >= COLS || h.y >= ROWS || self.body.some(on) || other.body.some(on) || (otherHead && otherHead.x === h.x && otherHead.y === h.y);
}
function crash(sn) {
  if (sn === me) { pS = Math.max(0, pS - 1); setMsg("You crashed! -1 point", "#fb7185"); }
  else { bS = Math.max(0, bS - 1); setMsg("The Viper crashed! -1 point for the bot", "#34d399"); }
  var sp = sn.spawn;
  sn.body = [];
  for (var i = 0; i < sp.len; i++) sn.body.push({ x: sp.x - sp.dx * i, y: sp.y - sp.dy * i });
  sn.prev = sn.body.map(cp); sn.dir = { dx: sp.dx, dy: sp.dy }; sn.next = sn.dir;
}
function advance(sn, h, mine) {
  sn.body.unshift(h);
  var i = foods.findIndex(function (f) { return f.x === h.x && f.y === h.y; });
  if (i < 0) { sn.body.pop(); return; }
  var f = foods[i];
  if (f.ok) {
    if (mine) { pS++; setMsg("You ate the answer " + q.a + "!  +1", "#34d399"); } else { bS++; setMsg("The Viper got " + q.a + " first!", "#fb7185"); }
    newRound();                                                    // keep tail = grow
  } else {
    if (mine) { pS = Math.max(0, pS - 1); setMsg("Wrong food! " + Arcade.qText(q).replace("?", q.a) + ", not " + f.val, "#fb7185"); }
    else bS = Math.max(0, bS - 1);
    foods.splice(i, 1); sn.body.pop();
  }
}
function step() {
  me.prev = me.body.map(cp); bot.prev = bot.body.map(cp);
  me.dir = me.next;
  var mh = { x: me.body[0].x + me.dir.dx, y: me.body[0].y + me.dir.dy }, bh = null;
  botAcc += L.bspd;
  if (botAcc >= 1) {
    botAcc -= 1; botThink(); bot.dir = bot.next;
    bh = { x: bot.body[0].x + bot.dir.dx, y: bot.body[0].y + bot.dir.dy };
  }
  var md = hit(mh, me, bot, bh), bd = bh ? hit(bh, bot, me, mh) : false;
  if (md) crash(me); else advance(me, mh, true);
  if (bh) { if (bd) crash(bot); else advance(bot, bh, false); }
  hud();
  if (pS >= L.target) win(); else if (bS >= L.target) lose();
}

function lose() {
  state = "over";
  Arcade.saveScore("duel", pS * 10);
  Arcade.endScreen($("end"), { good: false, title: "The Viper wins this round", text: "Final: you " + pS + " &ndash; bot " + bS + ". Try again!",
    retry: function () { start(lv); }, menu: showMenu });
}
function win() {
  state = "over";
  var final = lv * 100 + pS * 10 + Math.max(0, (L.target - bS)) * 5;
  Arcade.levelDone("duel", lv); Arcade.saveScore("duel", final);
  var more = lv < LV.length;
  Arcade.endScreen($("end"), { good: true, title: more ? "You beat the bot!" : "You defeated the Apex Viper!",
    text: "Final: you " + pS + " &ndash; bot " + bS + ". Score " + final, next: more ? function () { start(lv + 1); } : null,
    retry: function () { start(lv); }, menu: showMenu });
}

/* ---------- drawing ---------- */
function render(alpha) {
  ctx.drawImage(bg, 0, 0);
  if (state === "menu") return;
  ctx.font = "bold 13px Arial"; ctx.textAlign = "center"; ctx.textBaseline = "middle";
  var pulse = 1 + 0.06 * Math.sin(Date.now() / 160);
  foods.forEach(function (f) {
    var x = f.x * CS + CS / 2, y = f.y * CS + CS / 2;
    ctx.fillStyle = "rgba(245,158,11,.25)"; ctx.beginPath(); ctx.arc(x, y, 15 * pulse, 0, 6.2832); ctx.fill();
    ctx.fillStyle = "#f59e0b"; ctx.beginPath(); ctx.arc(x, y, 11, 0, 6.2832); ctx.fill();
    ctx.fillStyle = "#1c1917"; ctx.fillText(f.val, x, y + 1);
  });
  Arcade.drawSnake(ctx, bot, alpha, CS, PAL_BOT);
  Arcade.drawSnake(ctx, me, alpha, CS, PAL_ME);
  ctx.font = "bold 11px Arial";
  [[me, "YOU", "#34d399"], [bot, "BOT", "#fb7185"]].forEach(function (t) {
    var h = t[0].body[0]; ctx.fillStyle = t[2]; ctx.fillText(t[1], h.x * CS + CS / 2, h.y * CS - 6);
  });
}

document.addEventListener("keydown", function (e) {
  if (state !== "play") return;
  var k = e.key, d = me.dir;
  if ((k === "ArrowUp" || k === "w" || k === "W") && d.dy !== 1) me.next = { dx: 0, dy: -1 };
  else if ((k === "ArrowDown" || k === "s" || k === "S") && d.dy !== -1) me.next = { dx: 0, dy: 1 };
  else if ((k === "ArrowLeft" || k === "a" || k === "A") && d.dx !== 1) me.next = { dx: -1, dy: 0 };
  else if ((k === "ArrowRight" || k === "d" || k === "D") && d.dx !== -1) me.next = { dx: 1, dy: 0 };
  if (k.indexOf("Arrow") === 0) e.preventDefault();
});

Arcade.loop({ tickMs: function () { return state === "play" ? L.tick : 0; }, step: step, render: render });
showMenu();
</script>
</body></html>
