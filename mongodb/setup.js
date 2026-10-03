// ArcadeHub - MongoDB Atlas setup (MongoDB equivalent of sql/schema.sql)
// OPTIONAL: the app creates all of this automatically on first start.
// Run it in mongosh to see/create the collections yourself:
//   mongosh "mongodb+srv://<user>:<password>@<cluster>.mongodb.net/" --file mongodb/setup.js

use("arcade_hub");

// CREATE TABLE  ->  createCollection
["users", "scores", "progress", "products", "orders", "counters"].forEach(function (c) {
  if (!db.getCollectionNames().includes(c)) db.createCollection(c);
});

// UNIQUE / INDEX  ->  createIndex
db.users.createIndex({ username: 1 }, { unique: true });
db.scores.createIndex({ user_id: 1 });
db.scores.createIndex({ game: 1 });
db.progress.createIndex({ user_id: 1, game: 1 }, { unique: true });
db.orders.createIndex({ user_id: 1 });

// INSERT products  ->  insertOne / updateOne(upsert)
[
  { _id: 1, code: "hint",        name: "Botanist Lens",     description: "Highlights the prey that carries the correct answer.",        price: 100 },
  { _id: 2, code: "elixir",      name: "Metabolic Elixir",  description: "Energy drains 50% slower in Amazon Math Survival.",           price: 150 },
  { _id: 3, code: "golden_skin", name: "Golden Viper Skin", description: "Your snake shines gold in the jungle.",                       price: 250 },
  { _id: 4, code: "cloak",       name: "Apex Cloak",        description: "Jaguars ignore you for the first 30 seconds of every run.",   price: 400 }
].forEach(function (p) {
  db.products.updateOne({ _id: p._id }, { $setOnInsert: p }, { upsert: true });
});

print("ArcadeHub collections ready: " + db.getCollectionNames().join(", "));
