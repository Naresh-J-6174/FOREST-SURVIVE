# ArcadeHub - Amazon Edition (Web Technology Lab project)

## What is inside
| Game | Type | Levels |
|------|------|--------|
| Amazon Rainforest Survival | realistic jungle survival, maths prey, predator danger questions | 5 |
| Snake Duel: You vs Bot | race an AI snake (BFS pathfinding) to the correct answers | 5 |
| Math Snake | one maths skill per level | 6 |
| Classic Snake | berries, rocks, faster speed | 5 |
| Online Math Sprint | real 1v1, first to 10 correct answers | live |
| Jungle Tic-Tac-Math | real 1v1, win a cell by solving a question | live |

Every game goes fullscreen when you start it (button top-right toggles; Esc exits) and the canvas always scales to fit the screen.

Plus: Amazon-themed UI, profile page (stats, rank, badges, avatar cookie, change password),
Biosphere Store (cart + checkout), XML leaderboard, level progress saved in MongoDB.

## One project, two databases
| Where it runs | Database | How it is chosen |
|---------------|----------|------------------|
| Your PC / Eclipse | **MySQL** | default; edit `src/main/resources/db.properties` (user / password) |
| Render | **MongoDB Atlas** | automatically, when the environment variable `MONGODB_URI` exists |

The code is the same: servlets/JSPs -> DAO classes -> `DataStore` interface -> `MySqlStore` (JDBC) or `MongoStore` (Mongo driver).
Tables / collections are created automatically on first start. The manual scripts are:
`sql/schema.sql` (MySQL) and `mongodb/setup.js` + `mongodb/queries.js` (MongoDB).

## Run locally in Eclipse (MySQL)
1. Install JDK 8+ (11/17 fine), Eclipse IDE for Enterprise Java, Tomcat 9, MySQL.
2. Start MySQL. Edit `mysql.user` / `mysql.password` in `src/main/resources/db.properties`.
   (Optional: `mysql -u root -p < sql/schema.sql`. The app also creates the database and tables by itself.)
3. Eclipse: File > Import > Maven > **Existing Maven Projects** > select this folder > Finish
   (Maven downloads the MySQL and MongoDB drivers - no jar copying).
4. Right-click project > Run As > **Run on Server** > Tomcat v9.0.
5. Open http://localhost:8080/ArcadeHub/login.jsp

## Deploy on Render (MongoDB Atlas)
1. Atlas: create free cluster > Database Access: add user > Network Access: allow `0.0.0.0/0` > Connect > Drivers > copy the string.
2. Push this folder to GitHub.
3. Render: New > Web Service > pick the repo > Language **Docker** > add env var `MONGODB_URI` = your Atlas string > Deploy.
4. Open https://<service>.onrender.com/login.jsp  (log shows `[ArcadeHub] Using database: MongoDB`)

## Playing on a phone
Open the Render link in your phone browser (Chrome / Safari) - nothing to install.
- **Snake, Math Snake, Snake Duel:** swipe on the board to turn, or use the arrow pad at the bottom.
- **Amazon Rainforest Survival:** hold the left / right buttons (or the left / right side of the board) to steer; tap the answer buttons in a challenge.
- **Tic-Tac-Toe, Math Sprint, Store, Cart, Leaderboard, Profile:** tap as usual.
- Menus and end screens fill the whole phone screen; works in portrait and landscape.
- Phones are detected automatically. To preview the phone layout on a PC, open any page with `?touch=1` added
  (for example `http://localhost:8080/ArcadeHub/games/snake.jsp?touch=1`), and `?touch=0` to switch it off again.
  Desktop keyboard controls are unchanged.

## How to test the two online games alone
Log in as user A in Chrome and as user B in another browser (or an Incognito window), open the same game in both and press "Find opponent".
Both pages are matched into one room and update live through AJAX polling every 0.7 s.

## Syllabus mapping
| # | Experiment | Where |
|---|-----------|-------|
| 1 | Client-side JavaScript | `js/arcade.js` (shared library), `js/validate.js`, all game loops, canvas drawing, bot AI |
| 2 | Servlet web app | `servlet/` package: Register, Login, Logout, Score, Progress, Profile, Cart, Checkout, Inventory, Leaderboard, CheckUser, Match |
| 3 | JSP web app | all `.jsp` pages + reusable includes `WEB-INF/head.jspf`, `nav.jspf`, `auth.jspf` |
| 4 | Cookies and session | HttpSession (userId, username, cart); cookies `rememberedUser`, `lastVisit` (shown on hub), `avatar` (profile) |
| 5 | Database connectivity | `DBUtil`, `MySqlStore` (JDBC + PreparedStatement), `MongoStore` (MongoDB driver), DAOs |
| 6 | Form validation with AJAX | register page live username check; level menu, inventory and online games all use XMLHttpRequest |
| 7 | XML from server into HTML table | `LeaderboardServlet` -> `leaderboard.jsp` (parses `responseXML`) |
| 8 | Database application | tables users, scores, progress, products, orders, order_items |
| 9 | E-commerce | store -> session cart -> checkout transaction -> items change the Amazon game |
| 10 | Testing | `TESTING.md` |

## Project structure
```
ArcadeHub
|-- pom.xml, Dockerfile
|-- TESTING.md
`-- src/main
    |-- java/com/arcade
    |   |-- model/Product.java
    |   |-- db/ DataStore, MySqlStore, MongoStore  util/ DBUtil, UserDAO, StoreDAO, ProgressDAO, ProfileDAO, MathGen, MatchManager
    |   `-- servlet/ Register, Login, Logout, CheckUser, Score, Leaderboard, Progress, Profile,
    |                Cart, Checkout, Inventory, Match
    `-- webapp
        |-- WEB-INF/ web.xml, head.jspf, nav.jspf, auth.jspf,
        |-- js/ style.css, arcade.js, validate.js
        |-- games/ amazon.jsp, duel.jsp, mathsnake.jsp, snake.jsp, sprint.jsp, tictac.jsp
        `-- index.jsp login.jsp register.jsp profile.jsp store.jsp cart.jsp leaderboard.jsp
```
