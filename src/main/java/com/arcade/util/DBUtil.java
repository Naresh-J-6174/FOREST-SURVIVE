package com.arcade.util;

import com.arcade.db.DataStore;
import com.arcade.db.MongoStore;
import com.arcade.db.MySqlStore;
import java.io.InputStream;
import java.security.MessageDigest;
import java.util.Properties;

/**
 * Chooses the database automatically:
 *   - MONGODB_URI is set (Render)      -> MongoDB Atlas
 *   - otherwise (your PC / Eclipse)    -> MySQL, settings from db.properties
 * Environment variables always override db.properties.
 */
public class DBUtil {
    private static DataStore store;

    private static String cfg(Properties p, String env, String key, String def) {
        String v = System.getenv(env);
        if (v == null || v.trim().isEmpty()) v = System.getProperty(env);
        if (v == null || v.trim().isEmpty()) v = p.getProperty(key);
        return (v == null || v.trim().isEmpty()) ? def : v.trim();
    }

    public static synchronized DataStore store() {
        if (store == null) {
            Properties p = new Properties();
            try (InputStream in = DBUtil.class.getResourceAsStream("/db.properties")) {
                if (in != null) p.load(in);
            } catch (Exception ignore) { }

            String type = cfg(p, "DB_TYPE", "db.type", "");
            String mongoUri = cfg(p, "MONGODB_URI", "mongodb.uri", "");
            boolean useMongo = "mongodb".equalsIgnoreCase(type) || "mongo".equalsIgnoreCase(type)
                    || (type.isEmpty() && !mongoUri.isEmpty());

            if (useMongo) {
                if (mongoUri.isEmpty()) mongoUri = "mongodb://localhost:27017";
                store = new MongoStore(mongoUri, cfg(p, "MONGODB_DB", "mongodb.database", "arcade_hub"));
            } else {
                store = new MySqlStore(
                    cfg(p, "MYSQL_URL", "mysql.url",
                        "jdbc:mysql://localhost:3306/arcade_hub?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC"),
                    cfg(p, "MYSQL_USER", "mysql.user", "root"),
                    cfg(p, "MYSQL_PASSWORD", "mysql.password", "naresh1746"));
            }
            System.out.println("[ArcadeHub] Using database: " + store.name());
        }
        return store;
    }

    // used by the online games (MatchManager) to save results
    public static void addScore(int uid, String game, int score) {
        store().addScore(uid, game, score);
    }

    public static String hash(String s) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            StringBuilder sb = new StringBuilder();
            for (byte b : md.digest(s.getBytes("UTF-8"))) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
