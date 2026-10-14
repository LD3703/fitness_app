// Společné nastavení stránek gymbar.app (stejné hodnoty jako
// kAppLinkScheme, kPlayStoreUrl a kAppStoreUrl v lib/modules/links/deep_links.dart).
//
// Až bude aplikace v obchodě schválená a veřejná, přepni u něj live: true
// (u App Store navíc doplň skutečné ID z App Store Connect → App Information
// → Apple ID) a nasaď web: firebase deploy --only hosting.
// Dokud je live: false, tlačítko se ukáže jako neaktivní „již brzy“.
window.GYMBAR = {
  scheme: 'gymbar',
  stores: {
    play: {
      live: false,
      url: 'https://play.google.com/store/apps/details?id=cz.dedina.fitness_app'
    },
    apple: {
      live: false,
      url: 'https://apps.apple.com/app/id0000000000'
    }
  }
};
