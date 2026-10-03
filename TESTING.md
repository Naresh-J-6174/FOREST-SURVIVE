# Experiment 10 - Testing (fill "Actual" and "Pass/Fail" during your demo)

| # | Module | Test case | Input | Expected | Actual | Pass/Fail |
|---|--------|-----------|-------|----------|--------|-----------|
| 1 | Register | Username too short | "ab" | JS alert, form not submitted | | |
| 2 | Register (AJAX) | Existing username | type an existing name | "Username taken" appears without reload | | |
| 3 | Login | Wrong password | valid user, bad password | Error message | | |
| 4 | Cookie | Remember me | tick, log out, reopen login | Username prefilled | | |
| 5 | Cookie | lastVisit | log in twice | Hub shows the previous visit time | | |
| 6 | Session | Open /index.jsp without login | direct URL | Redirect to login | | |
| 7 | Session | Logout, then Back button | | Redirect to login | | |
| 8 | Levels | Locked levels | new account, open any game | Only level 1 is clickable | | |
| 9 | Levels | Clear level 1 | reach the target | "Level cleared", level 2 unlocks, progress saved after reload | | |
| 10 | Classic Snake | Hit a wall | steer into wall | "Crashed", retry offered, score saved | | |
| 11 | Math Snake | Wrong answer | eat a wrong number | Lives -1 and correct answer shown | | |
| 12 | Snake Duel | Bot competes | idle on level 5 | Bot collects answers and wins | | |
| 13 | Snake Duel | Beat the bot | eat answers first on level 1 | Level cleared, next level unlocked | | |
| 14 | Amazon | Correct prey | eat the right number | Score +10, energy +25, progress x/target | | |
| 15 | Amazon | Predator danger | let a jaguar get close | Question appears, correct = predator retreats | | |
| 16 | Amazon | Danger timeout | do not answer | Game over | | |
| 17 | Online Sprint | Matchmaking | open in 2 browsers, find opponent | Both enter the same room | | |
| 18 | Online Sprint | Race | answer 10 correctly in one browser | Winner gets Victory, other Defeat, scores saved | | |
| 19 | Online Tic-Tac-Math | Turn rules | click a cell on the opponent's turn | Ignored | | |
| 20 | Online Tic-Tac-Math | Wrong answer | answer wrongly | Turn passes, cell stays empty | | |
| 21 | Online Tic-Tac-Math | Win | three in a row | Result shown on both screens | | |
| 22 | Online | Opponent leaves | close one tab, wait 15 s | Other player wins | | |
| 23 | Leaderboard (XML) | Show scores | pick each game | Table filled from XML | | |
| 24 | Store | Buy with enough points | add item, checkout | Order saved, item "Owned" | | |
| 25 | Store | Not enough points | cart above balance | Error, nothing bought | | |
| 26 | Store + game | Item effect | buy Golden Viper Skin | Gold snake in Amazon game | | |
| 27 | Profile | Change password wrong old | wrong current password | Error message | | |
| 28 | Profile | Change password correct | correct old + new | Success, can log in with new password | | |
| 29 | Profile | Avatar cookie | choose Jaguar, reload | Jaguar icon in navigation | | |
| 30 | Security | SQL injection | username `' OR '1'='1` | Login fails | | |

## Tools to mention in the viva
* Manual functional testing (table above).
* Browser DevTools (F12): Network tab shows the AJAX calls (`checkUser`, `progress`, `saveScore`, `match`, `inventory`, `leaderboard`); Application tab shows the cookies.
* Selenium IDE: record and replay the login test (case 3 or 4).
* SQL checks: `SELECT * FROM scores;` `SELECT * FROM progress;` `SELECT * FROM orders;`
