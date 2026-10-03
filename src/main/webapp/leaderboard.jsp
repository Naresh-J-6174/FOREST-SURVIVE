<%@ page contentType="text/html;charset=UTF-8" %>
<%@ include file="/WEB-INF/auth.jspf" %>
<!DOCTYPE html>
<html><head><title>Leaderboard</title><%@ include file="/WEB-INF/head.jspf" %></head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="amazon-container" style="max-width:760px">
  <div class="amazon-card">
    <h2>Leaderboard</h2>
    <p class="muted">Loaded as XML from the server, then built into a table in your browser.</p>
    <select id="game" onchange="load()" style="margin-top:12px">
      <option value="amazon">Amazon Rainforest Survival</option>
      <option value="duel">Snake Duel vs Bot</option>
      <option value="mathsnake">Math Snake</option>
      <option value="snake">Classic Snake</option>
      <option value="sprint">Online Math Sprint</option>
      <option value="tictac">Jungle Tic-Tac-Math</option>
    </select>
    <div id="board">Loading...</div>
  </div>
</div>
<script>
// Experiment 7: XML from the server -> HTML table on the client
function load() {
  var game = document.getElementById("game").value;
  var xhr = new XMLHttpRequest();
  xhr.onreadystatechange = function () {
    if (xhr.readyState !== 4) return;
    var players = xhr.responseXML ? xhr.responseXML.getElementsByTagName("player") : [];
    var html = "<table><tr><th>Rank</th><th>Player</th><th>Best score</th></tr>";
    for (var i = 0; i < players.length; i++) {
      html += "<tr><td>" + players[i].getElementsByTagName("rank")[0].textContent +
              "</td><td>" + players[i].getElementsByTagName("name")[0].textContent +
              "</td><td>" + players[i].getElementsByTagName("score")[0].textContent + "</td></tr>";
    }
    document.getElementById("board").innerHTML = players.length ? html + "</table>" : "<p class='muted' style='margin-top:12px'>No scores yet. Go play!</p>";
  };
  xhr.open("GET", ARCADE_CTX + "/leaderboard?game=" + encodeURIComponent(game), true);
  xhr.send();
}
load();
</script>
</body></html>
