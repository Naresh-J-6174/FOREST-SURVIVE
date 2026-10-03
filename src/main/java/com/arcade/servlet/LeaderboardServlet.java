package com.arcade.servlet;

import com.arcade.util.DBUtil;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

// Returns top 10 scores as an XML document (client turns it into an HTML table)
@WebServlet("/leaderboard")
public class LeaderboardServlet extends HttpServlet {
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        res.setContentType("text/xml;charset=UTF-8");
        String game = req.getParameter("game");
        if (game == null) game = "snake";
        try {
            List<String[]> rows = DBUtil.store().leaderboard(game, 10);
            PrintWriter out = res.getWriter();
            out.print("<?xml version=\"1.0\" encoding=\"UTF-8\"?><leaderboard game=\"" + game.replaceAll("[^A-Za-z0-9_]", "") + "\">");
            int rank = 1;
            for (String[] r : rows) {
                out.print("<player><rank>" + rank++ + "</rank><name>" + r[0] + "</name><score>" + r[1] + "</score></player>");
            }
            out.print("</leaderboard>");
        } catch (RuntimeException e) {
            throw new ServletException(e);
        }
    }
}
