import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/home_screen.dart';
import 'screens/downloads_screen.dart';
import 'screens/download_history_screen.dart';
import 'screens/about_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/iap_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  MobileAds.instance.initialize();

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OmniDownloader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AppInitializer(),
    );
  }
}

// A wrapper to initialize services and then show the auth wrapper
class AppInitializer extends ConsumerStatefulWidget {
  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  @override
  void initState() {
    super.initState();
    // Initialize IAP service
    ref.read(iapServiceProvider).init();
  }

  @override
  Widget build(BuildContext context) {
    return AuthWrapper();
  }
}

// A wrapper to decide which screen to show based on auth state
class AuthWrapper extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    return authState.when(
      data: (user) => user != null ? MainScreen() : LoginScreen(),
      loading: () => Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    HomeScreen(),
    DownloadsScreen(),
    DownloadHistoryScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OmniDownloader'),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutScreen()),
              );
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final isAdFree = ref.watch(isAdFreeProvider);
              if (isAdFree) {
                return SizedBox.shrink(); // User is ad-free, show nothing
              }
              return TextButton(
                child: Text('Remove Ads', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  ref.read(iapServiceProvider).buyRemoveAds();
                },
              );
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              return IconButton(
                icon: Icon(Icons.logout),
                onPressed: () {
                  ref.read(authServiceProvider).signOut();
                },
              );
            },
          )
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.download),
            label: 'Downloads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Good for 3+ items
      ),
    );
  }
}