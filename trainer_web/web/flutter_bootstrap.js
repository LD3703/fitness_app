// Vlastní zavaděč (šablona Flutteru): po startu aplikace schová „GymBar…“.
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    const loading = document.getElementById('loading');
    if (loading) loading.remove();
    await appRunner.runApp();
  },
});
