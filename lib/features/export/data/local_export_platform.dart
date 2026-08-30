import 'package:soutnaqi/features/export/data/local_export_service.dart';
import 'package:soutnaqi/features/export/data/local_export_service_stub.dart'
    if (dart.library.io) 'package:soutnaqi/features/export/data/local_export_service_io.dart';

LocalExportService createLocalExportService() =>
    createPlatformLocalExportService();
