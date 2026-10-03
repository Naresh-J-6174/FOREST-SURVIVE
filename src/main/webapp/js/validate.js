// Experiment 1 (JavaScript validation) + Experiment 6 (AJAX username check)
function validateRegister() {
  var u = document.getElementById("username").value;
  var p = document.getElementById("password").value;
  if (!/^[A-Za-z0-9_]{3,20}$/.test(u)) { alert("Username: 3-20 letters, digits or _"); return false; }
  if (p.length < 4) { alert("Password must be at least 4 characters"); return false; }
  if (document.getElementById("status").dataset.state === "taken") { alert("Username already taken"); return false; }
  return true;
}

function checkUsername() {
  var u = document.getElementById("username").value;
  var st = document.getElementById("status");
  if (u.length < 3) { st.textContent = ""; return; }
  var xhr = new XMLHttpRequest();
  xhr.onreadystatechange = function () {
    if (xhr.readyState === 4 && xhr.status === 200) {
      var r = xhr.responseText.trim();
      st.dataset.state = r;
      st.textContent = r === "taken" ? "Username taken" : "Username available";
      st.style.color = r === "taken" ? "red" : "green";
    }
  };
  xhr.open("GET", "checkUser?username=" + encodeURIComponent(u), true);
  xhr.send();
}
