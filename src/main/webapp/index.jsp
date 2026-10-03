<%@ page contentType="text/html;charset=UTF-8" import="java.util.*,com.arcade.util.*" %>
<%@ include file="/WEB-INF/auth.jspf" %>
<%
  int uid = (Integer) session.getAttribute("userId");
  String user = (String) session.getAttribute("username");
  Map<String, Integer> prog = ProgressDAO.getAll(uid);
  String lv = (String) session.getAttribute("lastVisit");          // from the lastVisit cookie
  String lastText = "Welcome, this is your first visit!";
  if (lv != null) { try { lastText = "Your last visit: " + new java.util.Date(Long.parseLong(lv)); } catch (Exception e) { } }
  // code, title, badge text, badge style, description, link, number of levels (0 = online)
  String[][] games = {
    {"amazon", "Amazon Rainforest Survival", "SURVIVAL", "", "Hunt the prey with the right answer and solve sums to scare off jaguars and caimans.", "games/amazon.jsp", "5"},
    {"duel", "Snake Duel: You vs Bot", "AI BOT DUEL", "rose", "Race a clever Crimson Viper to eat the correct answers first.", "games/duel.jsp", "5"},
    {"mathsnake", "Math Snake", "MATHS", "amber", "Each level trains one skill: add, subtract, times, divide, squares, order of operations.", "games/mathsnake.jsp", "6"},
    {"snake", "Classic Snake", "CLASSIC", "amber", "Eat the berries, dodge rocks, and clear faster and faster levels.", "games/snake.jsp", "5"},
    {"sprint", "Online Math Sprint", "LIVE 1v1", "cyan", "Real-time race against another player: first to 10 correct answers wins.", "games/sprint.jsp", "0"},
    {"tictac", "Jungle Tic-Tac-Math", "LIVE 1v1", "cyan", "Claim a cell by solving a question. Get three in a row to beat your rival.", "games/tictac.jsp", "0"}
  };
%>
<!DOCTYPE html>
<html><head><title>Arcade Amazon</title><%@ include file="/WEB-INF/head.jspf" %></head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="amazon-container">
  <div class="amazon-card">
    <h1>Amazon Mathematical Arena</h1>
    <p class="muted" style="margin-top:6px">Welcome, <b style="color:var(--em)"><%= user %></b>. <%= lastText %></p>
    <p class="muted">Clear levels, beat the bot, or duel another explorer live. Spend your points in the <a href="store.jsp">Store</a>.</p>
  </div>
  <div class="grid">
  <% for (String[] g : games) {
       int total = Integer.parseInt(g[6]);
       Integer done = prog.get(g[0]); if (done == null) done = 0; %>
    <div class="game-item">
      <div>
        <span class="badge-amazon <%= g[3] %>"><%= g[2] %></span>
        <h3><%= g[1] %></h3>
        <p><%= g[4] %></p>
        <% if (total > 0) { %>
          <p style="margin-top:10px">Levels cleared: <b><%= Math.min(done, total) %> / <%= total %></b></p>
          <div class="bar" style="width:100%"><div style="width:<%= Math.min(100, done * 100 / total) %>%;background:var(--em)"></div></div>
        <% } %>
      </div>
      <a href="<%= g[5] %>" class="btn-amazon center"><%= total > 0 ? "Play" : "Find opponent" %></a>
    </div>
  <% } %>
  </div>
</div>
</body></html>
