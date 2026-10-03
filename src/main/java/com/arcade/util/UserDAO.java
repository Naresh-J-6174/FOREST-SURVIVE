package com.arcade.util;

import com.arcade.db.DuplicateUserException;

public class UserDAO {
    public static int register(String username, String password) throws DuplicateUserException {
        return DBUtil.store().createUser(username, DBUtil.hash(password));
    }
    public static Integer login(String username, String password) {
        return DBUtil.store().findUserId(username, DBUtil.hash(password == null ? "" : password));
    }
    public static boolean exists(String username) { return DBUtil.store().usernameExists(username); }
    public static boolean checkPassword(int uid, String password) {
        return DBUtil.store().checkPassword(uid, DBUtil.hash(password == null ? "" : password));
    }
    public static void changePassword(int uid, String newPassword) {
        DBUtil.store().updatePassword(uid, DBUtil.hash(newPassword));
    }
}
