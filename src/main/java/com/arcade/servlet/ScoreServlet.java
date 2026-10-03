package com.arcade.servlet;

import com.arcade.util.DBUtil;
import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

// AJAX endpoint: save a score for the logged-in player
@WebServlet("/saveScore")
public class ScoreServlet extends HttpServlet {
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        res.setContentType("text/plain");
        HttpSession s = req.getSession(false);
        if (s == null || s.getAttribute("userId") == null) {
            res.setStatus(401);
            res.getWriter().print("not logged in");
            return;
        }
        try {
            String game = req.getParameter("game");
            if (game == null || !game.matches("[A-Za-z0-9_]{1,30}")) throw new NumberFormatException("bad game");
            DBUtil.addScore((Integer) s.getAttribute("userId"), game, Integer.parseInt(req.getParameter("score")));
            res.getWriter().print("saved");
        } catch (RuntimeException e) {
            res.setStatus(400);
            res.getWriter().print("error");
        }
    }
}
