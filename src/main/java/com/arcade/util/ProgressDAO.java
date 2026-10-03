package com.arcade.util;

import java.util.Map;

// Highest level cleared per game and player
public class ProgressDAO {
    public static int get(int uid, String game) { return DBUtil.store().getProgress(uid, game); }
    public static Map<String, Integer> getAll(int uid) { return DBUtil.store().getAllProgress(uid); }
    public static void complete(int uid, String game, int level) { DBUtil.store().completeLevel(uid, game, level); }
}
