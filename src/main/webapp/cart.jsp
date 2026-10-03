<%@ page contentType="text/html;charset=UTF-8" import="java.util.*,com.arcade.util.*,com.arcade.model.*" %>
<%@ include file="/WEB-INF/auth.jspf" %>
<%
  int uid = (Integer) session.getAttribute("userId");
  Set<Integer> cart = (Set<Integer>) session.getAttribute("cart");
  if (cart == null) cart = new HashSet<Integer>();
  int balance = StoreDAO.getBalance(uid);
  int total = 0;
  List<Product> inCart = new ArrayList<Product>();
  for (Product p : StoreDAO.getProducts()) if (cart.contains(p.id)) { inCart.add(p); total += p.price; }
  String err = request.getParameter("error");
%>
<!DOCTYPE html>
<html><head><title>Your Cart</title><%@ include file="/WEB-INF/head.jspf" %></head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="amazon-container" style="max-width:760px">
  <div class="amazon-card">
    <h2>Your Cart</h2>
    <p class="muted">Balance: <b style="color:var(--amber)"><%= balance %></b> biomass points</p>
    <% if (err != null) { %><p class="err" style="margin-top:8px"><%= err.replaceAll("[<>&\"]", "") %></p><% } %>
    <% if (inCart.isEmpty()) { %>
      <p style="margin-top:14px">Your cart is empty. <a href="store.jsp">Browse the store</a></p>
    <% } else { %>
      <table>
        <tr><th>Item</th><th>Price</th><th></th></tr>
        <% for (Product p : inCart) { %>
          <tr><td><%= p.name %></td><td><%= p.price %></td>
            <td><form action="cartAction" method="post" style="margin:0">
              <input type="hidden" name="action" value="remove"><input type="hidden" name="id" value="<%= p.id %>">
              <button class="btn-amazon-secondary" type="submit" style="padding:.3rem .9rem">Remove</button></form></td></tr>
        <% } %>
        <tr><th>Total</th><th><%= total %></th><th></th></tr>
      </table>
      <p>Balance after purchase: <b class="<%= balance - total >= 0 ? "ok" : "err" %>"><%= balance - total %></b></p>
      <div class="row" style="justify-content:flex-start">
        <form action="checkout" method="post"><button type="submit">Checkout</button></form>
        <form action="cartAction" method="post"><input type="hidden" name="action" value="clear"><button class="btn-amazon-secondary" type="submit">Clear cart</button></form>
      </div>
    <% } %>
  </div>
</div>
</body></html>
