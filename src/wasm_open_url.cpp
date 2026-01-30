#include <emscripten/emscripten.h>

EM_JS(void, molt_open_url_js, (const char* url), {
  if (!url) {
    return;
  }
  const parsed = UTF8ToString(url);
  if (!parsed) {
    return;
  }
  window.open(parsed, "_blank");
});

extern "C" void molt_open_url(const char* url) {
  molt_open_url_js(url);
}
