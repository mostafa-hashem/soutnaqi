import 'package:soutnaqi/features/separation/data/separation_service.dart';
import 'package:soutnaqi/features/separation/data/separation_service_stub.dart';

SeparationService createOnDeviceSeparationService() => StubSeparationService();

Future<void> warmUpOnDeviceSeparationIfReady() async {}
