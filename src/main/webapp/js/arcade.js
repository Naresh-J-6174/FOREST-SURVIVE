/* Shared helpers for every game: AJAX, level menu, maths, snake drawing, game loop */
var Arcade = (function () {
  var base = (typeof ARCADE_CTX !== "undefined") ? ARCADE_CTX : "";
  var A = {};

  /* ---------- touch / phone detection ----------
     Phones & tablets are detected automatically (coarse pointer).
     To preview the phone layout on a PC open any page with ?touch=1  (?touch=0 turns it off again). */
  A.touch = (function () {
    try {
      if (/[?&]touch=0/.test(location.search)) sessionStorage.removeItem("arcadeTouch");
      if (/[?&]touch=1/.test(location.search)) sessionStorage.setItem("arcadeTouch", "1");
      if (sessionStorage.getItem("arcadeTouch") === "1") return true;
    } catch (e) {}
    return !!(window.matchMedia && window.matchMedia("(pointer: coarse)").matches);
  })();
  if (A.touch) document.documentElement.className += " touch";
  function rnd(a, b) { return Math.floor(Math.random() * (b - a + 1)) + a; }
  A.rnd = rnd;

  /* ---------- AJAX (XMLHttpRequest) ---------- */
  A.req = function (method, url, body, cb) {
    var x = new XMLHttpRequest();
    x.onreadystatechange = function () { if (x.readyState === 4 && cb) cb(x.status, x.responseText); };
    x.open(method, base + url, true);
    if (method === "POST") x.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    x.send(body || null);
  };
  A.json = function (method, url, body, cb) {
    A.req(method, url, body, function (s, t) {
      var d = null;
      try { d = JSON.parse(t); } catch (e) { d = null; }
      if (cb) cb(s, d);
    });
  };
  A.progress = function (game, cb) {
    A.req("GET", "/progress?game=" + game, null, function (s, t) { cb(s === 200 ? (parseInt(t, 10) || 0) : 0); });
  };
  A.levelDone = function (game, level) { A.req("POST", "/progress", "game=" + game + "&level=" + level); };
  A.saveScore = function (game, score, cb) {
    A.req("POST", "/saveScore", "game=" + game + "&score=" + score, function (s) { if (cb) cb(s === 200); });
  };

  /* ---------- maths ---------- */
  A.options = function (a, n) {
    var o = [a], g = 0;
    while (o.length < n && g++ < 200) { var w = a + rnd(-6, 6); if (w >= 0 && o.indexOf(w) < 0) o.push(w); }
    o.sort(function () { return Math.random() - 0.5; });
    return o;
  };
  A.qText = function (m) { return m.q + (m.q.indexOf("?") < 0 ? " = ?" : ""); };
  // tier 1: + -   tier 2: x /   tier 3: squares, equations, order of operations
  A.mathTier = function (tier) {
    var q, a, x, y, z, k;
    if (tier <= 1) {
      if (rnd(0, 1)) { x = rnd(5, 30); y = rnd(5, 30); q = x + " + " + y; a = x + y; }
      else { x = rnd(15, 45); y = rnd(3, 14); q = x + " - " + y; a = x - y; }
    } else if (tier === 2) {
      x = rnd(3, 12); y = rnd(3, 12);
      if (rnd(0, 1)) { q = x + " \u00D7 " + y; a = x * y; } else { q = (x * y) + " \u00F7 " + x; a = y; }
    } else {
      k = rnd(0, 2);
      if (k === 0) { x = rnd(3, 12); q = x + "\u00B2"; a = x * x; }
      else if (k === 1) { x = rnd(2, 9); y = rnd(2, 12); q = "x + " + x + " = " + (x + y) + ",  x = ?"; a = y; }
      else { x = rnd(2, 9); y = rnd(2, 9); z = rnd(2, 9); q = x + " + " + y + " \u00D7 " + z; a = x + y * z; }
    }
    return { q: q, a: a };
  };
  // one skill per level (used by Math Snake, levels 1-6)
  A.mathLevel = function (lv) {
    var q, a, x, y, z;
    switch (lv) {
      case 1: x = rnd(3, 25); y = rnd(3, 25); q = x + " + " + y; a = x + y; break;
      case 2: x = rnd(15, 60); y = rnd(3, x - 1); q = x + " - " + y; a = x - y; break;
      case 3: x = rnd(2, 12); y = rnd(2, 12); q = x + " \u00D7 " + y; a = x * y; break;
      case 4: x = rnd(2, 12); y = rnd(2, 12); q = (x * y) + " \u00F7 " + x; a = y; break;
      case 5:
        if (rnd(0, 1)) { x = rnd(3, 13); q = x + "\u00B2"; a = x * x; }
        else { x = rnd(2, 9); y = rnd(2, 12); q = "x + " + x + " = " + (x + y) + ",  x = ?"; a = y; }
        break;
      default: x = rnd(2, 9); y = rnd(2, 9); z = rnd(2, 9); q = x + " + " + y + " \u00D7 " + z; a = x + y * z;
    }
    return { q: q, a: a };
  };

  /* ---------- level menu + end screen ---------- */
  A.levelMenu = function (el, game, title, levels, onPick) {
    A._pickCb = onPick;
    A.progress(game, function (done) {
      var h = "<h2>" + title + "</h2><p class='muted'>Reach each level's target to unlock the next level.</p><div class='lvl-grid'>";
      levels.forEach(function (L, i) {
        var n = i + 1, locked = n > done + 1;
        h += "<button class='lvl-btn" + (locked ? " locked" : "") + (n <= done ? " done" : "") + "' " +
             (locked ? "disabled" : "onclick='Arcade._pick(" + n + ")'") + "><b>Level " + n + (n <= done ? " &#10004;" : "") +
             "</b><br>" + L.name + "<br><small>" + L.desc + "</small></button>";
      });
      el.innerHTML = h + "</div>";
      el.style.display = "flex";
    });
  };
  A._pick = function (n) { A.goFull(); if (A._pickCb) A._pickCb(n); };   // a click = allowed to enter fullscreen
  A.endScreen = function (el, o) {
    A._end = o;
    el.innerHTML = "<h1 style='color:" + (o.good ? "#34d399" : "#fb7185") + "'>" + o.title + "</h1><p>" + o.text + "</p><div class='row'>" +
      (o.next ? "<button onclick='Arcade._end.next()'>Next level &rarr;</button>" : "") +
      "<button class='btn-amazon-secondary' onclick='Arcade._end.retry()'>Retry</button>" +
      "<button class='btn-amazon-secondary' onclick='Arcade._end.menu()'>All levels</button></div>";
    el.style.display = "flex";
  };

  /* ---------- fixed-timestep game loop with smooth interpolation ---------- */
  A.loop = function (cfg) {
    var last = 0, acc = 0;
    function f(ts) {
      if (!last) last = ts;
      var dt = Math.min(100, ts - last); last = ts;
      var ms = cfg.tickMs();
      if (ms > 0) {
        acc += dt;
        while (acc >= ms) { acc -= ms; cfg.step(); if (cfg.tickMs() <= 0) { acc = 0; break; } }
      } else acc = 0;
      var m2 = cfg.tickMs();
      cfg.render(m2 > 0 ? acc / m2 : 1);
      requestAnimationFrame(f);
    }
    requestAnimationFrame(f);
  };

  /* ---------- snake renderer (grid cell -> smooth slide) ---------- */
  A.drawSnake = function (ctx, s, alpha, cs, pal) {
    var n = s.body.length, i, pts = [];
    for (i = 0; i < n; i++) {
      var c = s.body[i], p = (s.prev && (s.prev[i] || s.prev[s.prev.length - 1])) || c;
      pts.push({ x: (p.x + (c.x - p.x) * alpha + 0.5) * cs, y: (p.y + (c.y - p.y) * alpha + 0.5) * cs });
    }
    for (i = n - 1; i >= 0; i--) {
      var r = cs * (0.47 - 0.13 * i / n), q = pts[i];
      ctx.fillStyle = "rgba(0,0,0,.28)"; ctx.beginPath(); ctx.arc(q.x + 2, q.y + 3, r, 0, 6.2832); ctx.fill();
      ctx.fillStyle = i % 2 ? pal.a : pal.b; ctx.beginPath(); ctx.arc(q.x, q.y, r, 0, 6.2832); ctx.fill();
      if (i % 3 === 1) { ctx.fillStyle = pal.dark; ctx.beginPath(); ctx.arc(q.x, q.y, r * 0.5, 0, 6.2832); ctx.fill(); }
    }
    var h = pts[0], dx = s.dir.dx, dy = s.dir.dy, r0 = cs * 0.5;
    ctx.fillStyle = pal.a; ctx.beginPath(); ctx.arc(h.x, h.y, r0, 0, 6.2832); ctx.fill();
    [-1, 1].forEach(function (sd) {
      var ex = h.x + dx * r0 * 0.35 - dy * sd * r0 * 0.45, ey = h.y + dy * r0 * 0.35 + dx * sd * r0 * 0.45;
      ctx.fillStyle = "#fff59d"; ctx.beginPath(); ctx.arc(ex, ey, r0 * 0.28, 0, 6.2832); ctx.fill();
      ctx.fillStyle = "#000"; ctx.beginPath(); ctx.arc(ex + dx * 1.2, ey + dy * 1.2, r0 * 0.13, 0, 6.2832); ctx.fill();
    });
    if (Math.sin(Date.now() / 130) > 0.6) {
      ctx.strokeStyle = "#e53935"; ctx.lineWidth = 1.5; ctx.beginPath();
      ctx.moveTo(h.x + dx * r0, h.y + dy * r0);
      ctx.lineTo(h.x + dx * (r0 + 8), h.y + dy * (r0 + 8));
      ctx.lineTo(h.x + dx * (r0 + 12) - dy * 3, h.y + dy * (r0 + 12) + dx * 3);
      ctx.moveTo(h.x + dx * (r0 + 8), h.y + dy * (r0 + 8));
      ctx.lineTo(h.x + dx * (r0 + 12) + dy * 3, h.y + dy * (r0 + 12) - dx * 3);
      ctx.stroke();
    }
  };

  /* ---------- fullscreen + fit-to-screen ---------- */
  A.isFull = function () { return !!(document.fullscreenElement || document.webkitFullscreenElement); };
  A.goFull = function () {
    var b = document.getElementById("gamebox");
    if (A.touch || !b || A.isFull()) return;      // phones already use the whole screen
    var f = b.requestFullscreen || b.webkitRequestFullscreen;
    if (f) { try { var pr = f.call(b); if (pr && pr.catch) pr.catch(function () {}); } catch (e) {} }
  };
  A.toggleFull = function () {
    if (A.isFull()) { var x = document.exitFullscreen || document.webkitExitFullscreen; if (x) x.call(document); }
    else A.goFull();
  };
  // Desktop fullscreen: the canvas is scaled to fill the space under the question bar.
  // Phones: the canvas is scaled so board + on-screen pad fit on the screen.
  var lastLand = null;
  function fitTouch(cv) {
    var box = document.getElementById("gamebox"), pad = document.getElementById("tpad");
    var cs = window.getComputedStyle(box);
    var availW = box.clientWidth - parseFloat(cs.paddingLeft) - parseFloat(cs.paddingRight);
    var land = window.innerWidth > window.innerHeight, reserveH = 0;
    if (pad) {
      if (land) {
        var side = pad.className.indexOf("lr") >= 0 ? 104 : pad.offsetWidth + 18;
        availW = Math.min(availW, window.innerWidth - 2 * side);
      } else reserveH = pad.offsetHeight + 20;
      document.body.style.paddingBottom = land ? "" : (reserveH + 6) + "px";
    }
    var ref = (land && box.querySelector(".hud")) || cv;
    var scrollY = window.pageYOffset || 0;
    var cvTop = cv.getBoundingClientRect().top + scrollY;
    var target = land ? Math.max(0, ref.getBoundingClientRect().top + scrollY - 6) : scrollY;
    var availH = window.innerHeight - (land ? cvTop - target : Math.max(0, cvTop - scrollY)) - reserveH - 10;
    if (availH < 170) availH = 170;
    var sc = Math.min(availW / cv.width, availH / cv.height, 1.6);
    if (sc > 0) { cv.style.width = Math.floor(cv.width * sc) + "px"; cv.style.height = Math.floor(cv.height * sc) + "px"; }
    if (land && lastLand !== true) window.scrollTo(0, target);   // phone turned sideways: hide the menu bar, show the game
    lastLand = land;
  }
  A.fit = function () {
    var cv = document.querySelector ? document.querySelector("#gamebox canvas") : null;
    var btns = document.querySelectorAll ? document.querySelectorAll(".fs-btn") : [];
    for (var i = 0; i < btns.length; i++) btns[i].textContent = A.isFull() ? "Exit fullscreen" : "Fullscreen";
    if (!cv) return;
    cv.style.width = ""; cv.style.height = "";
    if (A.touch) { fitTouch(cv); return; }
    if (!A.isFull()) return;
    var top = cv.parentNode.getBoundingClientRect().top;
    var s = Math.min((window.innerWidth - 24) / cv.width, (window.innerHeight - top - 14) / cv.height);
    if (s > 0) { cv.style.width = Math.floor(cv.width * s) + "px"; cv.style.height = Math.floor(cv.height * s) + "px"; }
  };

  /* ---------- on-screen controls for phones ----------
     The games read keyboard events, so the touch controls simply send the same keys:
     swipe / arrow pad -> ArrowUp/Down/Left/Right.   (<div id="gamebox" data-touch="dpad|lr">) */
  function sendKey(type, key) {
    var ev;
    try { ev = new KeyboardEvent(type, { key: key, bubbles: true, cancelable: true }); }
    catch (e) { ev = document.createEvent("Event"); ev.initEvent(type, true, true); ev.key = key; }
    document.dispatchEvent(ev);
  }
  function bindHold(btn, key) {
    var down = false;
    function press(e) {
      e.preventDefault();
      if (down) return;
      down = true; btn.classList.add("on"); sendKey("keydown", key);
    }
    function release(e) {
      if (e && e.preventDefault) e.preventDefault();
      if (!down) return;
      down = false; btn.classList.remove("on"); sendKey("keyup", key);
    }
    btn.addEventListener("pointerdown", function (e) { try { btn.setPointerCapture(e.pointerId); } catch (x) {} press(e); });
    btn.addEventListener("pointerup", release);
    btn.addEventListener("pointercancel", release);
    btn.addEventListener("lostpointercapture", release);
    btn.addEventListener("contextmenu", function (e) { e.preventDefault(); });
  }
  function bindSwipe(cv) {            // swipe anywhere on the board to turn the snake
    var id = null, sx = 0, sy = 0;
    cv.addEventListener("pointerdown", function (e) { id = e.pointerId; sx = e.clientX; sy = e.clientY; });
    cv.addEventListener("pointermove", function (e) {
      if (id !== e.pointerId) return;
      var dx = e.clientX - sx, dy = e.clientY - sy;
      if (Math.abs(dx) < 16 && Math.abs(dy) < 16) return;
      var k = Math.abs(dx) > Math.abs(dy) ? (dx > 0 ? "ArrowRight" : "ArrowLeft") : (dy > 0 ? "ArrowDown" : "ArrowUp");
      sendKey("keydown", k); sendKey("keyup", k);
      sx = e.clientX; sy = e.clientY;          // allows another swipe without lifting the finger
    });
    function end() { id = null; }
    cv.addEventListener("pointerup", end);
    cv.addEventListener("pointercancel", end);
  }
  function bindHalves(cv) {           // hold the left / right half of the board to steer left / right
    var cur = {};
    cv.addEventListener("pointerdown", function (e) {
      var r = cv.getBoundingClientRect(), k = (e.clientX - r.left) < r.width / 2 ? "ArrowLeft" : "ArrowRight";
      cur[e.pointerId] = k;
      try { cv.setPointerCapture(e.pointerId); } catch (x) {}
      sendKey("keydown", k);
    });
    function up(e) { var k = cur[e.pointerId]; if (k) { delete cur[e.pointerId]; sendKey("keyup", k); } }
    cv.addEventListener("pointerup", up);
    cv.addEventListener("pointercancel", up);
  }
  A.initTouch = function () {
    if (!A.touch || document.getElementById("tpad")) return;
    var box = document.getElementById("gamebox");
    if (!box) return;
    var mode = box.getAttribute("data-touch"), cv = box.querySelector("canvas");
    if (!mode || !cv) return;
    var pad = document.createElement("div");
    pad.id = "tpad"; pad.className = "tpad " + mode;
    function mk(label, key, cls) {
      var b = document.createElement("button");
      b.type = "button"; b.className = "tb " + cls; b.innerHTML = label;
      bindHold(b, key); pad.appendChild(b);
    }
    if (mode === "lr") { mk("&#9664;", "ArrowLeft", "l"); mk("&#9654;", "ArrowRight", "r"); bindHalves(cv); }
    else { mk("&#9650;", "ArrowUp", "u"); mk("&#9664;", "ArrowLeft", "l"); mk("&#9660;", "ArrowDown", "d"); mk("&#9654;", "ArrowRight", "r"); bindSwipe(cv); }
    document.body.appendChild(pad);
    A.fit();
    setTimeout(A.fit, 300); setTimeout(A.fit, 1200);     // again after fonts / layout settle
  };

  if (typeof document !== "undefined" && document.addEventListener) {
    document.addEventListener("fullscreenchange", function () { setTimeout(A.fit, 50); });
    document.addEventListener("webkitfullscreenchange", function () { setTimeout(A.fit, 50); });
  }
  if (typeof window !== "undefined" && window.addEventListener) {
    var lw = 0, lh = 0, tm = null;
    window.addEventListener("resize", function () {          // ignore the small height jumps of a hiding address bar
      clearTimeout(tm);
      tm = setTimeout(function () {
        if (window.innerWidth !== lw || Math.abs(window.innerHeight - lh) > 80) { lw = window.innerWidth; lh = window.innerHeight; A.fit(); }
      }, 150);
    });
    window.addEventListener("orientationchange", function () { setTimeout(A.fit, 250); });
    window.addEventListener("load", function () { lw = window.innerWidth; lh = window.innerHeight; A.fit(); });
    document.addEventListener("DOMContentLoaded", A.initTouch);
  }
  return A;
})();
