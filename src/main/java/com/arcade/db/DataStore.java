package com.arcade.db;

import com.arcade.model.Product;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Everything the app needs from a database. Two implementations:
 *  - MySqlStore  (JDBC, used on your own computer / Eclipse)
 *  - MongoStore  (MongoDB Atlas, used on Render)
 */
public interface DataStore {
    String name();

    // users
    int createUser(String username, String passwordHash) throws DuplicateUserException;
    Integer findUserId(String username, String passwordHash);   // null if wrong login
    boolean usernameExists(String username);
    boolean checkPassword(int uid, String passwordHash);
    void updatePassword(int uid, String passwordHash);

    // scores / leaderboard
    void addScore(int uid, String game, int score);
    List<String[]> leaderboard(String game, int limit);          // each row = {username, bestScore}
    int[] getScoreStats(int uid);                                // {games, best, total, rank}

    // level progress
    int getProgress(int uid, String game);
    Map<String, Integer> getAllProgress(int uid);
    void completeLevel(int uid, String game, int level);

    // store / orders
    List<Product> getProducts();
    Set<Integer> getOwnedProductIds(int uid);
    int getTotalScore(int uid);
    int getTotalSpent(int uid);
    void createOrder(int uid, int total, List<Integer> productIds);
}
