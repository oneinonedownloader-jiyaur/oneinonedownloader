import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the ApiService
final apiServiceProvider = Provider((ref) => ApiService());

// A simple data class for analysis results
class AnalysisResult {
  final String title;
  final String thumbnailUrl;
  final List<dynamic> formats;
  final List<dynamic> audioOnly;

  AnalysisResult({required this.title, required this.thumbnailUrl, required this.formats, required this.audioOnly});

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      title: json['title'] ?? 'Untitled',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      formats: json['formats'] ?? [],
      audioOnly: json['audioOnly'] ?? [],
    );
  }
}

class ApiService {
  // TODO: Replace with your actual backend URL from a .env file
  final String baseUrl = 'http://10.0.2.2:3000'; // For Android emulator

  Future<AnalysisResult> analyzeUrl(String url) async {
    final response = await http.post(
      Uri.parse('$baseUrl/analyze'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'url': url}),
    );

    if (response.statusCode == 200) {
      return AnalysisResult.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to analyze URL: ${response.body}');
    }
  }

  Future<String> startDownload({
    required String url,
    required String formatId,
    String? userId,
    required String title,
    required String thumbnailUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/download'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'url': url,
        'formatId': formatId,
        'userId': userId,
        'title': title,
        'thumbnailUrl': thumbnailUrl,
      }),
    );

    if (response.statusCode == 202) {
      return jsonDecode(response.body)['downloadId'];
    } else {
      throw Exception('Failed to start download: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getDownloadStatus(String downloadId) async {
    final response = await http.get(Uri.parse('$baseUrl/download/status/$downloadId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get download status: ${response.body}');
    }
  }

  Future<List<dynamic>> getDownloadHistory(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/history/$userId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch history: ${response.body}');
    }
  }

}
