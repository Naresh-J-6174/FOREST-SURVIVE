<%@ page contentType="text/html;charset=UTF-8" %>
<% String err = request.getParameter("error"); %>
<!DOCTYPE html>
<html><head><title>Register - Arcade Amazon</title><%@ include file="/WEB-INF/head.jspf" %>
<script src="js/validate.js"></script></head>
<body>
<div class="amazon-card auth-box">
  <div class="center"><span class="amazon-brand" style="font-size:1.6rem">NEW<span>EXPLORER</span></span></div>
  <% if (err != null) { %><p class="err" style="margin-top:10px"><%= err.replaceAll("[<>&\"]", "") %></p><% } %>
  <form action="register" method="post" onsubmit="return validateRegister()" style="margin-top:14px">
    <input type="text" id="username" name="username" placeholder="Username (3-20 letters, digits, _)" onkeyup="checkUsername()">
    <small id="status" data-state=""></small>
    <input type="password" id="password" name="password" placeholder="Password (min 4 characters)">
    <button type="submit" style="width:100%;margin-top:10px">Create profile</button>
  </form>
  <p class="center muted" style="margin-top:14px"><a href="login.jsp">&larr; Back to login</a></p>
</div>
</body></html>
