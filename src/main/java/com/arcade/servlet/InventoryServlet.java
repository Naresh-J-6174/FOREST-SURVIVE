package com.arcade.servlet;

import com.arcade.util.StoreDAO;
import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

// AJAX endpoint: which store items does the player own? e.g. "elixir,hint"
@WebServlet("/inventory")
public class InventoryServlet extends HttpServlet {
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        res.setContentType("text/plain");
        HttpSession s = req.getSession(false);
        if (s == null || s.getAttribute("userId") == null) { res.setStatus(401); return; }
        try {
            res.getWriter().print(String.join(",", StoreDAO.getOwned((Integer) s.getAttribute("userId")).values()));
        } catch (RuntimeException e) {
            throw new ServletException(e);
        }
    }
}
