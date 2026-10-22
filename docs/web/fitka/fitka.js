// Logika stránky gymbar.app/fitka (index.html, docs/fitka.md):
// jazyk cs/en, hledání posilovny přes /api/gyms, tisk plakátu A4/A3
// a archu samolepek na stroje. Bez knihoven kromě qrcode.js (MIT).
(function () {
  var G = window.GYMBAR || {};
  var S = window.FITKA_STRINGS;
  var EX = window.GYMBAR_EXERCISES || [];
  var DEFAULTS = window.GYMBAR_STICKER_DEFAULTS || [];
  var BASE = 'https://gymbar.app';
  var PER_SHEET = 12;

  var lang = G.pickLang ? G.pickLang(['en', 'cs']) : 'cs';
  var t = S[lang];
  var gym = null;
  var picked = {};

  function $(id) { return document.getElementById(id); }
  function fmt(s, vars) {
    return s.replace(/\{(\w+)\}/g, function (m, k) { return vars[k] != null ? String(vars[k]) : m; });
  }
  function el(tag, cls, text) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text != null) e.textContent = text;
    return e;
  }
  function exName(e) { return lang === 'cs' ? e.cs : e.en; }

  // ------------------------------------------------------------ jazyk

  function applyLang(l, save) {
    lang = l;
    t = S[l];
    document.documentElement.lang = l;
    document.title = t.pageTitle;
    var nodes = document.querySelectorAll('[data-t]');
    for (var i = 0; i < nodes.length; i++) nodes[i].textContent = t[nodes[i].getAttribute('data-t')];
    $('q').placeholder = t.searchPlaceholder;
    var b = document.querySelectorAll('.lang [data-set]');
    for (var j = 0; j < b.length; j++) {
      b[j].setAttribute('aria-pressed', String(b[j].getAttribute('data-set') === l));
    }
    if (save) {
      try { localStorage.setItem('gymbar.lang', l); } catch (e) { /* bez úložiště */ }
    }
    if (gym) showGym(gym);
    renderPicks();
  }

  // ------------------------------------------------------------ hledání

  var timer = null;
  var seq = 0;

  function api(params) {
    return fetch('/api/gyms?' + new URLSearchParams(params).toString(), { headers: { Accept: 'application/json' } })
      .then(function (r) {
        if (!r.ok && r.status !== 400) throw new Error('HTTP ' + r.status);
        return r.json();
      })
      .then(function (j) { return (j && j.gyms) || []; });
  }

  function place(g) {
    return [g.city, g.address].filter(function (x) { return x; }).join(' · ');
  }

  function search(q) {
    var my = ++seq;
    var list = $('results');
    if (q.trim().length < 2) {
      list.innerHTML = '';
      $('status').textContent = '';
      return;
    }
    $('status').textContent = t.searching;
    api({ q: q }).then(function (gyms) {
      if (my !== seq) return;
      list.innerHTML = '';
      $('status').textContent = gyms.length ? '' : t.noResults;
      gyms.forEach(function (g) {
        var li = el('li');
        var b = el('button');
        b.type = 'button';
        b.appendChild(el('span', 'name', g.name));
        b.appendChild(el('span', 'place', place(g)));
        b.addEventListener('click', function () { select(g); });
        li.appendChild(b);
        list.appendChild(li);
      });
    }).catch(function () {
      if (my === seq) $('status').textContent = t.searchError;
    });
  }

  function select(g) {
    gym = g;
    try {
      var url = new URL(location.href);
      url.searchParams.set('gym', g.id);
      history.replaceState(null, '', url.pathname + url.search);
    } catch (e) { /* starý prohlížeč */ }
    showGym(g);
    $('searchPanel').hidden = true;
    $('kit').hidden = false;
    $('kit').scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  function showGym(g) {
    $('gymName').textContent = g.name;
    $('gymPlace').textContent = place(g);
    var m = $('members');
    m.hidden = !(g.members >= 5);
    if (!m.hidden) m.textContent = fmt(t.members, { n: g.members });
  }

  // ------------------------------------------------------------ samolepky

  function stickerExercises() {
    return EX.filter(function (e) { return e.st; })
      .sort(function (a, b) { return exName(a).localeCompare(exName(b), lang); });
  }

  function setDefaults() {
    picked = {};
    DEFAULTS.forEach(function (s) { picked[s] = true; });
  }

  function pickedList() {
    return stickerExercises().filter(function (e) { return picked[e.s]; });
  }

  function renderPicks() {
    var box = $('picks');
    box.innerHTML = '';
    stickerExercises().forEach(function (e) {
      var label = el('label');
      var cb = document.createElement('input');
      cb.type = 'checkbox';
      cb.checked = !!picked[e.s];
      cb.addEventListener('change', function () {
        picked[e.s] = cb.checked;
        updateCount();
      });
      label.appendChild(cb);
      label.appendChild(el('span', null, exName(e)));
      box.appendChild(label);
    });
    updateCount();
  }

  function updateCount() {
    $('pickCount').textContent = fmt(t.stickersCount, { n: pickedList().length });
  }

  // ------------------------------------------------------------ tisk

  /** QR kód jako SVG (tichá zóna 4 moduly, korekce M). */
  function qrSvg(text) {
    var qr = window.qrcode(0, 'M');
    qr.addData(text);
    qr.make();
    var n = qr.getModuleCount();
    var q = 4;
    var d = '';
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (qr.isDark(r, c)) d += 'M' + (c + q) + ' ' + (r + q) + 'h1v1h-1z';
      }
    }
    var size = n + 2 * q;
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ' + size + ' ' + size +
      '" shape-rendering="crispEdges"><rect width="' + size + '" height="' + size +
      '" fill="#fff"/><path d="' + d + '" fill="#000"/></svg>';
  }

  function qrBox(cls, text) {
    var box = el('div', cls);
    box.innerHTML = qrSvg(text);
    return box;
  }

  function logo() {
    var img = document.createElement('img');
    img.src = '/favicon.svg';
    img.alt = '';
    return img;
  }

  function printNode(node, pageCss) {
    var root = $('print');
    root.innerHTML = '';
    root.appendChild(node);
    $('page-size').textContent = pageCss;
    var go = function () { window.print(); };
    // Písmo a obrázky musí být načtené, jinak by se vytiskly bez nich.
    var imgs = Array.prototype.slice.call(root.querySelectorAll('img'));
    var loaded = Promise.all(imgs.map(function (i) {
      return i.complete ? null : new Promise(function (res) { i.onload = i.onerror = res; });
    }));
    var fonts = document.fonts && document.fonts.ready ? document.fonts.ready : Promise.resolve();
    Promise.all([loaded, fonts]).then(function () { setTimeout(go, 50); });
  }

  function gymUrl(g) { return BASE + '/gym?code=' + encodeURIComponent(g.code); }
  function exUrl(slug, g) {
    return BASE + '/ex?id=' + encodeURIComponent(slug) + '&gym=' + encodeURIComponent(g.id);
  }

  function printPoster(a3) {
    if (!gym) return;
    var p = el('div', 'poster' + (a3 ? ' a3' : ''));
    var bar = el('div', 'bar');
    bar.appendChild(logo());
    var word = el('b', null, 'Gym');
    word.appendChild(el('span', null, 'Bar'));
    bar.appendChild(word);
    bar.appendChild(el('em', null, t.posterKicker));
    p.appendChild(bar);
    p.appendChild(el('h3', null, t.posterHeadline));
    p.appendChild(el('p', 'gym', gym.name));
    p.appendChild(el('p', 'plead', fmt(t.posterLead, { gym: gym.name })));
    p.appendChild(qrBox('qr', gymUrl(gym)));
    p.appendChild(el('p', 'scan', t.posterScan));
    var code = el('p', 'code', t.posterCode + ': ');
    code.appendChild(el('b', null, gym.code));
    p.appendChild(code);
    p.appendChild(el('div', 'pfoot', t.posterFooter));
    printNode(p, '@page { size: ' + (a3 ? 'A3' : 'A4') + ' portrait; margin: 0; }');
  }

  function printStickers() {
    if (!gym) return;
    var list = pickedList();
    if (!list.length) {
      $('pickCount').textContent = t.stickersNone;
      return;
    }
    var wrap = el('div');
    for (var i = 0; i < list.length; i += PER_SHEET) {
      var sheet = el('div', 'sheet');
      list.slice(i, i + PER_SHEET).forEach(function (e) {
        var s = el('div', 'sticker');
        var top = el('p', 'stop');
        top.appendChild(logo());
        top.appendChild(el('span', null, t.stickerLabel));
        s.appendChild(top);
        s.appendChild(qrBox('qr', exUrl(e.s, gym)));
        s.appendChild(el('p', 'ex', exName(e)));
        s.appendChild(el('p', 'sscan', t.stickerScan));
        sheet.appendChild(s);
      });
      wrap.appendChild(sheet);
    }
    printNode(wrap, '@page { size: A4 portrait; margin: 0; }');
  }

  // ------------------------------------------------------------ start

  function init() {
    setDefaults();
    var b = document.querySelectorAll('.lang [data-set]');
    for (var i = 0; i < b.length; i++) {
      b[i].addEventListener('click', function (ev) {
        applyLang(ev.currentTarget.getAttribute('data-set'), true);
      });
    }
    $('q').addEventListener('input', function (ev) {
      clearTimeout(timer);
      var q = ev.target.value;
      timer = setTimeout(function () { search(q); }, 300);
    });
    $('change').addEventListener('click', function () {
      $('kit').hidden = true;
      $('searchPanel').hidden = false;
      $('q').focus();
    });
    $('posterA4').addEventListener('click', function () { printPoster(false); });
    $('posterA3').addEventListener('click', function () { printPoster(true); });
    $('stickersPrint').addEventListener('click', printStickers);
    $('pickDefaults').addEventListener('click', function () { setDefaults(); renderPicks(); });
    $('pickNone').addEventListener('click', function () { picked = {}; renderPicks(); });
    window.addEventListener('afterprint', function () { $('print').innerHTML = ''; });
    applyLang(lang, false);

    // ?gym=<id> z doporučení člena → rovnou předvybrat.
    var pre = new URLSearchParams(location.search).get('gym');
    if (pre && /^[A-Za-z0-9_-]{3,64}$/.test(pre)) {
      api({ id: pre }).then(function (gyms) { if (gyms[0]) select(gyms[0]); }).catch(function () {});
    }
  }

  init();
})();
