// Společný skript stránek gymbar.app (načítá se až za config.js).
//
// - Jazyk: ?lang=xx v adrese → dříve vybraný jazyk → jazyk prohlížeče
//   (slovenština → čeština, když stránka slovenštinu nemá) → angličtina
//   pro všechny ostatní.
// - Přepínač jazyků se vykreslí do prvku s třídou "lang", pokud na
//   stránce je. Obsah v jazycích má atribut data-lang="xx", vybraný jazyk
//   se zapne třídou na <body> (pravidla v CSS stránky).
// - Tlačítka obchodů: prvky s data-store="play" nebo data-store="apple".
//   Odkaz dostanou jen, když je obchod v config.js označený live: true,
//   jinak jsou neaktivní s textem „již brzy“.
(function () {
  var G = window.GYMBAR = window.GYMBAR || {};
  var LANGS = ['en', 'cs', 'sk', 'de', 'es', 'fr', 'it', 'nl', 'pl', 'pt'];
  var NAMES = {
    en: 'English', cs: 'Čeština', sk: 'Slovenčina', de: 'Deutsch', es: 'Español',
    fr: 'Français', it: 'Italiano', nl: 'Nederlands', pl: 'Polski', pt: 'Português'
  };
  var KEY = 'gymbar.lang';

  var SOON = {
    en: 'coming soon', cs: 'již brzy', de: 'bald verfügbar', es: 'muy pronto',
    fr: 'bientôt', sk: 'už čoskoro', it: 'in arrivo', nl: 'binnenkort',
    pl: 'wkrótce', pt: 'em breve'
  };
  var STORE_NAMES = { play: 'Google Play', apple: 'App Store' };

  /** Vybere jazyk z podporovaných (výchozí 'en'). */
  G.pickLang = function (supported, mapSkToCs) {
    supported = supported || LANGS;
    var param = new URLSearchParams(location.search).get('lang');
    if (param && supported.indexOf(param) >= 0) return param;
    try {
      var saved = localStorage.getItem(KEY);
      if (saved && supported.indexOf(saved) >= 0) return saved;
    } catch (e) { /* bez úložiště */ }
    var langs = navigator.languages && navigator.languages.length
      ? navigator.languages : [navigator.language || 'en'];
    for (var i = 0; i < langs.length; i++) {
      var c = String(langs[i] || '').toLowerCase().split('-')[0];
      if (supported.indexOf(c) >= 0) return c;
      if (c === 'sk' && mapSkToCs !== false && supported.indexOf('cs') >= 0) return 'cs';
    }
    return 'en';
  };

  /** Nastaví tlačítka obchodů podle config.js. */
  G.storeButtons = function (lang) {
    var soon = SOON[lang] || SOON.en;
    var els = document.querySelectorAll('[data-store]');
    for (var i = 0; i < els.length; i++) {
      var el = els[i];
      var store = (G.stores || {})[el.getAttribute('data-store')];
      if (!el.hasAttribute('data-label')) el.setAttribute('data-label', el.textContent);
      if (store && store.live) {
        el.href = store.url;
        el.textContent = el.getAttribute('data-label');
        el.classList.remove('soon');
        el.removeAttribute('aria-disabled');
        el.removeAttribute('tabindex');
      } else {
        el.removeAttribute('href');
        el.textContent = STORE_NAMES[el.getAttribute('data-store')] + ' · ' + soon;
        el.classList.add('soon');
        el.setAttribute('aria-disabled', 'true');
        el.setAttribute('tabindex', '-1');
      }
    }
  };

  /** Je aspoň jeden obchod veřejný? */
  G.anyStoreLive = function () {
    var s = G.stores || {};
    return !!((s.play && s.play.live) || (s.apple && s.apple.live));
  };

  function show(lang, save) {
    document.body.classList.remove.apply(document.body.classList, LANGS);
    document.body.classList.add(lang);
    document.documentElement.lang = lang;
    var buttons = document.querySelectorAll('.lang [data-set]');
    for (var i = 0; i < buttons.length; i++) {
      buttons[i].setAttribute('aria-pressed',
        String(buttons[i].getAttribute('data-set') === lang));
    }
    // Titulek: <meta name="title-xx"> nebo první nadpis v daném jazyce.
    var meta = document.querySelector('meta[name="title-' + lang + '"]');
    var h1 = document.querySelector('[data-lang="' + lang + '"] h1, h1[data-lang="' + lang + '"]');
    if (meta) document.title = meta.getAttribute('content');
    else if (h1) document.title = h1.textContent;
    G.storeButtons(lang);
    if (save) {
      try { localStorage.setItem(KEY, lang); } catch (e) { /* bez úložiště */ }
      try {
        var url = new URL(location.href);
        url.searchParams.set('lang', lang);
        history.replaceState(null, '', url.pathname + url.search + url.hash);
      } catch (e) { /* starý prohlížeč */ }
    }
    if (typeof G.onLang === 'function') G.onLang(lang);
  }

  /** Stránka s obsahem v data-lang (úvod, podmínky, podpora…). */
  G.initPage = function () {
    var box = document.querySelector('.lang');
    if (box && !box.children.length) {
      box.setAttribute('role', 'group');
      box.setAttribute('aria-label', 'Language');
      LANGS.forEach(function (l) {
        var b = document.createElement('button');
        b.type = 'button';
        b.setAttribute('data-set', l);
        b.setAttribute('title', NAMES[l]);
        b.setAttribute('aria-label', NAMES[l]);
        b.setAttribute('lang', l);
        b.textContent = l.toUpperCase();
        b.addEventListener('click', function () { show(l, true); });
        box.appendChild(b);
      });
    }
    show(G.pickLang(LANGS), false);
  };

  G.LANGS = LANGS;
})();
