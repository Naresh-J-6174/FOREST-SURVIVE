<%@ page contentType="text/html;charset=UTF-8" %>
<%@ include file="/WEB-INF/auth.jspf" %>
<!DOCTYPE html>
<html><head><title>Classic Snake</title><%@ include file="/WEB-INF/head.jspf" %></head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="amazon-container" style="max-width:640px">
 <div class="amazon-card center gamebox" id="gamebox" data-touch="dpad"><button class="btn-amazon-secondary fs-btn" onclick="Arcade.toggleFull()">Fullscreen</button>
  <h2>Classic Snake</h2>
  <div class="hud">
    <span class="pill">Level <b id="lv">-</b></span>
    <span class="pill">Berries <b id="prog">0/0</b></span>
    <span class="pill">Score <b id="score">0</b></span>
  </div>
  <div class="wrap">
    <canvas id="c" width="480" height="480"></canvas>
    <div class="ov" id="menu"></div>
    <div class="ov" id="end"></div>
  </div>
  <p class="muted" style="margin-top:10px"><span class="kb">Arrow keys / WASD to steer.</span><span class="tc">Swipe on the board or use the arrow pad to steer.</span> Walls and rocks are deadly.</p>
 </div>
</div>
<script>
var T = 24, N = 20;
var LV = [
  { name: "Meadow",       desc: "Eat 5 berries",  target: 5,  tick: 140, rocks: 0 },
  { name: "Riverbank",    desc: "Eat 8 berries",  target: 8,  tick: 120, rocks: 0 },
  { name: "Rocky Trail",  desc: "Eat 10 berries + rocks", target: 10, tick: 110, rocks: 6 },
  { name: "Dense Jungle", desc: "Eat 12 berries + more rocks", target: 12, tick: 100, rocks: 10 },
  { name: "Storm Season", desc: "Eat 15 berries, fast!", target: 15, tick: 85, rocks: 14 }
];
var PAL = { a: "#34d399", b: "#10b981", dark: "#065f46" };
var cv = document.getElementById("c"), ctx = cv.getContext("2d");
var lv = 1, L = LV[0], sn, food, rocks, score, eaten, state = "menu", bg;

function $(id) { return document.getElementById(id); }
function cp(c) { return { x: c.x, y: c.y }; }
function rnd(a, b) { return Arcade.rnd(a, b); }

// pre-rendered checkered jungle floor
bg = document.createElement("canvas"); bg.width = bg.height = N * T;
(function () {
  var b = bg.getContext("2d");
  for (var y = 0; y < N; y++) for (var x = 0; x < N; x++) { b.fillStyle = (x + y) % 2 ? "#0c2f1e" : "#0a2a1a"; b.fillRect(x * T, y * T, T, T); }
  for (var i = 0; i < 120; i++) { b.fillStyle = "rgba(52,211,153,.07)"; b.beginPath(); b.arc(Math.random() * N * T, Math.random() * N * T, rnd(2, 7), 0, 6.2832); b.fill(); }
})();

function showMenu() {
  state = "menu"; $("end").style.display = "none";
  Arcade.levelMenu($("menu"), "snake", "Classic Snake", LV, start);
}

function isFree(x, y) {
  if (sn.body.some(function (c) { return c.x === x && c.y === y; })) return false;
  if (rocks.some(function (c) { return c.x === x && c.y === y; })) return false;
  return true;
}
function placeFood() { var x, y; do { x = rnd(0, N - 1); y = rnd(0, N - 1); } while (!isFree(x, y)); food = { x: x, y: y }; }

function start(l) {
  lv = l; L = LV[l - 1];
  sn = { body: [{ x: 5, y: 10 }, { x: 4, y: 10 }, { x: 3, y: 10 }], dir: { dx: 1, dy: 0 }, next: { dx: 1, dy: 0 } };
  sn.prev = sn.body.map(cp);
  rocks = []; score = 0; eaten = 0;
  for (var i = 0; i < L.rocks; i++) {
    var x, y; do { x = rnd(0, N - 1); y = rnd(0, N - 1); } while ((y >= 9 && y <= 11 && x < 12) || rocks.some(function (r) { return r.x === x && r.y === y; }));
    rocks.push({ x: x, y: y });
  }
  placeFood();
  $("menu").style.display = "none"; $("end").style.display = "none";
  state = "play"; hud();
}
function hud() { $("lv").textContent = lv; $("prog").textContent = eaten + "/" + L.target; $("score").textContent = score; }

function step() {
  sn.prev = sn.body.map(cp);
  sn.dir = sn.next;
  var h = { x: sn.body[0].x + sn.dir.dx, y: sn.body[0].y + sn.dir.dy };
  var hitSelf = sn.body.slice(0, -1).some(function (c) { return c.x === h.x && c.y === h.y; });
  var hitRock = rocks.some(function (c) { return c.x === h.x && c.y === h.y; });
  if (h.x < 0 || h.y < 0 || h.x >= N || h.y >= N || hitSelf || hitRock) { lose(); return; }
  sn.body.unshift(h);
  if (h.x === food.x && h.y === food.y) {
    eaten++; score += 10;
    if (eaten >= L.target) { hud(); win(); return; }
    placeFood();
  } else sn.body.pop();
  hud();
}

function lose() {
  state = "over";
  Arcade.saveScore("snake", score);
  Arcade.endScreen($("end"), { good: false, title: "Crashed!", text: "You ate " + eaten + " of " + L.target + " berries on level " + lv + ".",
    retry: function () { start(lv); }, menu: showMenu });
}
function win() {
  state = "over";
  var final = score + lv * 50;
  Arcade.levelDone("snake", lv); Arcade.saveScore("snake", final);
  var more = lv < LV.length;
  Arcade.endScreen($("end"), { good: true, title: more ? "Level " + lv + " cleared!" : "You conquered every level!",
    text: "Score: " + final + (more ? "" : " &mdash; you are a Snake Champion!"),
    next: more ? function () { start(lv + 1); } : null, retry: function () { start(lv); }, menu: showMenu });
}

function render(alpha) {
  ctx.drawImage(bg, 0, 0);
  if (state === "menu") return;
  rocks.forEach(function (r) {
    ctx.fillStyle = "#4b5563"; ctx.beginPath(); ctx.roundRect ? ctx.roundRect(r.x * T + 2, r.y * T + 2, T - 4, T - 4, 6) : ctx.rect(r.x * T + 2, r.y * T + 2, T - 4, T - 4); ctx.fill();
    ctx.fillStyle = "#6b7280"; ctx.beginPath(); ctx.arc(r.x * T + 9, r.y * T + 9, 4, 0, 6.2832); ctx.fill();
  });
  if (food) {
    var fx = food.x * T + T / 2, fy = food.y * T + T / 2, pulse = 1 + 0.08 * Math.sin(Date.now() / 150);
    ctx.fillStyle = "rgba(244,63,94,.25)"; ctx.beginPath(); ctx.arc(fx, fy, 12 * pulse, 0, 6.2832); ctx.fill();
    ctx.fillStyle = "#f43f5e"; ctx.beginPath(); ctx.arc(fx, fy, 7 * pulse, 0, 6.2832); ctx.fill();
    ctx.fillStyle = "#fecdd3"; ctx.beginPath(); ctx.arc(fx - 2, fy - 2, 2, 0, 6.2832); ctx.fill();
  }
  Arcade.drawSnake(ctx, sn, alpha, T, PAL);
}

document.addEventListener("keydown", function (e) {
  if (state !== "play") return;
  var k = e.key, d = sn.dir;
  if ((k === "ArrowUp" || k === "w" || k === "W") && d.dy !== 1) sn.next = { dx: 0, dy: -1 };
  else if ((k === "ArrowDown" || k === "s" || k === "S") && d.dy !== -1) sn.next = { dx: 0, dy: 1 };
  else if ((k === "ArrowLeft" || k === "a" || k === "A") && d.dx !== 1) sn.next = { dx: -1, dy: 0 };
  else if ((k === "ArrowRight" || k === "d" || k === "D") && d.dx !== -1) sn.next = { dx: 1, dy: 0 };
  if (k.indexOf("Arrow") === 0) e.preventDefault();
});

Arcade.loop({ tickMs: function () { return state === "play" ? L.tick : 0; }, step: step, render: render });
showMenu();
</script>
</body></html>
