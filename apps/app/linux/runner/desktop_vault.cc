#include "desktop_vault.h"
#include <libsecret/secret.h>
#include <cstring>

namespace {
constexpr gsize kMaxPlain = 512 * 1024;
const SecretSchema kSchema = {
    "app.heisuca.player.desktop.connections", SECRET_SCHEMA_NONE,
    {{"application", SECRET_SCHEMA_ATTRIBUTE_STRING}, {nullptr, SECRET_SCHEMA_ATTRIBUTE_STRING}},
    0, nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, nullptr};
struct Request {
  FlMethodCall* call;
  GCancellable* cancel;
  gchar* payload;
  guint timer = 0;
  bool write;
  ~Request() {
    if (timer) g_source_remove(timer);
    if (payload) { secret_password_wipe(payload); g_free(payload); }
    g_object_unref(cancel);
    g_object_unref(call);
  }
};
void reply_error(FlMethodCall* call, const char* code) {
  g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(
      fl_method_error_response_new(code, "Não foi possível acessar as conexões protegidas.", nullptr));
  fl_method_call_respond(call, response, nullptr);
}
bool unavailable(GError* error) {
  return error && (g_error_matches(error, G_DBUS_ERROR, G_DBUS_ERROR_SERVICE_UNKNOWN) ||
      g_error_matches(error, G_DBUS_ERROR, G_DBUS_ERROR_NAME_HAS_NO_OWNER) ||
      g_error_matches(error, G_IO_ERROR, G_IO_ERROR_NOT_FOUND) ||
      g_error_matches(error, G_IO_ERROR, G_IO_ERROR_CONNECTION_REFUSED) ||
      g_error_matches(error, G_IO_ERROR, G_IO_ERROR_NOT_CONNECTED));
}
gboolean cancel_request(gpointer data) {
  auto* request = static_cast<Request*>(data);
  request->timer = 0;
  g_cancellable_cancel(request->cancel);
  return G_SOURCE_REMOVE;
}
void work(GTask* task, gpointer, gpointer data, GCancellable* cancel) {
  auto* request = static_cast<Request*>(data);
  GError* error = nullptr;
  if (request->write) {
    const bool ok = secret_password_store_sync(&kSchema, SECRET_COLLECTION_DEFAULT,
        "Heisuca — conexões", request->payload, cancel, &error,
        "application", "app.heisuca.player.desktop", nullptr);
    if (error) g_task_return_error(task, error);
    else g_task_return_boolean(task, ok);
  } else {
    gchar* value = secret_password_lookup_sync(&kSchema, cancel, &error,
        "application", "app.heisuca.player.desktop", nullptr);
    if (error) g_task_return_error(task, error);
    else g_task_return_pointer(task, value, reinterpret_cast<GDestroyNotify>(secret_password_free));
  }
}
void finished(GObject*, GAsyncResult* result, gpointer) {
  GTask* task = G_TASK(result);
  auto* request = static_cast<Request*>(g_task_get_task_data(task));
  if (request->timer) { g_source_remove(request->timer); request->timer = 0; }
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlValue) value = nullptr;
  if (request->write) {
    const bool ok = g_task_propagate_boolean(task, &error);
    if (!ok || error) { reply_error(request->call, "keyringFailed"); return; }
    value = fl_value_new_bool(true);
  } else {
    gchar* text = static_cast<gchar*>(g_task_propagate_pointer(task, &error));
    if (error) {
      reply_error(request->call, unavailable(error) ? "keyringUnavailable" : "keyringFailed");
      return;
    }
    if (text) {
      if (std::strlen(text) > 1024 * 1024) {
        secret_password_free(text); reply_error(request->call, "keyringFailed"); return;
      }
      gsize size = 0;
      guchar* bytes = g_base64_decode(text, &size);
      secret_password_free(text);
      if (size > kMaxPlain) {
        if (size) std::memset(bytes, 0, size);
      g_free(bytes);
        reply_error(request->call, "keyringFailed"); return;
      }
      value = fl_value_new_uint8_list(bytes, size);
      if (size) std::memset(bytes, 0, size);
      g_free(bytes);
    } else value = fl_value_new_null();
  }
  g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_success_response_new(value));
  fl_method_call_respond(request->call, response, nullptr);
}
void handle(FlMethodChannel*, FlMethodCall* call, gpointer) {
  const char* method = fl_method_call_get_name(call);
  const bool write = std::strcmp(method, "write") == 0;
  if (!write && std::strcmp(method, "read") != 0) {
    g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
    fl_method_call_respond(call, response, nullptr); return;
  }
  gchar* payload = nullptr;
  if (write) {
    FlValue* args = fl_method_call_get_args(call);
    if (fl_value_get_type(args) != FL_VALUE_TYPE_UINT8_LIST || fl_value_get_length(args) > kMaxPlain) {
      reply_error(call, "keyringFailed"); return;
    }
    payload = g_base64_encode(fl_value_get_uint8_list(args), fl_value_get_length(args));
  }
  auto* request = new Request{FL_METHOD_CALL(g_object_ref(call)), g_cancellable_new(), payload, 0, write};
  g_autoptr(GTask) task = g_task_new(nullptr, request->cancel, finished, nullptr);
  g_task_set_task_data(task, request, [](gpointer data) { delete static_cast<Request*>(data); });
  request->timer = g_timeout_add_seconds(10, cancel_request, request);
  g_task_run_in_thread(task, work);
}
}  // namespace
void heisuca_desktop_vault_register(FlView* view) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* channel = fl_method_channel_new(fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "heisuca/desktop_vault", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, handle, nullptr, nullptr);
  g_object_set_data_full(G_OBJECT(view), "heisuca-desktop-vault", channel, g_object_unref);
}
