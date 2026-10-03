package com.arcade.db;

import com.arcade.model.Product;
import com.mongodb.ErrorCategory;
import com.mongodb.MongoWriteException;
import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoDatabase;
import com.mongodb.client.model.Accumulators;
import com.mongodb.client.model.Aggregates;
import com.mongodb.client.model.FindOneAndUpdateOptions;
import com.mongodb.client.model.IndexOptions;
import com.mongodb.client.model.Indexes;
import com.mongodb.client.model.ReturnDocument;
import com.mongodb.client.model.Sorts;
import com.mongodb.client.model.UpdateOptions;
import com.mongodb.client.model.Updates;
import java.util.*;
import org.bson.Document;

import static com.mongodb.client.model.Filters.and;
import static com.mongodb.client.model.Filters.eq;

/** MongoDB Atlas implementation. Collections: users, scores, progress, products, orders, counters. */
public class MongoStore implements DataStore {
    private final MongoDatabase db;

    public MongoStore(String uri, String dbName) {
        MongoClient client = MongoClients.create(uri);
        db = client.getDatabase(dbName);
        try {
            initCollections();
        } catch (RuntimeException e) {
            throw new DataException("Cannot connect to MongoDB Atlas (check MONGODB_URI, user/password and Network Access)", e);
        }
    }

    public String name() { return "MongoDB"; }

    private MongoCollection<Document> col(String n) { return db.getCollection(n); }

    // unique indexes + the 4 store products (same job as sql/schema.sql and mongodb/setup.js)
    private void initCollections() {
        col("users").createIndex(Indexes.ascending("username"), new IndexOptions().unique(true));
        col("scores").createIndex(Indexes.ascending("user_id"));
        col("scores").createIndex(Indexes.ascending("game"));
        col("progress").createIndex(Indexes.ascending("user_id", "game"), new IndexOptions().unique(true));
        col("orders").createIndex(Indexes.ascending("user_id"));

        Object[][] seed = {
            {1, "hint", "Botanist Lens", "Highlights the prey that carries the correct answer.", 100},
            {2, "elixir", "Metabolic Elixir", "Energy drains 50% slower in Amazon Math Survival.", 150},
            {3, "golden_skin", "Golden Viper Skin", "Your snake shines gold in the jungle.", 250},
            {4, "cloak", "Apex Cloak", "Jaguars ignore you for the first 30 seconds of every run.", 400}
        };
        for (Object[] p : seed) {
            // setOnInsert = only fills the product the first time (never overwrites later edits)
            col("products").updateOne(eq("_id", p[0]), Updates.combine(
                    Updates.setOnInsert("code", p[1]),
                    Updates.setOnInsert("name", p[2]),
                    Updates.setOnInsert("description", p[3]),
                    Updates.setOnInsert("price", p[4])), new UpdateOptions().upsert(true));
        }
    }

    // auto-increment integer ids (so the session/JSP code can keep using int ids, as with MySQL)
    private int nextId(String sequence) {
        Document d = col("counters").findOneAndUpdate(eq("_id", sequence), Updates.inc("seq", 1),
                new FindOneAndUpdateOptions().upsert(true).returnDocument(ReturnDocument.AFTER));
        return ((Number) d.get("seq")).intValue();
    }

    private static int num(Document d, String key) {
        Object v = d.get(key);
        return v instanceof Number ? ((Number) v).intValue() : 0;
    }

    public int createUser(String username, String hash) throws DuplicateUserException {
        int id = nextId("users");
        try {
            col("users").insertOne(new Document("_id", id).append("username", username)
                    .append("password_hash", hash).append("created_at", new Date()));
            return id;
        } catch (MongoWriteException e) {
            if (e.getError().getCategory() == ErrorCategory.DUPLICATE_KEY) throw new DuplicateUserException();
            throw new DataException("createUser failed", e);
        }
    }

    public Integer findUserId(String username, String hash) {
        Document d = col("users").find(and(eq("username", username), eq("password_hash", hash))).first();
        return d == null ? null : Integer.valueOf(num(d, "_id"));
    }

    public boolean usernameExists(String username) {
        return col("users").find(eq("username", username)).first() != null;
    }

    public boolean checkPassword(int uid, String hash) {
        return col("users").find(and(eq("_id", uid), eq("password_hash", hash))).first() != null;
    }

    public void updatePassword(int uid, String hash) {
        col("users").updateOne(eq("_id", uid), Updates.set("password_hash", hash));
    }

    public void addScore(int uid, String game, int score) {
        col("scores").insertOne(new Document("user_id", uid).append("game", game)
                .append("score", score).append("played_at", new Date()));
    }

    public List<String[]> leaderboard(String game, int limit) {
        List<Document> top = col("scores").aggregate(Arrays.asList(
                Aggregates.match(eq("game", game)),
                Aggregates.group("$user_id", Accumulators.max("best", "$score")),
                Aggregates.sort(Sorts.descending("best")),
                Aggregates.limit(limit))).into(new ArrayList<Document>());
        List<String[]> rows = new ArrayList<String[]>();
        for (Document d : top) {
            Document u = col("users").find(eq("_id", d.get("_id"))).first();
            if (u != null) rows.add(new String[] { u.getString("username"), String.valueOf(num(d, "best")) });
        }
        return rows;
    }

    public int[] getScoreStats(int uid) {
        int[] r = new int[4];
        for (Document d : col("scores").find(eq("user_id", uid))) {
            int s = num(d, "score");
            r[0]++;
            r[2] += s;
            if (s > r[1]) r[1] = s;
        }
        int better = 0;
        for (Document d : col("scores").aggregate(Arrays.asList(
                Aggregates.group("$user_id", Accumulators.sum("s", "$score"))))) {
            if (num(d, "s") > r[2]) better++;
        }
        r[3] = better + 1;
        return r;
    }

    public int getProgress(int uid, String game) {
        Document d = col("progress").find(and(eq("user_id", uid), eq("game", game))).first();
        return d == null ? 0 : num(d, "max_level");
    }

    public Map<String, Integer> getAllProgress(int uid) {
        Map<String, Integer> m = new HashMap<String, Integer>();
        for (Document d : col("progress").find(eq("user_id", uid))) m.put(d.getString("game"), num(d, "max_level"));
        return m;
    }

    public void completeLevel(int uid, String game, int level) {
        col("progress").updateOne(and(eq("user_id", uid), eq("game", game)),
                Updates.max("max_level", level), new UpdateOptions().upsert(true));
    }

    public List<Product> getProducts() {
        List<Product> list = new ArrayList<Product>();
        for (Document d : col("products").find().sort(Sorts.ascending("price"))) {
            Product p = new Product();
            p.id = num(d, "_id");
            p.code = d.getString("code");
            p.name = d.getString("name");
            p.description = d.getString("description");
            p.price = num(d, "price");
            list.add(p);
        }
        return list;
    }

    public Set<Integer> getOwnedProductIds(int uid) {
        Set<Integer> s = new HashSet<Integer>();
        for (Document o : col("orders").find(eq("user_id", uid))) {
            Object items = o.get("items");
            if (items instanceof List) for (Object i : (List<?>) items) s.add(((Number) i).intValue());
        }
        return s;
    }

    public int getTotalScore(int uid) {
        int t = 0;
        for (Document d : col("scores").find(eq("user_id", uid))) t += num(d, "score");
        return t;
    }

    public int getTotalSpent(int uid) {
        int t = 0;
        for (Document d : col("orders").find(eq("user_id", uid))) t += num(d, "total");
        return t;
    }

    public void createOrder(int uid, int total, List<Integer> ids) {
        col("orders").insertOne(new Document("_id", nextId("orders")).append("user_id", uid)
                .append("total", total).append("items", new ArrayList<Integer>(ids)).append("created_at", new Date()));
    }
}
