package com.arcade.util;

import java.util.*;

// Server-side maths question generator (used by the online games so players cannot cheat)
public class MathGen {
    public static class Q {
        public String text;
        public int answer;
        public int[] opts;
    }

    private static final Random R = new Random();

    private static int rnd(int a, int b) { return a + R.nextInt(b - a + 1); }

    public static Q make(int tier) {
        String q;
        int a, x, y, z;
        if (tier <= 1) {
            if (R.nextBoolean()) { x = rnd(5, 30); y = rnd(5, 30); q = x + " + " + y; a = x + y; }
            else { x = rnd(15, 45); y = rnd(3, 14); q = x + " - " + y; a = x - y; }
        } else if (tier == 2) {
            x = rnd(3, 12); y = rnd(3, 12);
            if (R.nextBoolean()) { q = x + " \u00D7 " + y; a = x * y; }
            else { q = (x * y) + " \u00F7 " + x; a = y; }
        } else {
            int k = R.nextInt(3);
            if (k == 0) { x = rnd(3, 12); q = x + "\u00B2"; a = x * x; }
            else if (k == 1) { x = rnd(2, 9); y = rnd(2, 12); q = "x + " + x + " = " + (x + y) + ",  x = ?"; a = y; }
            else { x = rnd(2, 9); y = rnd(2, 9); z = rnd(2, 9); q = x + " + " + y + " \u00D7 " + z; a = x + y * z; }
        }
        Q o = new Q();
        o.text = q.indexOf('?') < 0 ? q + " = ?" : q;
        o.answer = a;
        o.opts = options(a, 4);
        return o;
    }

    static int[] options(int a, int n) {
        List<Integer> l = new ArrayList<Integer>();
        l.add(a);
        int guard = 0;
        while (l.size() < n && guard++ < 200) {
            int w = a + rnd(-6, 6);
            if (w >= 0 && !l.contains(w)) l.add(w);
        }
        Collections.shuffle(l, R);
        int[] r = new int[l.size()];
        for (int i = 0; i < r.length; i++) r[i] = l.get(i);
        return r;
    }
}
