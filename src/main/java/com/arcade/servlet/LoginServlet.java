package com.arcade.servlet;

import com.arcade.util.UserDAO;
import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        String u = req.getParameter("username");
        String p = req.getParameter("password");
        if (u == null) { res.sendRedirect("login.jsp?error=Wrong+username+or+password"); return; }
        try {
            Integer uid = UserDAO.login(u, p);
            if (uid != null) {
                // SESSION management
                HttpSession session = req.getSession(true);
                session.setAttribute("userId", uid);
                session.setAttribute("username", u);
                session.setMaxInactiveInterval(30 * 60);

                // COOKIE 1: remember username for 7 days
                boolean remember = "on".equals(req.getParameter("remember"));
                Cookie ck = new Cookie("rememberedUser", remember ? u : "");
                ck.setMaxAge(remember ? 7 * 24 * 3600 : 0);
                res.addCookie(ck);

                // COOKIE 2: last visit time (old value goes into the session so index.jsp can show it)
                String prev = null;
                Cookie[] all = req.getCookies();
                if (all != null) for (Cookie k : all) if (k.getName().equals("lastVisit")) prev = k.getValue();
                session.setAttribute("lastVisit", prev);
                Cookie lv = new Cookie("lastVisit", String.valueOf(System.currentTimeMillis()));
                lv.setMaxAge(30 * 24 * 3600);
                res.addCookie(lv);

                res.sendRedirect("index.jsp");
            } else {
                res.sendRedirect("login.jsp?error=Wrong+username+or+password");
            }
        } catch (RuntimeException e) {
            throw new ServletException(e);
        }
    }
}
