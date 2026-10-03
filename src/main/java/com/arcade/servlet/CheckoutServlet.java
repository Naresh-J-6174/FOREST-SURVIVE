package com.arcade.servlet;

import com.arcade.model.Product;
import com.arcade.util.StoreDAO;
import java.io.IOException;
import java.util.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

// Turns the session cart into a database order
@WebServlet("/checkout")
public class CheckoutServlet extends HttpServlet {
    @SuppressWarnings("unchecked")
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        HttpSession s = req.getSession(false);
        if (s == null || s.getAttribute("userId") == null) { res.sendRedirect("login.jsp"); return; }
        Set<Integer> cart = (Set<Integer>) s.getAttribute("cart");
        if (cart == null || cart.isEmpty()) { res.sendRedirect("cart.jsp?error=Your+cart+is+empty"); return; }
        int uid = (Integer) s.getAttribute("userId");

        try {
            Map<Integer, String> owned = StoreDAO.getOwned(uid);
            int total = 0;
            List<Integer> ids = new ArrayList<Integer>();
            for (int id : cart) {
                if (owned.containsKey(id)) continue;
                Product p = StoreDAO.getProduct(id);
                if (p != null) { total += p.price; ids.add(id); }
            }
            if (ids.isEmpty()) { res.sendRedirect("cart.jsp?error=Nothing+to+buy"); return; }
            if (total > StoreDAO.getBalance(uid)) {
                res.sendRedirect("cart.jsp?error=Not+enough+biomass+points.+Play+more+games!");
                return;
            }
            StoreDAO.createOrder(uid, total, ids);
            cart.clear();
            res.sendRedirect("store.jsp?msg=Purchase+complete!+Your+items+are+active+in+Amazon+Math+Survival.");
        } catch (RuntimeException e) {
            throw new ServletException(e);
        }
    }
}
