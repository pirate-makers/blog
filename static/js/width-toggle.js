/**
 * Wide layout toggle.
 *
 * The saved choice is applied before first paint by an inline script in
 * layouts/partials/head.html; this file only handles the user interaction.
 */
(function () {
  var toggle = document.querySelector(".width-toggle");
  if (!toggle) return;

  function switchWidth() {
    var wide = document.documentElement.getAttribute("data-width") === "wide";
    if (wide) {
      document.documentElement.removeAttribute("data-width");
      try { localStorage.setItem("width", "normal"); } catch (e) {}
    } else {
      document.documentElement.setAttribute("data-width", "wide");
      try { localStorage.setItem("width", "wide"); } catch (e) {}
    }
  }

  toggle.addEventListener("click", switchWidth, false);
  toggle.addEventListener("keydown", function (e) {
    if (e.key === "Enter" || e.key === " ") {
      e.preventDefault();
      switchWidth();
    }
  }, false);
})();
