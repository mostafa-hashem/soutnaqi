import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soutnaqi/features/separation/cubit/on_device_model_cubit.dart';
import 'package:soutnaqi/features/separation/cubit/on_device_model_state.dart';
import 'package:soutnaqi/features/separation/data/on_device/on_device_model_repository.dart';

class _FakeOnDeviceModelRepository implements OnDeviceModelRepository {
  bool _isDownloading = false;
  double _progress = 0.0;
  bool _isCached = false;
  int _cachedSize = 0;
  final Set<void Function(double progress)> _listeners = {};

  @override
  bool get isDownloading => _isDownloading;

  @override
  double get currentDownloadProgress => _progress;

  @override
  void addProgressListener(void Function(double progress) listener) {
    _listeners.add(listener);
    if (_progress > 0) listener(_progress);
  }

  @override
  void removeProgressListener(void Function(double progress) listener) {
    _listeners.remove(listener);
  }

  void notifyProgress(double progress) {
    _progress = progress;
    for (final l in List.of(_listeners)) {
      l(progress);
    }
  }

  @override
  Future<bool> isModelCached() async => _isCached;

  @override
  Future<int> cachedModelSizeBytes() async => _cachedSize;

  @override
  Future<void> ensureModelDownloaded({
    void Function(double progress)? onProgress,
  }) async {
    _isDownloading = true;
    if (onProgress != null) addProgressListener(onProgress);
  }

  @override
  void cancelDownload() {
    _isDownloading = false;
    _progress = 0.0;
    _listeners.clear();
  }

  @override
  Future<void> deleteCachedModel() async {
    _isCached = false;
    _cachedSize = 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.flutter.io/path_provider');

  late _FakeOnDeviceModelRepository repository;
  late OnDeviceModelCubit cubit;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });
    repository = _FakeOnDeviceModelRepository();
    cubit = OnDeviceModelCubit(repository: repository);
  });

  tearDown(() async {
    await cubit.close();
  });

  test('refresh transitions to ready when model is cached', () async {
    repository._isCached = true;
    repository._cachedSize = 66762490;

    await cubit.refresh();

    expect(cubit.state.status, OnDeviceModelStatus.ready);
    expect(cubit.state.cachedSizeBytes, 66762490);
  });

  test('refresh transitions to notDownloaded when model is not cached', () async {
    repository._isCached = false;

    await cubit.refresh();

    expect(cubit.state.status, OnDeviceModelStatus.notDownloaded);
  });

  test('refresh preserves downloading status and current progress when downloading', () async {
    repository._isDownloading = true;
    repository._progress = 0.45;

    await cubit.refresh();

    expect(cubit.state.status, OnDeviceModelStatus.downloading);
    expect(cubit.state.downloadProgress, 0.45);
  });

  test('progress listener forwards progress events while downloading', () async {
    await cubit.download();
    expect(cubit.state.status, OnDeviceModelStatus.downloading);

    repository.notifyProgress(0.35);
    expect(cubit.state.downloadProgress, 0.35);

    repository.notifyProgress(0.72);
    expect(cubit.state.downloadProgress, 0.72);
  });

  test('cancelDownload stops download and resets status', () {
    repository._isDownloading = true;
    cubit.cancelDownload();

    expect(cubit.state.status, OnDeviceModelStatus.notDownloaded);
    expect(repository.isDownloading, isFalse);
  });
}
