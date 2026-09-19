// lib/providers/download_provider.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/agent_models.dart';

enum DownloadStatus { idle, downloading, complete, error }

class DownloadState {
  const DownloadState({
    this.status       = DownloadStatus.idle,
    this.progress     = 0.0,
    this.speed        = '',
    this.errorMessage = '',
    this.savePath     = '',
  });

  final DownloadStatus status;
  final double         progress;  // 0.0–1.0
  final String         speed;
  final String         errorMessage;
  final String         savePath;

  bool   get isDownloading  => status == DownloadStatus.downloading;
  String get percentLabel   => '${(progress * 100).toStringAsFixed(1)}%';

  DownloadState copyWith({
    DownloadStatus? status,
    double?  progress,
    String?  speed,
    String?  errorMessage,
    String?  savePath,
  }) => DownloadState(
    status:       status       ?? this.status,
    progress:     progress     ?? this.progress,
    speed:        speed        ?? this.speed,
    errorMessage: errorMessage ?? this.errorMessage,
    savePath:     savePath     ?? this.savePath,
  );
}

class DownloadNotifier extends StateNotifier<DownloadState> {
  DownloadNotifier() : super(const DownloadState());

  final Dio _dio = Dio();
  CancelToken? _cancel;
  DateTime? _t0;
  int _lastBytes = 0;

  Future<String> _dir() async {
    if (Platform.isAndroid) {
      if ((await Permission.manageExternalStorage.request()).isGranted) {
        const p = '/storage/emulated/0/Download/JackModels';
        await Directory(p).create(recursive: true);
        return p;
      }
    }
    final d = await getApplicationDocumentsDirectory();
    final dir = Directory('${d.path}/JackModels');
    await dir.create(recursive: true);
    return dir.path;
  }

  Future<void> start(ModelDef model) async {
    if (state.isDownloading) return;
    _cancel = CancelToken();
    _t0 = DateTime.now();
    _lastBytes = 0;
    state = const DownloadState(status: DownloadStatus.downloading);

    try {
      final path = '${await _dir()}/${model.filename}';
      await _dio.download(
        model.downloadUrl, path,
        cancelToken: _cancel,
        onReceiveProgress: (recv, total) {
          if (total <= 0) return;
          final now = DateTime.now();
          final elapsed =
              now.difference(_t0!).inMilliseconds / 1000.0;
          String spd = state.speed;
          if (elapsed > 0.3) {
            final mb = ((recv - _lastBytes) / elapsed) / (1024 * 1024);
            spd = '${mb.toStringAsFixed(1)} MB/s';
            _t0 = now;
            _lastBytes = recv;
          }
          state = state.copyWith(
              progress: recv / total, speed: spd, savePath: path);
        },
      );
      state = state.copyWith(
          status: DownloadStatus.complete, progress: 1.0);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        state = const DownloadState();
      } else {
        state = state.copyWith(
            status: DownloadStatus.error,
            errorMessage: e.message ?? 'Failed');
      }
    }
  }

  void cancel() {
    _cancel?.cancel();
    state = const DownloadState();
  }
}

final downloadProvider =
    StateNotifierProvider.family<DownloadNotifier, DownloadState, String>(
  (_, id) => DownloadNotifier(),
);
