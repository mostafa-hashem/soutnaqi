import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_model_repository.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_model_spec.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'installs the verified bundled model into an empty support directory',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'soutnaqi-offline-model',
      );
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (_) async => directory.path);
      try {
        final repository = OnDeviceModelRepository();
        expect(await repository.cachedModelSizeBytes(), 0);
        final ready = await Future.wait([
          repository.isModelCached(),
          repository.isModelCached(),
        ]);
        expect(ready, [true, true]);
        final model = File(await repository.modelPath());
        expect(await model.length(), OnDeviceModelSpec.expectedSizeBytes);
        expect(
          (await sha256.bind(model.openRead()).first).toString(),
          OnDeviceModelSpec.expectedSha256,
        );
      } finally {
        messenger.setMockMethodCallHandler(channel, null);
        await directory.delete(recursive: true);
      }
    },
    skip: Platform.environment['SOUTNAQI_TEST_BUNDLE'] == null,
  );
}
