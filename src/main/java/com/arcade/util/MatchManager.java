package com.arcade.util;

import java.util.*;

/**
 * Server-side state for the two online 1v1 games:
 *   "sprint" - race to 10 correct answers
 *   "tictac" - tic-tac-toe where each cell must be won by solving a maths question
 * Rooms live in memory. Clients poll /match?action=state every ~0.7 s (AJAX).
 */
public class MatchManager {
    static final int TOTAL = 10;
    private static final long GONE_MS = 15000;      // no poll for this long = player left
    private static final long WAIT_MS = 30000;      // waiting room expires
    private static final long PEND_MS = 25000;      // time limit to answer a tic-tac question
    private static final int[][] LINES = {{0,1,2},{3,4,5},{6,7,8},{0,3,6},{1,4,7},{2,5,8},{0,4,8},{2,4,6}};
    private static final Map<String, Room> rooms = new HashMap<String, Room>();
    private static int counter = 0;

    public static class Room {
        public String id, game, status = "waiting", reason = "", note = "";
        public String[] names = new String[2];
        public int[] uids = new int[2];
        public long[] seen = new long[2];
        public long created, ended;
        public int winner = -1;                     // 0 / 1 = slot, 2 = draw
        // sprint
        public int[] progress = new int[2];
        public long[] lock = new long[2];
        public String[] qText = new String[TOTAL];
        public int[] qAns = new int[TOTAL];
        public int[][] qOpts = new int[TOTAL][];
        // tic-tac-math
        public int[] board = new int[9];
        public int turn = 0, pendCell = -1, pendAns, moves = 0;
        public String pendText;
        public int[] pendOpts;
        public long pendStart;
    }

    // ---------- matchmaking ----------
    public static synchronized Room join(String game, int uid, String name) {
        long now = System.currentTimeMillis();
        cleanup(now);
        for (Room r : rooms.values()) {                          // re-join a running match
            if (!r.game.equals(game)) continue;
            check(r, now);
            if (r.status.equals("finished")) continue;
            if (name.equals(r.names[0]) || name.equals(r.names[1])) return r;
        }
        for (Room r : rooms.values()) {                          // join someone who is waiting
            if (r.game.equals(game) && r.status.equals("waiting") && r.names[0] != null && !name.equals(r.names[0])) {
                r.names[1] = name;
                r.uids[1] = uid;
                start(r, now);
                return r;
            }
        }
        Room r = new Room();                                     // otherwise open a new room
        r.id = "R" + (++counter);
        r.game = game;
        r.names[0] = name;
        r.uids[0] = uid;
        r.created = now;
        r.seen[0] = now;
        rooms.put(r.id, r);
        return r;
    }

    public static synchronized Room find(String id) { return id == null ? null : rooms.get(id); }

    public static int slotOf(Room r, String name) {
        if (name.equals(r.names[0])) return 0;
        if (name.equals(r.names[1])) return 1;
        return -1;
    }

    private static void cleanup(long now) {
        Iterator<Room> it = rooms.values().iterator();
        while (it.hasNext()) {
            Room r = it.next();
            if ((r.status.equals("finished") && now - r.ended > 120000) || now - r.created > 3600000) it.remove();
        }
    }

    private static void start(Room r, long now) {
        r.status = "playing";
        r.seen[0] = now;
        r.seen[1] = now;
        if (r.game.equals("sprint")) {
            int[] tiers = {1, 1, 1, 2, 2, 2, 2, 3, 3, 3};
            for (int i = 0; i < TOTAL; i++) {
                MathGen.Q q = MathGen.make(tiers[i]);
                r.qText[i] = q.text;
                r.qAns[i] = q.answer;
                r.qOpts[i] = q.opts;
            }
            r.note = "Go! First to " + TOTAL + " correct answers wins.";
        } else {
            r.note = "Pick a cell and solve the question to claim it.";
        }
    }

    // forfeits and time limits are evaluated lazily on every access
    private static void check(Room r, long now) {
        if (r.status.equals("playing")) {
            for (int s = 0; s < 2; s++) {
                if (now - r.seen[s] > GONE_MS) { finish(r, 1 - s, r.names[s] + " left the match"); return; }
            }
            if (r.game.equals("tictac") && r.pendCell >= 0 && now - r.pendStart > PEND_MS) {
                r.note = r.names[r.turn] + " ran out of time and lost the turn.";
                r.pendCell = -1;
                r.turn = 1 - r.turn;
            }
        } else if (r.status.equals("waiting") && now - r.seen[0] > WAIT_MS) {
            r.status = "finished";
            r.reason = "No opponent found. Try again.";
            r.ended = now;
        }
    }

    // ---------- sprint ----------
    public static synchronized String answerSprint(Room r, int slot, int index, int choice) {
        long now = System.currentTimeMillis();
        check(r, now);
        if (!r.status.equals("playing") || !r.game.equals("sprint")) return "";
        if (index != r.progress[slot] || index >= TOTAL) return "";
        if (now < r.lock[slot]) return "locked";
        if (choice == r.qAns[index]) {
            r.progress[slot]++;
            if (r.progress[slot] >= TOTAL) finish(r, slot, r.names[slot] + " reached " + TOTAL + " correct answers first!");
            return "correct";
        }
        r.lock[slot] = now + 1500;
        return "wrong";
    }

    // ---------- tic-tac-math ----------
    public static synchronized String pick(Room r, int slot, int cell) {
        long now = System.currentTimeMillis();
        check(r, now);
        if (!r.status.equals("playing") || !r.game.equals("tictac") || r.turn != slot || r.pendCell >= 0) return "";
        if (cell < 0 || cell > 8 || r.board[cell] != 0) return "";
        MathGen.Q q = MathGen.make(Math.min(3, 1 + r.moves / 3));
        r.pendCell = cell;
        r.pendText = q.text;
        r.pendAns = q.answer;
        r.pendOpts = q.opts;
        r.pendStart = now;
        r.note = r.names[slot] + " is trying to claim a cell...";
        return "question";
    }

    public static synchronized String reply(Room r, int slot, int choice) {
        long now = System.currentTimeMillis();
        check(r, now);
        if (!r.status.equals("playing") || !r.game.equals("tictac") || r.turn != slot || r.pendCell < 0) return "";
        boolean ok = choice == r.pendAns;
        int cell = r.pendCell;
        r.pendCell = -1;
        if (ok) {
            r.board[cell] = slot + 1;
            r.moves++;
            r.note = r.names[slot] + " claimed a cell!";
            if (hasLine(r.board, slot + 1)) { finish(r, slot, r.names[slot] + " got three in a row!"); return "correct"; }
            if (r.moves >= 9) { finish(r, 2, "The board is full: it is a draw."); return "correct"; }
        } else {
            r.note = r.names[slot] + " answered wrong and lost the turn.";
        }
        r.turn = 1 - r.turn;
        return ok ? "correct" : "wrong";
    }

    private static boolean hasLine(int[] b, int who) {
        for (int[] l : LINES) if (b[l[0]] == who && b[l[1]] == who && b[l[2]] == who) return true;
        return false;
    }

    public static synchronized void leave(Room r, int slot) {
        long now = System.currentTimeMillis();
        if (r.status.equals("playing")) finish(r, 1 - slot, r.names[slot] + " left the match");
        else if (r.status.equals("waiting")) { r.status = "finished"; r.reason = "Search cancelled."; r.ended = now; }
    }

    // ---------- finishing + saving scores in MongoDB ----------
    private static void finish(Room r, int winner, String reason) {
        r.status = "finished";
        r.winner = winner;
        r.reason = reason;
        r.ended = System.currentTimeMillis();
        for (int s = 0; s < 2; s++) {
            if (r.names[s] == null) continue;
            int pts;
            if (winner == 2) pts = 50;
            else if (winner == s) pts = 100;
            else pts = r.game.equals("sprint") ? 10 + 5 * r.progress[s] : 20;
            try {
                DBUtil.addScore(r.uids[s], r.game, pts);
            } catch (RuntimeException e) {
                e.printStackTrace();
            }
        }
    }

    // ---------- JSON for the browser (hand-built, no library needed) ----------
    public static synchronized String state(Room r, int slot, String result) {
        long now = System.currentTimeMillis();
        r.seen[slot] = now;
        check(r, now);
        int opp = 1 - slot;
        StringBuilder sb = new StringBuilder("{");
        sb.append("\"room\":\"").append(r.id).append("\",\"game\":\"").append(r.game)
          .append("\",\"status\":\"").append(r.status).append("\",\"slot\":").append(slot)
          .append(",\"you\":\"").append(esc(r.names[slot])).append("\",\"opp\":\"").append(esc(r.names[opp] == null ? "" : r.names[opp]))
          .append("\",\"winner\":").append(r.winner).append(",\"reason\":\"").append(esc(r.reason))
          .append("\",\"note\":\"").append(esc(r.note)).append("\",\"result\":\"").append(result == null ? "" : result).append("\"");
        if (r.game.equals("sprint")) {
            sb.append(",\"total\":").append(TOTAL).append(",\"scores\":[").append(r.progress[0]).append(",").append(r.progress[1]).append("]");
            if (r.status.equals("playing") && r.progress[slot] < TOTAL) {
                int i = r.progress[slot];
                sb.append(",\"q\":{\"i\":").append(i).append(",\"text\":\"").append(esc(r.qText[i])).append("\",\"opts\":").append(arr(r.qOpts[i])).append("}");
                sb.append(",\"lockMs\":").append(Math.max(0, r.lock[slot] - now));
            }
        } else {
            sb.append(",\"board\":").append(arr(r.board)).append(",\"turn\":").append(r.turn).append(",\"pendCell\":").append(r.pendCell);
            if (r.pendCell >= 0 && r.turn == slot) {
                long left = Math.max(0, (PEND_MS - (now - r.pendStart)) / 1000);
                sb.append(",\"pq\":{\"cell\":").append(r.pendCell).append(",\"text\":\"").append(esc(r.pendText))
                  .append("\",\"opts\":").append(arr(r.pendOpts)).append(",\"left\":").append(left).append("}");
            }
        }
        return sb.append("}").toString();
    }

    private static String arr(int[] a) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < a.length; i++) { if (i > 0) sb.append(","); sb.append(a[i]); }
        return sb.append("]").toString();
    }

    private static String esc(String s) {
        return s == null ? "" : s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
