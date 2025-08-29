import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import '../services/api_service.dart';
import '../services/download_service.dart';
import '../services/iap_service.dart';

// Provider for the analysis result
final analysisResultProvider = StateProvider<AnalysisResult?>((ref) => null);

class HomeScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _urlController = TextEditingController();
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    // We will create the ad only if the user is not ad-free.
    final isAdFree = ref.read(isAdFreeProvider);
    if (!isAdFree) {
      _bannerAd = ref.read(adServiceProvider).createBannerAd();
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analysisResult = ref.watch(analysisResultProvider);
    final isAdFree = ref.watch(isAdFreeProvider);

    return Scaffold(
      // The AppBar is now in MainScreen, so it's removed from here.
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildUrlInput(context),
                  SizedBox(height: 20),
                  if (analysisResult != null)
                    _buildResults(context, analysisResult),
                ],
              ),
            ),
          ),
          if (!isAdFree && _bannerAd != null)
            Container(
              alignment: Alignment.center,
              child: AdWidget(ad: _bannerAd!),
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
            ),
        ],
      ),
    );
  }

  Widget _buildUrlInput(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _urlController,
          decoration: InputDecoration(
            labelText: 'Paste URL here',
            border: OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(Icons.paste),
              onPressed: () async {
                final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
                if (clipboardData != null) {
                  _urlController.text = clipboardData.text ?? '';
                }
              },
            ),
          ),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () async {
            final url = _urlController.text;
            if (url.isNotEmpty) {
              try {
                final result = await ref.read(apiServiceProvider).analyzeUrl(url);
                ref.read(analysisResultProvider.notifier).state = result;
              } catch (e) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Analysis Failed'),
                    content: Text('Could not analyze the URL. Please check the link and your internet connection.\n\nError: ${e.toString()}'),
                    actions: [
                      TextButton(
                        child: Text('OK'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                );
              }
            }
          },
          child: Text('Analyze'),
        ),
      ],
    );
  }

  Widget _buildResults(BuildContext context, AnalysisResult result) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.title, style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 10),
            if (result.thumbnailUrl.isNotEmpty)
              Image.network(result.thumbnailUrl),
            SizedBox(height: 20),
            Text('Video Formats', style: Theme.of(context).textTheme.titleMedium),
            ...result.formats.map((format) => ListTile(
                  title: Text('${format['quality']} - ${format['container']}'),
                  subtitle: Text(format['note'] ?? ''),
                  trailing: IconButton(
                    icon: Icon(Icons.download),
                    onPressed: () {
                      ref.read(downloadServiceProvider.notifier).startDownload(
                            url: _urlController.text,
                            formatId: format['quality'], // Using quality as a stand-in ID
                            title: result.title,
                            thumbnailUrl: result.thumbnailUrl,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Download started for ${format['quality']}!')),
                      );
                    },
                  ),
                )),
            SizedBox(height: 20),
            Text('Audio Only', style: Theme.of(context).textTheme.titleMedium),
            ...result.audioOnly.map((format) => ListTile(
                  title: Text('${format['quality']} - ${format['container']}'),
                  subtitle: Text(format['note'] ?? ''),
                  trailing: IconButton(
                    icon: Icon(Icons.download),
                    onPressed: () {
                      ref.read(downloadServiceProvider.notifier).startDownload(
                            url: _urlController.text,
                            formatId: format['quality'], // Using quality as a stand-in ID
                            title: result.title,
                            thumbnailUrl: result.thumbnailUrl,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Download started for ${format['quality']}!')),
                      );
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
