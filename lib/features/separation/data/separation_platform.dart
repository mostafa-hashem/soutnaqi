import 'package:soutnaqi/core/config/app_env.dart';
import 'package:soutnaqi/features/separation/data/separation_service.dart';
import 'package:soutnaqi/features/separation/data/separation_service_stub.dart';
import 'package:soutnaqi/features/separation/data/separation_service_stub.dart'
    if (dart.library.io) 'package:soutnaqi/features/separation/data/local_separation_service.dart'
    as local_impl;
import 'package:soutnaqi/features/separation/data/separation_service_stub.dart'
    if (dart.library.io) 'package:soutnaqi/features/separation/data/replicate_separation_service.dart'
    as cloud_impl;

SeparationService createSeparationService() {
  if (AppEnv.isLocalSeparationConfigured) {
    return local_impl.createLocalSeparationService();
  }
  if (AppEnv.isReplicateSeparationConfigured) {
    return cloud_impl.createPlatformSeparationService();
  }
  return StubSeparationService();
}
