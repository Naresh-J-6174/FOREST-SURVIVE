package com.arcade.servlet;

import com.arcade.util.MatchManager;
import com.arcade.util.MatchManager.Room;
import java.io.IOException;
import java.io.PrintWriter;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

// AJAX endpoint for the two online 1v1 games. Always answers with JSON.
@WebServlet("/match")
public class MatchServlet extends HttpServlet {
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws IOException { handle(req, res); }
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws IOException { handle(req, res); }

    private void handle(HttpServletRequest req, HttpServletResponse res) throws IOException {
        res.setContentType("application/json;charset=UTF-8");
        PrintWriter out = res.getWriter();
        HttpSession s = req.getSession(false);
        if (s == null || s.getAttribute("userId") == null) {
            res.setStatus(401);
            out.print("{\"error\":\"login required\"}");
            return;
        }
        String name = (String) s.getAttribute("username");
        int uid = (Integer) s.getAttribute("userId");
        String a = req.getParameter("action");
        if (a == null) a = "";
        try {
            if (a.equals("join")) {
                String g = req.getParameter("game");
                if (!"sprint".equals(g) && !"tictac".equals(g)) { out.print("{\"error\":\"unknown game\"}"); return; }
                Room r = MatchManager.join(g, uid, name);
                out.print(MatchManager.state(r, MatchManager.slotOf(r, name), ""));
                return;
            }
            Room r = MatchManager.find(req.getParameter("room"));
            int slot = r == null ? -1 : MatchManager.slotOf(r, name);
            if (slot < 0) { out.print("{\"error\":\"no such room\"}"); return; }
            String result = "";
            if (a.equals("answer")) {
                result = MatchManager.answerSprint(r, slot, Integer.parseInt(req.getParameter("index")), Integer.parseInt(req.getParameter("choice")));
            } else if (a.equals("pick")) {
                result = MatchManager.pick(r, slot, Integer.parseInt(req.getParameter("cell")));
            } else if (a.equals("reply")) {
                result = MatchManager.reply(r, slot, Integer.parseInt(req.getParameter("choice")));
            } else if (a.equals("leave")) {
                MatchManager.leave(r, slot);
            }
            out.print(MatchManager.state(r, slot, result));
        } catch (NumberFormatException e) {
            out.print("{\"error\":\"bad number\"}");
        }
    }
}
