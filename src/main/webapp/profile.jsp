<%@ page contentType="text/html;charset=UTF-8" import="java.util.*,com.arcade.util.*" %>
<%@ include file="/WEB-INF/auth.jspf" %>
<%
  int uid = (Integer) session.getAttribute("userId");
  String user = (String) session.getAttribute("username");
  ProfileDAO.Stats st = ProfileDAO.get(uid);
  Map<String, Integer> prog = ProgressDAO.getAll(uid);
  String rankTitle = st.total < 100 ? "Seedling" : st.total < 500 ? "Explorer" : st.total < 1500 ? "Jungle Hunter" : "Apex Predator";
  String msg = request.getParameter("msg"), err = request.getParameter("error");
  String[][] gl = { {"amazon","Amazon Survival","5"}, {"duel","Snake Duel vs Bot","5"}, {"mathsnake","Math Snake","6"}, {"snake","Classic Snake","5"} };
  int cleared = 0; for (String[] g : gl) { Integer d = prog.get(g[0]); if (d != null) cleared += d; }
  Integer ama = prog.get("amazon"), dl = prog.get("duel");
  // badge: icon, name, how to earn, earned?
  Object[][] badges = {
    {"&#127807;", "First Steps", "Play your first game", st.games >= 1},
    {"&#128293;", "Veteran", "Play 10 games", st.games >= 10},
    {"&#11088;", "High Scorer", "Score 100 in one game", st.best >= 100},
    {"&#128176;", "Biomass Hoarder", "Earn 500 points in total", st.total >= 500},
    {"&#127795;", "Canopy Climber", "Clear Amazon level 3", ama != null && ama >= 3},
    {"&#129302;", "Bot Slayer", "Beat the bot once", dl != null && dl >= 1},
    {"&#127942;", "Level Master", "Clear 10 levels in total", cleared >= 10}
  };
%>
<!DOCTYPE html>
<html><head><title>Profile - Arcade Amazon</title><%@ include file="/WEB-INF/head.jspf" %></head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="amazon-container" style="max-width:860px">
  <div class="amazon-card">
    <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:10px">
      <div><h2><span style="font-size:1.8rem"><%= _em %></span> <span style="color:var(--em)"><%= user %></span></h2>
      <p class="muted">Rank title: <b><%= rankTitle %></b></p></div>
      <span class="badge-amazon amber">Global rank #<%= st.rank %></span>
    </div>
    <div class="stats">
      <div class="stat-box"><small>Games played</small><b><%= st.games %></b></div>
      <div class="stat-box"><small>Best score</small><b style="color:var(--amber)"><%= st.best %></b></div>
      <div class="stat-box"><small>Total points</small><b><%= st.total %></b></div>
      <div class="stat-box"><small>Store balance</small><b style="color:var(--cyan)"><%= st.balance %></b></div>
    </div>
    <% if (msg != null) { %><p class="ok"><%= msg.replaceAll("[<>&\"]", "") %></p><% } %>
    <% if (err != null) { %><p class="err"><%= err.replaceAll("[<>&\"]", "") %></p><% } %>
  </div>

  <div class="amazon-card">
    <h3>Level progress</h3>
    <table>
      <tr><th>Game</th><th>Levels cleared</th><th style="width:40%"></th></tr>
      <% for (String[] g : gl) { Integer d = prog.get(g[0]); int dd = d == null ? 0 : Math.min(d, Integer.parseInt(g[2])); int tt = Integer.parseInt(g[2]); %>
        <tr><td><%= g[1] %></td><td><%= dd %> / <%= tt %></td>
        <td><div class="bar" style="width:100%"><div style="width:<%= dd * 100 / tt %>%;background:var(--em)"></div></div></td></tr>
      <% } %>
    </table>
  </div>

  <div class="amazon-card">
    <h3>Badges</h3>
    <div class="badges">
    <% for (Object[] b : badges) { %>
      <div class="bdg <%= ((Boolean) b[3]) ? "on" : "" %>"><span style="font-size:1.4rem"><%= b[0] %></span><b><%= b[1] %></b><small><%= b[2] %></small></div>
    <% } %>
    </div>
  </div>

  <div class="amazon-card">
    <h3>Avatar <small class="muted">(saved in a cookie)</small></h3>
    <form action="profileAction" method="post" style="display:flex;gap:10px;flex-wrap:wrap;align-items:center;margin-top:10px">
      <input type="hidden" name="action" value="avatar">
      <select name="avatar" style="width:auto">
        <option value="snake">&#128013; Anaconda</option><option value="jaguar">&#128006; Jaguar</option>
        <option value="frog">&#128056; Dart frog</option><option value="parrot">&#129436; Macaw</option>
        <option value="monkey">&#128018; Howler monkey</option>
      </select>
      <button type="submit">Save avatar</button>
    </form>
  </div>

  <div class="amazon-card">
    <h3>Security settings</h3>
    <form action="profileAction" method="post" style="max-width:360px;margin-top:10px">
      <input type="hidden" name="action" value="password">
      <label>Current password</label><input type="password" name="oldPassword" required>
      <label>New password (min 4 characters)</label><input type="password" name="newPassword" required>
      <button type="submit" style="margin-top:8px">Change password</button>
    </form>
  </div>
</div>
</body></html>
