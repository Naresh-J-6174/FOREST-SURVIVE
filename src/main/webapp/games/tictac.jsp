<%@ page contentType="text/html;charset=UTF-8" %>
<%@ include file="/WEB-INF/auth.jspf" %>
<!DOCTYPE html>
<html><head><title>Jungle Tic-Tac-Math</title><%@ include file="/WEB-INF/head.jspf" %></head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="amazon-container" style="max-width:720px">
 <div class="amazon-card gamebox online" id="gamebox"><button class="btn-amazon-secondary fs-btn" onclick="Arcade.toggleFull()">Fullscreen</button>
  <div class="center">
    <span class="badge-amazon cyan">LIVE 1v1</span>
    <h2 style="margin-top:8px">Jungle Tic-Tac-Math</h2>
    <p class="muted">Take turns. To claim a cell you must answer a maths question correctly. A wrong answer (or running out of 25 seconds) loses your turn. Three in a row wins!</p>
  </div>

  <div id="lobby" class="center" style="margin:26px 0">
    <button id="findBtn" onclick="findMatch()">Find opponent</button>
    <p id="lobbyMsg" class="muted" style="margin-top:12px">Open this page in a second browser with a different account to play yourself.</p>
  </div>

  <div id="arena" style="display:none" class="center">
    <div class="hud">
      <span class="pill" style="border-color:var(--em)">&#10005; <b id="n1"></b></span>
      <span class="pill" style="border-color:var(--rose)">&#9675; <b id="n2"></b></span>
    </div>
    <div id="turn" class="quest"></div>
    <div id="board" class="ttt"></div>
    <div id="note" class="muted" style="min-height:22px"></div>
    <div id="qbox" style="display:none;background:rgba(0,0,0,.35);padding:18px;border-radius:12px;margin-top:10px">
      <div class="quest" id="qtext" style="font-size:1.8rem"></div>
      <div id="opts" class="row"></div>
      <div class="bar" style="width:240px;margin-top:10px"><div id="tbar" style="width:100%;background:#ef5350"></div></div>
    </div>
    <div style="margin-top:14px"><button class="btn-amazon-secondary" onclick="leave()">Leave match</button></div>
  </div>

  <div id="result" class="center" style="display:none;margin-top:20px">
    <h1 id="rTitle"></h1><p id="rText" class="muted"></p>
    <div class="row"><button onclick="location.reload()">Play again</button><a class="btn-amazon btn-amazon-secondary" href="../index.jsp">Back to hub</a></div>
  </div>
 </div>
</div>
<script>
var room = null, slot = 0, timer = null, shownPQ = -1, last = null;
function $(id) { return document.getElementById(id); }

function findMatch() {
  Arcade.goFull();
  $("findBtn").disabled = true;
  $("lobbyMsg").textContent = "Searching for an opponent...";
  Arcade.json("POST", "/match", "action=join&game=tictac", function (s, d) {
    if (!d || d.error) { $("lobbyMsg").textContent = "Could not join: " + (d ? d.error : "server error"); $("findBtn").disabled = false; return; }
    room = d.room; slot = d.slot; render(d);
    if (!timer) timer = setInterval(poll, 700);
  });
}
function poll() { Arcade.json("GET", "/match?action=state&room=" + room, null, function (s, d) { if (d && !d.error) render(d); }); }
function leave() { Arcade.json("POST", "/match", "action=leave&room=" + room, function (s, d) { if (d) render(d); }); }

function pickCell(i) {
  if (!last || last.status !== "playing" || last.turn !== slot || last.pendCell >= 0 || last.board[i] !== 0) return;
  Arcade.json("POST", "/match", "action=pick&room=" + room + "&cell=" + i, function (s, d) { if (d && !d.error) render(d); });
}
function reply(v) {
  Arcade.json("POST", "/match", "action=reply&room=" + room + "&choice=" + v, function (s, d) { if (d && !d.error) render(d); });
}

function render(d) {
  last = d;
  if (d.status === "waiting") { $("lobbyMsg").textContent = "Waiting for another explorer to join the room..."; return; }
  if (d.status === "finished" && d.winner === -1) {
    clearInterval(timer); timer = null;
    $("lobbyMsg").textContent = d.reason; $("findBtn").disabled = false; $("lobby").style.display = "block"; $("arena").style.display = "none"; return;
  }
  $("lobby").style.display = "none"; $("arena").style.display = "block";
  var names = d.slot === 0 ? [d.you, d.opp] : [d.opp, d.you];
  $("n1").textContent = names[0] + (d.slot === 0 ? " (you)" : ""); $("n2").textContent = names[1] + (d.slot === 1 ? " (you)" : "");

  var html = "";
  for (var i = 0; i < 9; i++) {
    var v = d.board[i], cls = "cell" + (v === 1 ? " x" : v === 2 ? " o" : "") + (d.pendCell === i ? " pend" : "");
    html += "<button class='" + cls + "' onclick='pickCell(" + i + ")'>" + (v === 1 ? "&#10005;" : v === 2 ? "&#9675;" : "") + "</button>";
  }
  $("board").innerHTML = html;
  $("note").textContent = d.note;

  if (d.status === "finished") {
    clearInterval(timer); timer = null;
    $("arena").style.display = "none"; $("result").style.display = "block";
    var draw = d.winner === 2, won = d.winner === d.slot;
    $("rTitle").textContent = draw ? "Draw" : (won ? "Victory!" : "Defeat");
    $("rTitle").style.color = draw ? "#fcd34d" : (won ? "#34d399" : "#fb7185");
    $("rText").textContent = d.reason + (draw ? " (+50 points)" : won ? " (+100 points)" : " (+20 points)");
    return;
  }
  var mine = d.turn === slot;
  $("turn").textContent = mine ? (d.pq ? "Answer the question!" : "Your turn: choose a cell") : "Waiting for " + (d.turn === 0 ? names[0] : names[1]) + "...";
  $("turn").style.color = mine ? "#34d399" : "#fcd34d";

  if (d.pq) {
    $("qbox").style.display = "block";
    $("qtext").textContent = d.pq.text;
    $("tbar").style.width = Math.max(0, d.pq.left / 25 * 100) + "%";
    if (shownPQ !== d.pq.cell) {
      shownPQ = d.pq.cell;
      var box = $("opts"); box.innerHTML = "";
      d.pq.opts.forEach(function (v) {
        var b = document.createElement("button");
        b.className = "opt"; b.textContent = v; b.onclick = function () { reply(v); };
        box.appendChild(b);
      });
    }
  } else { $("qbox").style.display = "none"; shownPQ = -1; }
}
</script>
</body></html>
