// ArcadeHub - MongoDB queries used by the app (for your lab record / viva)
// Run in mongosh after:  use("arcade_hub")

// ---- Users (Register / Login / AJAX username check) ----
db.users.insertOne({ _id: 1, username: "ravi", password_hash: "<sha256>", created_at: new Date() });  // INSERT INTO users
db.users.findOne({ username: "ravi", password_hash: "<sha256>" });                                    // SELECT id FROM users WHERE ...
db.users.findOne({ username: "ravi" });                                                               // username taken?
db.users.updateOne({ _id: 1 }, { $set: { password_hash: "<new sha256>" } });                          // UPDATE users SET password_hash

// ---- Scores ----
db.scores.insertOne({ user_id: 1, game: "snake", score: 120, played_at: new Date() });                // INSERT INTO scores
db.scores.aggregate([                                                                                 // Leaderboard (top 10 per game)
  { $match: { game: "snake" } },
  { $group: { _id: "$user_id", best: { $max: "$score" } } },
  { $sort: { best: -1 } },
  { $limit: 10 }
]);
db.scores.aggregate([{ $match: { user_id: 1 } },                                                      // Profile: games, best, total
  { $group: { _id: null, games: { $sum: 1 }, best: { $max: "$score" }, total: { $sum: "$score" } } }]);

// ---- Level progress ----
db.progress.updateOne({ user_id: 1, game: "amazon" }, { $max: { max_level: 3 } }, { upsert: true });  // INSERT ... ON DUPLICATE KEY UPDATE GREATEST
db.progress.find({ user_id: 1 });                                                                     // SELECT game,max_level

// ---- Store / E-commerce ----
db.products.find().sort({ price: 1 });                                                                // SELECT * FROM products ORDER BY price
db.orders.insertOne({ _id: 1, user_id: 1, total: 250, items: [3], created_at: new Date() });          // INSERT INTO orders + order_items
db.orders.find({ user_id: 1 });                                                                       // items the player owns
db.orders.aggregate([{ $match: { user_id: 1 } }, { $group: { _id: null, spent: { $sum: "$total" } } }]);  // total spent

// ---- Handy checks ----
db.users.countDocuments();
db.scores.find().sort({ played_at: -1 }).limit(5);
