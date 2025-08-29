import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';

class DownloadTask {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String status;
  final double progress;
  final String? filePath; // To store the path of the downloaded file

  DownloadTask({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    this.status = 'pending',
    this.progress = 0.0,
    this.filePath,
  });

  DownloadTask copyWith({
    String? status,
    double? progress,
    String? filePath,
  }) {
    return DownloadTask(
      id: id,
      title: title,
      thumbnailUrl: thumbnailUrl,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      filePath: filePath ?? this.filePath,
    );
  }
}

class DownloadService extends StateNotifier<List<DownloadTask>> {
  final ApiService _apiService;
  final Dio _dio = Dio();

  DownloadService(this._apiService) : super([]);

  Future<void> startDownload({
    required String url,
    required String formatId,
    String? userId,
    required String title,
    required String thumbnailUrl,
  }) async {
    // 1. Request permissions
    if (!await _requestPermissions()) {
      print('Storage permissions not granted.');
      // Optionally, show a message to the user
      return;
    }

    // 2. Initiate download with backend to get a downloadId
    final downloadId = await _apiService.startDownload(
      url: url,
      formatId: formatId,
      userId: userId,
      title: title,
      thumbnailUrl: thumbnailUrl,
    );

    // 3. Add task to state
    final newTask = DownloadTask(
      id: downloadId,
      title: title,
      thumbnailUrl: thumbnailUrl,
      status: 'queued',
    );
    state = [...state, newTask];

    // 4. Start the actual file download
    _executeDownload(downloadId);
  }

  Future<void> _executeDownload(String downloadId) async {
    final taskIndex = state.indexWhere((task) => task.id == downloadId);
    if (taskIndex == -1) return;

    try {
      // Get the downloads directory
      final dir = await getDownloadsDirectory();
      if (dir == null) throw Exception('Could not get downloads directory');
      final savePath = '${dir.path}/$downloadId.mp4'; // Assuming mp4 for now

      state = [
        for (final task in state)
          if (task.id == downloadId) task.copyWith(status: 'downloading') else task,
      ];

      await _dio.download(
        '${_apiService.baseUrl}/download/stream/$downloadId',
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _updateTaskProgress(downloadId, progress);
          }
        },
      );

      // 5. Update task to completed
      _updateTaskState(downloadId, 'completed', filePath: savePath);
    } catch (e) {
      print('Download failed for $downloadId: $e');
      _updateTaskState(downloadId, 'failed');
    }
  }

  Future<bool> _requestPermissions() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  void _updateTaskProgress(String id, double progress) {
    state = [
      for (final task in state)
        if (task.id == id) task.copyWith(progress: progress) else task,
    ];
  }

  void _updateTaskState(String id, String status, {String? filePath}) {
    state = [
      for (final task in state)
        if (task.id == id)
          task.copyWith(status: status, filePath: filePath, progress: status == 'completed' ? 1.0 : null)
        else
          task,
    ];
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Provider for the DownloadService
final downloadServiceProvider = StateNotifierProvider<DownloadService, List<DownloadTask>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return DownloadService(apiService);
});
