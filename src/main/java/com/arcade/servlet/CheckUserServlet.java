package com.arcade.servlet;

import com.arcade.util.UserDAO;
import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

// AJAX endpoint: is this username free?
@WebServlet("/checkUser")
public class CheckUserServlet extends HttpServlet {
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        res.setContentType("text/plain");
        String u = req.getParameter("username");
        if (u == null) { res.getWriter().print("available"); return; }
        try {
            res.getWriter().print(UserDAO.exists(u) ? "taken" : "available");
        } catch (RuntimeException e) {
            throw new ServletException(e);
        }
    }
}
