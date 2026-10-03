package com.arcade.servlet;

import com.arcade.util.UserDAO;
import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

// Profile settings: change password (hashed, old password required) and choose an avatar (cookie)
@WebServlet("/profileAction")
public class ProfileServlet extends HttpServlet {
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        HttpSession s = req.getSession(false);
        if (s == null || s.getAttribute("userId") == null) { res.sendRedirect("login.jsp"); return; }
        int uid = (Integer) s.getAttribute("userId");
        String action = req.getParameter("action");

        if ("avatar".equals(action)) {
            String a = req.getParameter("avatar");
            if (a != null && a.matches("snake|jaguar|frog|parrot|monkey")) {
                Cookie c = new Cookie("avatar", a);
                c.setMaxAge(365 * 24 * 3600);
                res.addCookie(c);
            }
            res.sendRedirect("profile.jsp?msg=Avatar+saved");
            return;
        }

        if ("password".equals(action)) {
            String oldp = req.getParameter("oldPassword");
            String newp = req.getParameter("newPassword");
            if (newp == null || newp.length() < 4) { res.sendRedirect("profile.jsp?error=New+password+must+have+at+least+4+characters"); return; }
            try {
                if (!UserDAO.checkPassword(uid, oldp)) { res.sendRedirect("profile.jsp?error=Current+password+is+wrong"); return; }
                UserDAO.changePassword(uid, newp);
            } catch (RuntimeException e) {
                throw new ServletException(e);
            }
            res.sendRedirect("profile.jsp?msg=Password+updated");
            return;
        }
        res.sendRedirect("profile.jsp");
    }
}
