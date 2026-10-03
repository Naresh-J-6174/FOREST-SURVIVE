<%@ page contentType="text/html;charset=UTF-8" %>
<%@ include file="/WEB-INF/auth.jspf" %>
<!DOCTYPE html>
<html><head><title>Online Math Sprint</title><%@ include file="/WEB-INF/head.jspf" %></head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="amazon-container" style="max-width:820px">
 <div class="amazon-card gamebox online" id="gamebox"><button class="btn-amazon-secondary fs-btn" onclick="Arcade.toggleFull()">Fullscreen</button>
  <div class="center">
    <span class="badge-amazon cyan">LIVE 1v1</span>
    <h2 style="margin-top:8px">Online Math Sprint</h2>
    <p class="muted">Two real players get the same 10 questions. First to answer all 10 correctly wins. A wrong answer freezes you for 1.5 seconds.</p>
  </div>

  <div id="lobby" class="center" style="margin:26px 0">
    <button id="findBtn" onclick="findMatch()">Find opponent</button>
    <p id="lobbyMsg" class="muted" style="margin-top:12px">Open this page in a second browser (or another PC) with a different account to play yourself.</p>
  </div>

  <div id="arena" style="display:none">
    <div class="arena">
      <div class="duel-box"><h3 style="color:var(--em)" id="n1">You</h3><div class="pbar"><div id="b1"></div></div><b id="s1" style="font-size:1.3rem">0 / 10</b></div>
      <div class="duel-box"><h3 style="color:var(--rose)" id="n2">Opponent</h3><div class="pbar"><div id="b2" style="background:var(--rose)"></div></div><b id="s2" style="font-size:1.3rem">0 / 10</b></div>
    </div>
    <div class="center" style="margin-top:20px;background:rgba(0,0,0,.35);padding:22px;border-radius:12px">
      <div class="quest" id="q" style="font-size:2rem">&nbsp;</div>
      <div id="opts" class="row"></div>
      <div id="msg"></div>
    </div>
    <div class="center" style="margin-top:12px"><button class="btn-amazon-secondary" onclick="leave()">Leave match</button></div>
  </div>

  <div id="result" class="center" style="display:none;margin-top:20px">
    <h1 id="rTitle"></h1><p id="rText" class="muted"></p>
    <div class="row"><button onclick="location.reload()">Play again</button><a class="btn-amazon btn-amazon-secondary" href="../index.jsp">Back to hub</a></div>
  </div>
 </div>
</div>
<script>
var room = null, slot = 0, timer = null, shownQ = -1, locked = false;
function $(id) { return document.getElementById(id); }

function findMatch() {
  Arcade.goFull();
  $("findBtn").disabled = true;
  $("lobbyMsg").textContent = "Searching for an opponent...";
  Arcade.json("POST", "/match", "action=join&game=sprint", function (s, d) {
    if (!d || d.error) { $("lobbyMsg").textContent = "Could not join: " + (d ? d.error : "server error"); $("findBtn").disabled = false; return; }
    room = d.room; slot = d.slot;
    render(d);
    if (!timer) timer = setInterval(poll, 700);            // AJAX polling = "live" updates
  });
}
function poll() {
  Arcade.json("GET", "/match?action=state&room=" + room, null, function (s, d) { if (d && !d.error) render(d); });
}
function leave() {
  Arcade.json("POST", "/match", "action=leave&room=" + room, function (s, d) { if (d) render(d); });
}

function render(d) {
  if (d.status === "waiting") { $("lobbyMsg").textContent = "Waiting for another explorer to join the room..."; return; }
  if (d.status === "finished" && d.winner === -1) {
    clearInterval(timer); timer = null;
    $("lobbyMsg").textContent = d.reason; $("findBtn").disabled = false; $("lobby").style.display = "block"; $("arena").style.display = "none"; return;
  }
  $("lobby").style.display = "none"; $("arena").style.display = "block";
  $("n1").textContent = d.you + " (you)"; $("n2").textContent = d.opp;
  var me = d.scores[d.slot], op = d.scores[1 - d.slot];
  $("s1").textContent = me + " / " + d.total; $("s2").textContent = op + " / " + d.total;
  $("b1").style.width = me / d.total * 100 + "%"; $("b2").style.width = op / d.total * 100 + "%";
  if (d.status === "finished") {
    clearInterval(timer); timer = null;
    $("arena").style.display = "none"; $("result").style.display = "block";
    var won = d.winner === d.slot;
    $("rTitle").textContent = won ? "Victory!" : "Defeat"; $("rTitle").style.color = won ? "#34d399" : "#fb7185";
    $("rText").textContent = d.reason + (won ? "  (+100 points)" : "  (consolation points saved)");
    return;
  }
  if (d.result === "wrong") { locked = true; $("msg").textContent = "Wrong! Frozen for 1.5 seconds..."; $("msg").style.color = "#fb7185"; }
  if (d.q && d.q.i !== shownQ) {                              // build buttons only when the question changes
    shownQ = d.q.i;
    $("q").textContent = (d.q.i + 1) + ".  " + d.q.text;
    var box = $("opts"); box.innerHTML = "";
    d.q.opts.forEach(function (v) {
      var b = document.createElement("button");
      b.className = "opt"; b.textContent = v;
      b.onclick = function () { answer(d.q.i, v); };
      box.appendChild(b);
    });
    if (d.result === "correct") { $("msg").textContent = "Correct!"; $("msg").style.color = "#34d399"; }
  }
  var lockNow = locked || d.lockMs > 0;
  var btns = $("opts").getElementsByTagName("button");
  for (var i = 0; i < btns.length; i++) btns[i].disabled = lockNow;
  if (locked) setTimeout(function () { locked = false; $("msg").textContent = ""; var bs = $("opts").getElementsByTagName("button"); for (var j = 0; j < bs.length; j++) bs[j].disabled = false; }, 1500);
}
function answer(i, v) {
  Arcade.json("POST", "/match", "action=answer&room=" + room + "&index=" + i + "&choice=" + v, function (s, d) { if (d && !d.error) render(d); });
}
</script>
</body></html>
