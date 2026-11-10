import 'package:flutter/services.dart';

/// Native device bridge (TV detection, device name, performance signals,
/// process-exit diagnostics). Implemented per platform under `app.heisuca/device`.
const MethodChannel deviceChannel = MethodChannel('app.heisuca/device');
