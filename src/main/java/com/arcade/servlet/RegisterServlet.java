package com.arcade.servlet;

import com.arcade.db.DuplicateUserException;
import com.arcade.util.UserDAO;
import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/register")
public class RegisterServlet extends HttpServlet {
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        String u = req.getParameter("username");
        String p = req.getParameter("password");
        if (u == null || p == null || !u.matches("[A-Za-z0-9_]{3,20}") || p.length() < 4) {
            res.sendRedirect("register.jsp?error=Invalid+input");
            return;
        }
        try {
            UserDAO.register(u, p);
            res.sendRedirect("login.jsp?msg=Registered.+Please+login");
        } catch (DuplicateUserException e) {
            res.sendRedirect("register.jsp?error=Username+taken");
        } catch (RuntimeException e) {
            throw new ServletException(e);
        }
    }
}
