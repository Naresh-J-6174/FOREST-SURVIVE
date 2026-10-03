package com.arcade.servlet;

import com.arcade.util.StoreDAO;
import java.io.IOException;
import java.util.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

// Shopping cart kept in the HTTP session (add / remove / clear)
@WebServlet("/cartAction")
public class CartServlet extends HttpServlet {
    @SuppressWarnings("unchecked")
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        HttpSession s = req.getSession(false);
        if (s == null || s.getAttribute("userId") == null) { res.sendRedirect("login.jsp"); return; }
        Set<Integer> cart = (Set<Integer>) s.getAttribute("cart");
        if (cart == null) { cart = new LinkedHashSet<Integer>(); s.setAttribute("cart", cart); }

        String action = req.getParameter("action");
        try {
            if ("clear".equals(action)) {
                cart.clear();
            } else {
                int id = Integer.parseInt(req.getParameter("id"));
                if ("add".equals(action)) {
                    boolean owned = StoreDAO.getOwned((Integer) s.getAttribute("userId")).containsKey(id);
                    if (!owned) cart.add(id);
                } else if ("remove".equals(action)) {
                    cart.remove(id);
                }
            }
        } catch (NumberFormatException e) {
            // ignore bad input
        } catch (RuntimeException e) {
            throw new ServletException(e);
        }
        res.sendRedirect("add".equals(action) ? "store.jsp" : "cart.jsp");
    }
}
