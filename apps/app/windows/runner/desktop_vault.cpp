#include "pch.h"

#include "desktop_vault.h"

#include <windows.h>
#include <wincrypt.h>
#include <dpapi.h>

#include <cstdint>
#include <string>
#include <vector>
#include <utility>

namespace {

constexpr size_t kMaxPayloadSizeBytes = 1024 * 1024;
constexpr size_t kMaxPlainPayloadSizeBytes = 512 * 1024;
struct ScopedBlob {
  DATA_BLOB data{};
  ~ScopedBlob() {
    if (data.pbData != nullptr) {
      ::SecureZeroMemory(data.pbData, data.cbData);
      ::LocalFree(data.pbData);
    }
  }
};

void HandleProtect(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* args = call.arguments();
  if (!args) {
    result->Error("INVALID_ARGUMENT", "Missing arguments");
    return;
  }

  const auto* bytes = std::get_if<std::vector<uint8_t>>(args);
  if (!bytes) {
    result->Error("INVALID_ARGUMENT", "Payload must be a byte array");
    return;
  }

  if (bytes->empty()) {
    result->Error("INVALID_ARGUMENT", "Empty payload");
    return;
  }
  if (bytes->size() > kMaxPlainPayloadSizeBytes) {
    result->Error("PAYLOAD_TOO_LARGE", "Payload exceeds maximum allowed size");
    return;
  }

  DATA_BLOB data_in{};
  data_in.cbData = static_cast<DWORD>(bytes->size());
  data_in.pbData = bytes->empty() ? nullptr : const_cast<BYTE*>(reinterpret_cast<const BYTE*>(bytes->data()));

  ScopedBlob out;
  auto& data_out = out.data;
  const BOOL ok = ::CryptProtectData(
      &data_in,
      nullptr,  // szDataDescr
      nullptr,  // pOptionalEntropy: sem segredo fixo
      nullptr,  // pvReserved
      nullptr,  // pPromptStruct
      CRYPTPROTECT_UI_FORBIDDEN,
      &data_out);

  if (!ok) {
    result->Error("PROTECT_FAILED", "Data protection failed");
    return;
  }

  std::vector<uint8_t> output;
  if (data_out.pbData != nullptr && data_out.cbData > 0) {
    output.assign(data_out.pbData, data_out.pbData + data_out.cbData);
  }

  result->Success(flutter::EncodableValue(std::move(output)));
}

void HandleUnprotect(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* args = call.arguments();
  if (!args) {
    result->Error("INVALID_ARGUMENT", "Missing arguments");
    return;
  }

  const auto* bytes = std::get_if<std::vector<uint8_t>>(args);
  if (!bytes) {
    result->Error("INVALID_ARGUMENT", "Payload must be a byte array");
    return;
  }

  if (bytes->empty()) {
    result->Error("INVALID_ARGUMENT", "Empty payload");
    return;
  }
  if (bytes->size() > kMaxPayloadSizeBytes) {
    result->Error("PAYLOAD_TOO_LARGE", "Payload exceeds maximum allowed size");
    return;
  }

  DATA_BLOB data_in{};
  data_in.cbData = static_cast<DWORD>(bytes->size());
  data_in.pbData = bytes->empty() ? nullptr : const_cast<BYTE*>(reinterpret_cast<const BYTE*>(bytes->data()));

  ScopedBlob out;
  auto& data_out = out.data;
  const BOOL ok = ::CryptUnprotectData(
      &data_in,
      nullptr,  // ppszDataDescr
      nullptr,  // pOptionalEntropy: sem segredo fixo
      nullptr,  // pvReserved
      nullptr,  // pPromptStruct
      CRYPTPROTECT_UI_FORBIDDEN,
      &data_out);

  if (!ok) {
    result->Error("UNPROTECT_FAILED", "Data unprotection failed");
    return;
  }

  std::vector<uint8_t> output;
  if (data_out.pbData != nullptr && data_out.cbData > 0) {
    output.assign(data_out.pbData, data_out.pbData + data_out.cbData);
  }

  result->Success(flutter::EncodableValue(std::move(output)));
}

}  // namespace

std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> SetUpDesktopVaultChannel(
    flutter::BinaryMessenger* messenger) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "heisuca/desktop_vault", &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        const std::string& method = call.method_name();
        if (method == "protect") {
          HandleProtect(call, std::move(result));
        } else if (method == "unprotect") {
          HandleUnprotect(call, std::move(result));
        } else {
          result->NotImplemented();
        }
      });

  return channel;
}
