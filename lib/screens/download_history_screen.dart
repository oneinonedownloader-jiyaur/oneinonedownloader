import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

// Provider to fetch download history
final historyProvider = FutureProvider<List<dynamic>>((ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    // If no user, return an empty list. The UI will handle this state.
    return [];
  }
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getDownloadHistory(user.uid);
});

class DownloadHistoryScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsyncValue = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Download History'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => ref.refresh(historyProvider),
          )
        ],
      ),
      body: historyAsyncValue.when(
        data: (history) {
          if (history.isEmpty) {
            return Center(child: Text('No download history found.'));
          }
          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return ListTile(
                leading: _buildStatusIcon(item['status'] ?? 'unknown'),
                title: Text(item['title'] ?? 'Untitled'),
                subtitle: Text('Status: ${item['status']}'),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'downloading':
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.0),
        );
      case 'failed':
        return const Icon(Icons.error, color: Colors.red);
      default:
        return const Icon(Icons.help, color: Colors.grey);
    }
  }
}
