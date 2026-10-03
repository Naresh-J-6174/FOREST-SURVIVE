<%@ page contentType="text/html;charset=UTF-8" %>
<%
  String remembered = "";
  javax.servlet.http.Cookie[] cookies = request.getCookies();     // Experiment 4: read the cookie
  if (cookies != null) for (javax.servlet.http.Cookie c : cookies) if (c.getName().equals("rememberedUser")) remembered = c.getValue().replaceAll("[^A-Za-z0-9_]", "");
  String err = request.getParameter("error"), msg = request.getParameter("msg");
%>
<!DOCTYPE html>
<html><head><title>Login - Arcade Amazon</title><%@ include file="/WEB-INF/head.jspf" %></head>
<body>
<div class="amazon-card auth-box">
  <div class="center"><span class="amazon-brand" style="font-size:1.8rem">ARCADE<span>AMAZON</span></span>
  <p class="muted" style="margin:6px 0 16px">Survive the jungle with maths</p></div>
  <% if (err != null) { %><p class="err"><%= err.replaceAll("[<>&\"]", "") %></p><% } %>
  <% if (msg != null) { %><p class="ok"><%= msg.replaceAll("[<>&\"]", "") %></p><% } %>
  <form action="login" method="post">
    <input type="text" name="username" placeholder="Username" value="<%= remembered %>">
    <input type="password" name="password" placeholder="Password">
    <label style="display:block;margin:8px 0 14px"><input type="checkbox" name="remember" <%= remembered.isEmpty() ? "" : "checked" %>> Remember me</label>
    <button type="submit" style="width:100%">Enter the Amazon</button>
  </form>
  <p class="center muted" style="margin-top:14px">New explorer? <a href="register.jsp">Create an account</a></p>
</div>
</body></html>
