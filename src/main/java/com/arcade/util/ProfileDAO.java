package com.arcade.util;

public class ProfileDAO {
    public static class Stats {
        public int games, best, total, rank, balance;
    }

    public static Stats get(int uid) {
        int[] r = DBUtil.store().getScoreStats(uid);
        Stats st = new Stats();
        st.games = r[0];
        st.best = r[1];
        st.total = r[2];
        st.rank = r[3];
        st.balance = StoreDAO.getBalance(uid);
        return st;
    }
}
