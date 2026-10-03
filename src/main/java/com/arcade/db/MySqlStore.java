package com.arcade.db;

import com.arcade.model.Product;
import java.sql.*;
import java.util.*;

/** MySQL implementation (JDBC + PreparedStatement). */
public class MySqlStore implements DataStore {
    private final String url, user, pass;

    public MySqlStore(String url, String user, String pass) {
        this.url = url;
        this.user = user;
        this.pass = pass;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new DataException("MySQL driver (mysql-connector-j) is missing from the classpath", e);
        }
        initSchema();
    }

    public String name() { return "MySQL"; }

    private Connection conn() throws SQLException {
        return DriverManager.getConnection(url, user, pass);
    }

    // Same tables as sql/schema.sql - created automatically if they do not exist yet
    private void initSchema() {
        String[] ddl = {
            "CREATE TABLE IF NOT EXISTS users (id INT AUTO_INCREMENT PRIMARY KEY, username VARCHAR(20) NOT NULL UNIQUE, " +
                "password_hash CHAR(64) NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)",
            "CREATE TABLE IF NOT EXISTS scores (id INT AUTO_INCREMENT PRIMARY KEY, user_id INT NOT NULL, game VARCHAR(30) NOT NULL, " +
                "score INT NOT NULL, played_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY (user_id) REFERENCES users(id))",
            "CREATE TABLE IF NOT EXISTS progress (user_id INT NOT NULL, game VARCHAR(30) NOT NULL, max_level INT NOT NULL DEFAULT 0, " +
                "PRIMARY KEY (user_id, game), FOREIGN KEY (user_id) REFERENCES users(id))",
            "CREATE TABLE IF NOT EXISTS products (id INT AUTO_INCREMENT PRIMARY KEY, code VARCHAR(30) NOT NULL UNIQUE, " +
                "name VARCHAR(60) NOT NULL, description VARCHAR(200) NOT NULL, price INT NOT NULL)",
            "CREATE TABLE IF NOT EXISTS orders (id INT AUTO_INCREMENT PRIMARY KEY, user_id INT NOT NULL, total INT NOT NULL, " +
                "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY (user_id) REFERENCES users(id))",
            "CREATE TABLE IF NOT EXISTS order_items (order_id INT NOT NULL, product_id INT NOT NULL, PRIMARY KEY (order_id, product_id), " +
                "FOREIGN KEY (order_id) REFERENCES orders(id), FOREIGN KEY (product_id) REFERENCES products(id))",
            "INSERT IGNORE INTO products(code,name,description,price) VALUES " +
                "('hint','Botanist Lens','Highlights the prey that carries the correct answer.',100)," +
                "('elixir','Metabolic Elixir','Energy drains 50% slower in Amazon Math Survival.',150)," +
                "('golden_skin','Golden Viper Skin','Your snake shines gold in the jungle.',250)," +
                "('cloak','Apex Cloak','Jaguars ignore you for the first 30 seconds of every run.',400)"
        };
        try (Connection c = conn(); Statement st = c.createStatement()) {
            for (String s : ddl) st.executeUpdate(s);
        } catch (SQLException e) {
            throw new DataException("Cannot connect to MySQL at " + url + " (check db.properties / is MySQL running?)", e);
        }
    }

    public int createUser(String username, String hash) throws DuplicateUserException {
        try (Connection c = conn();
             PreparedStatement ps = c.prepareStatement("INSERT INTO users(username,password_hash) VALUES(?,?)", Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, username);
            ps.setString(2, hash);
            ps.executeUpdate();
            ResultSet k = ps.getGeneratedKeys();
            k.next();
            return k.getInt(1);
        } catch (SQLIntegrityConstraintViolationException e) {
            throw new DuplicateUserException();
        } catch (SQLException e) {
            throw new DataException("createUser failed", e);
        }
    }

    public Integer findUserId(String username, String hash) {
        try (Connection c = conn();
             PreparedStatement ps = c.prepareStatement("SELECT id FROM users WHERE username=? AND password_hash=?")) {
            ps.setString(1, username);
            ps.setString(2, hash);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? Integer.valueOf(rs.getInt(1)) : null;
        } catch (SQLException e) {
            throw new DataException("findUserId failed", e);
        }
    }

    public boolean usernameExists(String username) {
        try (Connection c = conn(); PreparedStatement ps = c.prepareStatement("SELECT 1 FROM users WHERE username=?")) {
            ps.setString(1, username);
            return ps.executeQuery().next();
        } catch (SQLException e) {
            throw new DataException("usernameExists failed", e);
        }
    }

    public boolean checkPassword(int uid, String hash) {
        try (Connection c = conn(); PreparedStatement ps = c.prepareStatement("SELECT 1 FROM users WHERE id=? AND password_hash=?")) {
            ps.setInt(1, uid);
            ps.setString(2, hash);
            return ps.executeQuery().next();
        } catch (SQLException e) {
            throw new DataException("checkPassword failed", e);
        }
    }

    public void updatePassword(int uid, String hash) {
        try (Connection c = conn(); PreparedStatement ps = c.prepareStatement("UPDATE users SET password_hash=? WHERE id=?")) {
            ps.setString(1, hash);
            ps.setInt(2, uid);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DataException("updatePassword failed", e);
        }
    }

    public void addScore(int uid, String game, int score) {
        try (Connection c = conn(); PreparedStatement ps = c.prepareStatement("INSERT INTO scores(user_id,game,score) VALUES(?,?,?)")) {
            ps.setInt(1, uid);
            ps.setString(2, game);
            ps.setInt(3, score);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DataException("addScore failed", e);
        }
    }

    public List<String[]> leaderboard(String game, int limit) {
        List<String[]> rows = new ArrayList<String[]>();
        try (Connection c = conn();
             PreparedStatement ps = c.prepareStatement(
                 "SELECT u.username, MAX(s.score) AS best FROM scores s JOIN users u ON u.id=s.user_id " +
                 "WHERE s.game=? GROUP BY u.username ORDER BY best DESC LIMIT ?")) {
            ps.setString(1, game);
            ps.setInt(2, limit);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) rows.add(new String[] { rs.getString(1), String.valueOf(rs.getInt(2)) });
        } catch (SQLException e) {
            throw new DataException("leaderboard failed", e);
        }
        return rows;
    }

    public int[] getScoreStats(int uid) {
        int[] r = new int[4];
        try (Connection c = conn()) {
            try (PreparedStatement ps = c.prepareStatement(
                    "SELECT COUNT(*), COALESCE(MAX(score),0), COALESCE(SUM(score),0) FROM scores WHERE user_id=?")) {
                ps.setInt(1, uid);
                ResultSet rs = ps.executeQuery();
                rs.next();
                r[0] = rs.getInt(1);
                r[1] = rs.getInt(2);
                r[2] = rs.getInt(3);
            }
            try (PreparedStatement ps = c.prepareStatement(
                    "SELECT COUNT(*) + 1 FROM (SELECT SUM(score) AS s FROM scores GROUP BY user_id) t WHERE t.s > ?")) {
                ps.setInt(1, r[2]);
                ResultSet rs = ps.executeQuery();
                rs.next();
                r[3] = rs.getInt(1);
            }
        } catch (SQLException e) {
            throw new DataException("getScoreStats failed", e);
        }
        return r;
    }

    public int getProgress(int uid, String game) {
        try (Connection c = conn(); PreparedStatement ps = c.prepareStatement("SELECT max_level FROM progress WHERE user_id=? AND game=?")) {
            ps.setInt(1, uid);
            ps.setString(2, game);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : 0;
        } catch (SQLException e) {
            throw new DataException("getProgress failed", e);
        }
    }

    public Map<String, Integer> getAllProgress(int uid) {
        Map<String, Integer> m = new HashMap<String, Integer>();
        try (Connection c = conn(); PreparedStatement ps = c.prepareStatement("SELECT game, max_level FROM progress WHERE user_id=?")) {
            ps.setInt(1, uid);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) m.put(rs.getString(1), rs.getInt(2));
        } catch (SQLException e) {
            throw new DataException("getAllProgress failed", e);
        }
        return m;
    }

    public void completeLevel(int uid, String game, int level) {
        String sql = "INSERT INTO progress(user_id,game,max_level) VALUES(?,?,?) ON DUPLICATE KEY UPDATE max_level = GREATEST(max_level, ?)";
        try (Connection c = conn(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, uid);
            ps.setString(2, game);
            ps.setInt(3, level);
            ps.setInt(4, level);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DataException("completeLevel failed", e);
        }
    }

    public List<Product> getProducts() {
        List<Product> list = new ArrayList<Product>();
        try (Connection c = conn();
             PreparedStatement ps = c.prepareStatement("SELECT id,code,name,description,price FROM products ORDER BY price");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Product p = new Product();
                p.id = rs.getInt("id");
                p.code = rs.getString("code");
                p.name = rs.getString("name");
                p.description = rs.getString("description");
                p.price = rs.getInt("price");
                list.add(p);
            }
        } catch (SQLException e) {
            throw new DataException("getProducts failed", e);
        }
        return list;
    }

    public Set<Integer> getOwnedProductIds(int uid) {
        Set<Integer> s = new HashSet<Integer>();
        String sql = "SELECT oi.product_id FROM order_items oi JOIN orders o ON o.id=oi.order_id WHERE o.user_id=?";
        try (Connection c = conn(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, uid);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) s.add(rs.getInt(1));
        } catch (SQLException e) {
            throw new DataException("getOwnedProductIds failed", e);
        }
        return s;
    }

    public int getTotalScore(int uid) {
        return sumOf("SELECT COALESCE(SUM(score),0) FROM scores WHERE user_id=?", uid);
    }

    public int getTotalSpent(int uid) {
        return sumOf("SELECT COALESCE(SUM(total),0) FROM orders WHERE user_id=?", uid);
    }

    private int sumOf(String sql, int uid) {
        try (Connection c = conn(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, uid);
            ResultSet rs = ps.executeQuery();
            rs.next();
            return rs.getInt(1);
        } catch (SQLException e) {
            throw new DataException("sum failed", e);
        }
    }

    // order + order_items inside one transaction
    public void createOrder(int uid, int total, List<Integer> ids) {
        try (Connection c = conn()) {
            c.setAutoCommit(false);
            try {
                int orderId;
                try (PreparedStatement ps = c.prepareStatement("INSERT INTO orders(user_id,total) VALUES(?,?)", Statement.RETURN_GENERATED_KEYS)) {
                    ps.setInt(1, uid);
                    ps.setInt(2, total);
                    ps.executeUpdate();
                    ResultSet k = ps.getGeneratedKeys();
                    k.next();
                    orderId = k.getInt(1);
                }
                try (PreparedStatement ps = c.prepareStatement("INSERT INTO order_items(order_id,product_id) VALUES(?,?)")) {
                    for (int id : ids) { ps.setInt(1, orderId); ps.setInt(2, id); ps.addBatch(); }
                    ps.executeBatch();
                }
                c.commit();
            } catch (SQLException e) {
                c.rollback();
                throw e;
            }
        } catch (SQLException e) {
            throw new DataException("createOrder failed", e);
        }
    }
}
