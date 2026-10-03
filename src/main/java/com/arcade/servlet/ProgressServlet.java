package com.arcade.servlet;

import com.arcade.util.ProgressDAO;
import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

// AJAX: GET = how many levels has this player cleared, POST = record a cleared level
@WebServlet("/progress")
public class ProgressServlet extends HttpServlet {
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        res.setContentType("text/plain");
        HttpSession s = req.getSession(false);
        String game = req.getParameter("game");
        if (s == null || s.getAttribute("userId") == null) { res.setStatus(401); return; }
        if (game == null || !game.matches("[a-z0-9_]{1,30}")) { res.setStatus(400); return; }
        try {
            res.getWriter().print(ProgressDAO.get((Integer) s.getAttribute("userId"), game));
        } catch (RuntimeException e) {
            throw new ServletException(e);
        }
    }

    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        res.setContentType("text/plain");
        HttpSession s = req.getSession(false);
        String game = req.getParameter("game");
        if (s == null || s.getAttribute("userId") == null) { res.setStatus(401); return; }
        try {
            int level = Integer.parseInt(req.getParameter("level"));
            if (game == null || !game.matches("[a-z0-9_]{1,30}") || level < 1 || level > 20) { res.setStatus(400); return; }
            ProgressDAO.complete((Integer) s.getAttribute("userId"), game, level);
            res.getWriter().print("ok");
        } catch (NumberFormatException e) {
            res.setStatus(400);
        } catch (RuntimeException e) {
            throw new ServletException(e);
        }
    }
}
