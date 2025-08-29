import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import '../services/download_service.dart';

class DownloadsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Downloads'),
      ),
      body: downloads.isEmpty
          ? Center(child: Text('No downloads yet.'))
          : ListView.builder(
              itemCount: downloads.length,
              itemBuilder: (context, index) {
                final task = downloads[index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Image.network(
                          task.thumbnailUrl,
                          width: 100,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.video_library, size: 60),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(task.title,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              SizedBox(height: 5),
                              Text('Status: ${task.status}'),
                              SizedBox(height: 5),
                              if (task.status == 'downloading' || task.status == 'queued')
                                LinearProgressIndicator(value: task.progress),
                              if (task.status == 'failed')
                                Text('Download failed', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                        if (task.status == 'completed' && task.filePath != null)
                          IconButton(
                            icon: Icon(Icons.folder_open),
                            onPressed: () async {
                              final result = await OpenFile.open(task.filePath);
                              if (result.type != ResultType.done) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Could not open file: ${result.message}')),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
