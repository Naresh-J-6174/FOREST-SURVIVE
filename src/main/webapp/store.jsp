<%@ page contentType="text/html;charset=UTF-8" import="java.util.*,com.arcade.util.*,com.arcade.model.*" %>
<%@ include file="/WEB-INF/auth.jspf" %>
<%
  int uid = (Integer) session.getAttribute("userId");
  List<Product> products = StoreDAO.getProducts();
  int balance = StoreDAO.getBalance(uid);
  Map<Integer, String> owned = StoreDAO.getOwned(uid);
  Set<Integer> cart = (Set<Integer>) session.getAttribute("cart");
  if (cart == null) cart = new HashSet<Integer>();
  String msg = request.getParameter("msg");
%>
<!DOCTYPE html>
<html><head><title>Biosphere Store</title><%@ include file="/WEB-INF/head.jspf" %></head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="amazon-container">
  <div class="amazon-card">
    <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:10px">
      <h2>Amazon Biosphere Store</h2>
      <div><span class="badge-amazon amber"><%= balance %> biomass points</span> &nbsp; <a href="cart.jsp" class="btn-amazon btn-amazon-secondary" style="padding:.4rem 1rem">Cart (<%= cart.size() %>)</a></div>
    </div>
    <p class="muted" style="margin-top:6px">Points = all your game scores minus what you spent. Items unlock in Amazon Rainforest Survival.</p>
    <% if (msg != null) { %><p class="ok" style="margin-top:8px"><%= msg.replaceAll("[<>&\"]", "") %></p><% } %>
    <div class="grid">
    <% for (Product p : products) {
         boolean has = owned.containsKey(p.id), inCart = cart.contains(p.id); %>
      <div class="game-item">
        <div><h3><%= p.name %></h3><p><%= p.description %></p>
        <p style="color:var(--amber);font-weight:700;font-size:1.1rem"><%= p.price %> pts</p></div>
        <% if (has) { %><span class="ok"><b>&#10004; Owned</b></span>
        <% } else if (inCart) { %><span class="muted">In your cart</span>
        <% } else { %>
          <form action="cartAction" method="post">
            <input type="hidden" name="action" value="add"><input type="hidden" name="id" value="<%= p.id %>">
            <button type="submit">Add to cart</button>
          </form>
        <% } %>
      </div>
    <% } %>
    </div>
  </div>
</div>
</body></html>
