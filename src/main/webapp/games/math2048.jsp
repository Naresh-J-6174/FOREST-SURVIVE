<%@ page contentType="text/html;charset=UTF-8" %>
<%
  if (session.getAttribute("username") == null) { response.sendRedirect("../login.jsp"); return; }
%>
<!DOCTYPE html>
<html><head><title>Math 2048</title><link rel="stylesheet" href="../js/style.css">
<style>
#board{display:grid;grid-template-columns:repeat(4,80px);gap:8px;background:#39415a;padding:8px;border-radius:8px;width:max-content;margin:12px auto}
.tile{width:80px;height:80px;border-radius:6px;background:#252c42;display:flex;flex-direction:column;align-items:center;justify-content:center;font-weight:bold;font-size:24px;color:#222}
.tile small{font-size:11px;font-weight:normal}
#quiz{display:none;background:#1b2030;border:2px solid #ffd54f;border-radius:10px;max-width:360px;margin:10px auto;padding:14px}
#quiz button{margin:4px;min-width:60px}
</style></head>
<body>
<h2>Math 2048</h2>
<p>Score: <b id="score">0</b> | Best tile: <b id="best">2</b> | <label><input type="checkbox" id="hint" onchange="draw()"> Show powers of 2</label></p>
<p>Arrow keys slide the tiles. Two equal tiles merge into their <b>double</b>.<br>Every time you make a new big tile, answer an <b>exponent question</b> for bonus points!</p>
<div id="board"></div>
<div id="quiz"><p id="qtext" style="font-size:18px"></p><div id="opts"></div><p id="qres"></p></div>
<p id="msg"></p>
<p><button onclick="newGame()">New Game</button> <a href="../index.jsp">Back</a> | <a href="../leaderboard.jsp">Leaderboard</a></p>

<script>
var grid, score, bestTile, milestone, locked, over;
var COLORS = {0:"#252c42",2:"#eee4da",4:"#ede0c8",8:"#f2b179",16:"#f59563",32:"#f67c5f",64:"#f65e3b",128:"#edcf72",256:"#edcc61",512:"#edc850",1024:"#edc53f",2048:"#edc22e"};

function newGame() {
  grid = [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]];
  score = 0; bestTile = 2; milestone = 4; locked = false; over = false;
  document.getElementById("quiz").style.display = "none";
  document.getElementById("msg").textContent = "";
  addTile(); addTile(); draw();
}

function addTile() {
  var empty = [];
  for (var r = 0; r < 4; r++) for (var c = 0; c < 4; c++) if (!grid[r][c]) empty.push([r, c]);
  if (!empty.length) return;
  var p = empty[Math.floor(Math.random() * empty.length)];
  grid[p[0]][p[1]] = Math.random() < 0.9 ? 2 : 4;
}

function draw() {
  var b = document.getElementById("board"), show = document.getElementById("hint").checked, html = "";
  for (var r = 0; r < 4; r++) for (var c = 0; c < 4; c++) {
    var v = grid[r][c], bg = COLORS[v] || "#3c3a32", col = v > 4 ? "#fff" : "#222";
    html += '<div class="tile" style="background:' + bg + ';color:' + col + '">' + (v ? v : "") +
            (v && show ? "<small>2<sup>" + Math.log2(v) + "</sup></small>" : "") + "</div>";
  }
  b.innerHTML = html;
  document.getElementById("score").textContent = score;
  document.getElementById("best").textContent = bestTile;
}

// position of cell j in line i for a given direction
function pos(d, i, j) {
  if (d === "left") return [i, j];
  if (d === "right") return [i, 3 - j];
  if (d === "up") return [j, i];
  return [3 - j, i];
}

function slide(line) {
  var a = line.filter(function (v) { return v; }), gained = 0;
  for (var i = 0; i < a.length - 1; i++) {
    if (a[i] === a[i + 1]) { a[i] *= 2; gained += a[i]; a.splice(i + 1, 1); }
  }
  while (a.length < 4) a.push(0);
  return { line: a, gained: gained };
}

function move(d) {
  var moved = false, gained = 0;
  for (var i = 0; i < 4; i++) {
    var line = [];
    for (var j = 0; j < 4; j++) { var p = pos(d, i, j); line.push(grid[p[0]][p[1]]); }
    var res = slide(line);
    for (j = 0; j < 4; j++) {
      p = pos(d, i, j);
      if (grid[p[0]][p[1]] !== res.line[j]) moved = true;
      grid[p[0]][p[1]] = res.line[j];
    }
    gained += res.gained;
  }
  if (!moved) return;
  score += gained;
  addTile();
  var mx = 0;
  grid.forEach(function (row) { row.forEach(function (v) { if (v > mx) mx = v; }); });
  bestTile = mx;
  draw();
  if (mx >= milestone) { milestone = mx * 2; askQuiz(mx); }
  else if (!canMove()) endGame();
}

function canMove() {
  for (var r = 0; r < 4; r++) for (var c = 0; c < 4; c++) {
    if (!grid[r][c]) return true;
    if (c < 3 && grid[r][c] === grid[r][c + 1]) return true;
    if (r < 3 && grid[r][c] === grid[r + 1][c]) return true;
  }
  return false;
}

// ---- Exponent quiz (middle school maths) ----
function askQuiz(tile) {
  locked = true;
  var e = Math.log2(tile), correct, text;
  if (Math.random() < 0.5) { text = "You made " + tile + "!  " + tile + " = 2 to the power ?"; correct = e; }
  else { text = "What is 2 to the power " + e + "  (2^" + e + ")?"; correct = tile; }
  var opts = [correct];
  while (opts.length < 4) {
    var w = (correct === e) ? e + Math.floor(Math.random() * 7) - 3 : Math.pow(2, e + Math.floor(Math.random() * 5) - 2);
    if (w > 0 && opts.indexOf(w) === -1) opts.push(w);
  }
  opts.sort(function () { return Math.random() - 0.5; });
  document.getElementById("qtext").textContent = text;
  document.getElementById("qres").textContent = "";
  var o = document.getElementById("opts"); o.innerHTML = "";
  opts.forEach(function (v) {
    var btn = document.createElement("button");
    btn.textContent = v;
    btn.onclick = function () { answerQuiz(v === correct, tile, e); };
    o.appendChild(btn);
  });
  document.getElementById("quiz").style.display = "block";
}

function answerQuiz(ok, tile, e) {
  var res = document.getElementById("qres");
  if (ok) { score += tile; res.style.color = "#7be07b"; res.textContent = "Correct! +" + tile + " bonus points. " + tile + " = 2^" + e; }
  else { res.style.color = "#ff6b6b"; res.textContent = "Not quite: " + tile + " = 2^" + e + " (2 multiplied by itself " + e + " times)"; }
  document.getElementById("opts").innerHTML = "";
  draw();
  setTimeout(function () {
    document.getElementById("quiz").style.display = "none";
    locked = false;
    if (!canMove()) endGame();
  }, 1800);
}

function endGame() {
  over = true;
  document.getElementById("msg").textContent = "Game over! Final score: " + score;
  var xhr = new XMLHttpRequest();
  xhr.onreadystatechange = function () {
    if (xhr.readyState === 4)
      document.getElementById("msg").textContent = "Game over! Final score: " + score + (xhr.status === 200 ? " (saved)" : " (could not save)");
  };
  xhr.open("POST", "../saveScore", true);
  xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  xhr.send("game=math2048&score=" + score);
}

document.addEventListener("keydown", function (e) {
  var map = { ArrowLeft: "left", ArrowRight: "right", ArrowUp: "up", ArrowDown: "down" };
  if (map[e.key]) { e.preventDefault(); if (!locked && !over) move(map[e.key]); }
});
newGame();
</script>
</body></html>
