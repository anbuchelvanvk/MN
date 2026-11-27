// MN Family legal pages: contents highlighting, phone contents toggle,
// theme switch, print and back-to-top. Works without JS too.
(function () {
  'use strict';

  var root = document.documentElement;

  // ---- Theme (remembered per browser; falls back to the system setting) ----
  function readTheme() {
    try { return localStorage.getItem('mn-legal-theme'); } catch (e) { return null; }
  }
  function saveTheme(t) {
    try { localStorage.setItem('mn-legal-theme', t); } catch (e) { /* private mode */ }
  }
  var saved = readTheme();
  if (saved === 'light' || saved === 'dark') root.setAttribute('data-theme', saved);

  function currentTheme() {
    var t = root.getAttribute('data-theme');
    if (t) return t;
    return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }

  document.addEventListener('DOMContentLoaded', function () {
    var themeBtn = document.getElementById('themeToggle');
    function paintThemeBtn() {
      if (!themeBtn) return;
      var dark = currentTheme() === 'dark';
      themeBtn.textContent = dark ? '☀' : '☾';
      themeBtn.setAttribute('aria-label', dark ? 'Switch to light theme' : 'Switch to dark theme');
    }
    if (themeBtn) {
      paintThemeBtn();
      themeBtn.addEventListener('click', function () {
        var next = currentTheme() === 'dark' ? 'light' : 'dark';
        root.setAttribute('data-theme', next);
        saveTheme(next);
        paintThemeBtn();
      });
    }

    // ---- Print ----
    var printBtn = document.getElementById('printBtn');
    if (printBtn) printBtn.addEventListener('click', function () { window.print(); });

    // ---- Contents: toggle on phones ----
    var toc = document.querySelector('.toc');
    var tocToggle = document.querySelector('.toc-toggle');
    if (toc && tocToggle) {
      tocToggle.addEventListener('click', function () {
        var open = toc.classList.toggle('open');
        tocToggle.setAttribute('aria-expanded', open ? 'true' : 'false');
      });
      toc.addEventListener('click', function (e) {
        if (e.target.closest('a') && window.innerWidth <= 860) {
          toc.classList.remove('open');
          tocToggle.setAttribute('aria-expanded', 'false');
        }
      });
    }

    // ---- Contents: highlight the section being read ----
    var links = Array.prototype.slice.call(document.querySelectorAll('.toc a[href^="#"]'));
    var byId = {};
    links.forEach(function (a) { byId[a.getAttribute('href').slice(1)] = a; });
    var sections = links
      .map(function (a) { return document.getElementById(a.getAttribute('href').slice(1)); })
      .filter(Boolean);

    function setActive(id) {
      links.forEach(function (a) { a.classList.remove('active'); a.removeAttribute('aria-current'); });
      if (byId[id]) { byId[id].classList.add('active'); byId[id].setAttribute('aria-current', 'true'); }
    }

    if ('IntersectionObserver' in window && sections.length) {
      var visible = {};
      var io = new IntersectionObserver(function (entries) {
        entries.forEach(function (en) { visible[en.target.id] = en.isIntersecting; });
        for (var i = 0; i < sections.length; i++) {
          if (visible[sections[i].id]) { setActive(sections[i].id); break; }
        }
      }, { rootMargin: '-90px 0px -55% 0px', threshold: 0 });
      sections.forEach(function (s) { io.observe(s); });
    }

    // ---- Back to top ----
    var topBtn = document.getElementById('toTop');
    if (topBtn) {
      var onScroll = function () { topBtn.classList.toggle('show', window.scrollY > 600); };
      window.addEventListener('scroll', onScroll, { passive: true });
      onScroll();
      topBtn.addEventListener('click', function () { window.scrollTo({ top: 0, behavior: 'smooth' }); });
    }

    // ---- Footer year ----
    var y = document.getElementById('year');
    if (y) y.textContent = String(new Date().getFullYear());
  });
})();
