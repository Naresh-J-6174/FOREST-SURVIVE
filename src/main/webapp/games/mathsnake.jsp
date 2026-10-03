<%@ page contentType="text/html;charset=UTF-8" %>
<%@ include file="/WEB-INF/auth.jspf" %>
<!DOCTYPE html>
<html><head><title>Math Snake</title><%@ include file="/WEB-INF/head.jspf" %></head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="amazon-container" style="max-width:700px">
 <div class="amazon-card center gamebox" id="gamebox" data-touch="dpad"><button class="btn-amazon-secondary fs-btn" onclick="Arcade.toggleFull()">Fullscreen</button>
  <h2>Math Snake</h2>
  <div class="quest" id="question">Choose a level</div>
  <div class="hud" style="margin-top:8px">
    <span class="pill">Level <b id="lv">-</b></span>
    <span class="pill">Correct <b id="prog">0/0</b></span>
    <span class="pill">Lives <b id="lives">3</b></span>
    <span class="pill">Score <b id="score">0</b></span>
  </div>
  <div id="msg"></div>
  <div class="wrap">
    <canvas id="c" width="480" height="480"></canvas>
    <div class="ov" id="menu"></div>
    <div class="ov" id="end"></div>
  </div>
  <p class="muted" style="margin-top:10px"><span class="kb">Steer with the arrow keys / WASD</span><span class="tc">Swipe on the board or use the arrow pad to steer</span> and eat the food showing the correct answer.</p>
 </div>
</div>
<script>
var T = 24, N = 20;
var LV = [
  { name: "Addition Meadow",    desc: "5 correct sums",        target: 5,  tick: 170 },
  { name: "Subtraction Creek",  desc: "6 correct answers",     target: 6,  tick: 160 },
  { name: "Times-Table Trail",  desc: "7 correct answers",     target: 7,  tick: 150 },
  { name: "Division Dunes",     desc: "8 correct answers",     target: 8,  tick: 140 },
  { name: "Squares & Equations",desc: "9 correct answers",     target: 9,  tick: 130 },
  { name: "Order of Operations",desc: "10 correct answers",    target: 10, tick: 120 }
];
var PAL = { a: "#86efac", b: "#22c55e", dark: "#14532d" };
var cv = document.getElementById("c"), ctx = cv.getContext("2d");
var lv = 1, L = LV[0], sn, foods = [], q, score, eaten, lives, state = "menu", bg;

function $(id) { return document.getElementById(id); }
function cp(c) { return { x: c.x, y: c.y }; }
function rnd(a, b) { return Arcade.rnd(a, b); }
function setMsg(t, c) { var m = $("msg"); m.textContent = t; m.style.color = c || "#ecfdf5"; }

bg = document.createElement("canvas"); bg.width = bg.height = N * T;
(function () {
  var b = bg.getContext("2d");
  for (var y = 0; y < N; y++) for (var x = 0; x < N; x++) { b.fillStyle = (x + y) % 2 ? "#0c2f1e" : "#0a2a1a"; b.fillRect(x * T, y * T, T, T); }
})();

function showMenu() {
  state = "menu"; $("end").style.display = "none"; $("question").textContent = "Choose a level";
  Arcade.levelMenu($("menu"), "mathsnake", "Math Snake", LV, start);
}

function occupied(x, y) {
  return sn.body.some(function (c) { return c.x === x && c.y === y; }) || foods.some(function (f) { return f.x === x && f.y === y; });
}
function newQuestion() {
  q = Arcade.mathLevel(lv);
  var vals = Arcade.options(q.a, 3);
  foods = [];
  vals.forEach(function (v) {
    var x, y, g = 0;
    do { x = rnd(1, N - 2); y = rnd(1, N - 2); g++; } while ((occupied(x, y) || (y === 10 && x < 9)) && g < 100);
    foods.push({ x: x, y: y, val: v, ok: v === q.a });
  });
  $("question").textContent = Arcade.qText(q);
}

function start(l) {
  lv = l; L = LV[l - 1];
  sn = { body: [{ x: 5, y: 10 }, { x: 4, y: 10 }, { x: 3, y: 10 }], dir: { dx: 1, dy: 0 }, next: { dx: 1, dy: 0 } };
  sn.prev = sn.body.map(cp);
  score = 0; eaten = 0; lives = 3; foods = [];
  setMsg(""); newQuestion();
  $("menu").style.display = "none"; $("end").style.display = "none";
  state = "play"; hud();
}
function hud() { $("lv").textContent = lv; $("prog").textContent = eaten + "/" + L.target; $("lives").textContent = lives; $("score").textContent = score; }

function step() {
  sn.prev = sn.body.map(cp);
  sn.dir = sn.next;
  var h = { x: sn.body[0].x + sn.dir.dx, y: sn.body[0].y + sn.dir.dy };
  var hitSelf = sn.body.slice(0, -1).some(function (c) { return c.x === h.x && c.y === h.y; });
  if (h.x < 0 || h.y < 0 || h.x >= N || h.y >= N || hitSelf) { lose("Crashed!"); return; }
  sn.body.unshift(h);
  var i = foods.findIndex(function (f) { return f.x === h.x && f.y === h.y; });
  if (i < 0) { sn.body.pop(); return; }
  if (foods[i].ok) {
    eaten++; score += 10;
    setMsg("Correct! " + Arcade.qText(q).replace("?", q.a), "#34d399");
    if (eaten >= L.target) { hud(); win(); return; }
    newQuestion();                                  // tail kept = snake grows
  } else {
    lives--;
    setMsg("Oops! " + Arcade.qText(q).replace("?", q.a) + ", not " + foods[i].val, "#fb7185");
    foods.splice(i, 1); sn.body.pop();
    if (lives <= 0) { hud(); lose("Out of lives!"); return; }
  }
  hud();
}

function lose(why) {
  state = "over";
  Arcade.saveScore("mathsnake", score);
  Arcade.endScreen($("end"), { good: false, title: why, text: "You solved " + eaten + " of " + L.target + " on level " + lv + ".",
    retry: function () { start(lv); }, menu: showMenu });
}
function win() {
  state = "over";
  var final = score + lives * 10 + lv * 50;
  Arcade.levelDone("mathsnake", lv); Arcade.saveScore("mathsnake", final);
  var more = lv < LV.length;
  Arcade.endScreen($("end"), { good: true, title: more ? "Level " + lv + " cleared!" : "Math champion!",
    text: "Score: " + final + " (" + lives + " lives left)", next: more ? function () { start(lv + 1); } : null,
    retry: function () { start(lv); }, menu: showMenu });
}

function render(alpha) {
  ctx.drawImage(bg, 0, 0);
  if (state === "menu") return;
  ctx.font = "bold 12px Arial"; ctx.textAlign = "center"; ctx.textBaseline = "middle";
  foods.forEach(function (f) {
    var x = f.x * T + T / 2, y = f.y * T + T / 2;
    ctx.fillStyle = "rgba(245,158,11,.25)"; ctx.beginPath(); ctx.arc(x, y, 15, 0, 6.2832); ctx.fill();
    ctx.fillStyle = "#f59e0b"; ctx.beginPath(); ctx.arc(x, y, 11, 0, 6.2832); ctx.fill();
    ctx.fillStyle = "#1c1917"; ctx.fillText(f.val, x, y + 1);
  });
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
