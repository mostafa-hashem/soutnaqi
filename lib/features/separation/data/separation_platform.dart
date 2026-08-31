import 'package:soutnaqi/core/config/app_env.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_separation_service_stub.dart'
    if (dart.library.io) 'package:soutnaqi/features/separation/data/on_device/on_device_separation_service.dart'
    as on_device_impl;
import 'package:soutnaqi/features/separation/data/separation_service.dart';
import 'package:soutnaqi/features/separation/data/separation_service_stub.dart'
    if (dart.library.io) 'package:soutnaqi/features/separation/data/local_separation_service.dart'
    as local_impl;
import 'package:soutnaqi/features/separation/data/separation_service_stub.dart'
    if (dart.library.io) 'package:soutnaqi/features/separation/data/replicate_separation_service.dart'
    as cloud_impl;

/// Local server / Replicate stay opt-in via dart-define, unchanged. When
/// neither is configured, on-device separation (fully offline after a
/// one-time model download) is the default rather than the old dead-end
/// stub — see the "letes-plan-for-b" on-device separation plan.
SeparationService createSeparationService() {
  if (AppEnv.isLocalSeparationConfigured) {
    return local_impl.createLocalSeparationService();
  }
  if (AppEnv.isReplicateSeparationConfigured) {
    return cloud_impl.createPlatformSeparationService();
  }
  return on_device_impl.createOnDeviceSeparationService();
}
