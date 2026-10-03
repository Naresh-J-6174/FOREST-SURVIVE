CREATE DATABASE IF NOT EXISTS arcade_hub;
USE arcade_hub;

CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(20) NOT NULL UNIQUE,
  password_hash CHAR(64) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS scores (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  game VARCHAR(30) NOT NULL,
  score INT NOT NULL,
  played_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ===== Level progress (highest level cleared per game) =====
CREATE TABLE IF NOT EXISTS progress (
  user_id INT NOT NULL,
  game VARCHAR(30) NOT NULL,
  max_level INT NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, game),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ===== E-commerce tables (Experiment 9) =====
CREATE TABLE IF NOT EXISTS products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(30) NOT NULL UNIQUE,
  name VARCHAR(60) NOT NULL,
  description VARCHAR(200) NOT NULL,
  price INT NOT NULL
);

CREATE TABLE IF NOT EXISTS orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  total INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS order_items (
  order_id INT NOT NULL,
  product_id INT NOT NULL,
  PRIMARY KEY (order_id, product_id),
  FOREIGN KEY (order_id) REFERENCES orders(id),
  FOREIGN KEY (product_id) REFERENCES products(id)
);

INSERT IGNORE INTO products(code,name,description,price) VALUES
 ('hint','Botanist Lens','Highlights the prey that carries the correct answer.',100),
 ('elixir','Metabolic Elixir','Energy drains 50% slower in Amazon Math Survival.',150),
 ('golden_skin','Golden Viper Skin','Your snake shines gold in the jungle.',250),
 ('cloak','Apex Cloak','Jaguars ignore you for the first 30 seconds of every run.',400);
