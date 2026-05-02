import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/album_repository.dart';
import 'services/image_processing_service.dart';
import 'services/upload_queue_service.dart';

class SnapGatherApp extends StatefulWidget {
  const SnapGatherApp({super.key});

  @override
  State<SnapGatherApp> createState() => _SnapGatherAppState();
}

class _SnapGatherAppState extends State<SnapGatherApp> {
  late final Future<_AppServices> _bootstrap = _initialize();

  Future<_AppServices> _initialize() async {
    await Firebase.initializeApp();

    final repository = AlbumRepository(
      imageProcessingService: ImageProcessingService(),
    );
    final uploadQueue = UploadQueueService(repository: repository);
    await uploadQueue.initialize();

    return _AppServices(repository: repository, uploadQueue: uploadQueue);
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF111111),
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        secondary: Color(0xFFCCCCCC),
        surface: Color(0xFF181818),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF111111),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardColor: const Color(0xFF181818),
      dividerColor: const Color(0xFF242424),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1B1B1B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: Color(0xFF8C8C8C)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'SnapGather',
      debugShowCheckedModeBanner: false,
      theme: baseTheme,
      home: FutureBuilder<_AppServices>(
        future: _bootstrap,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _LoadingScreen();
          }

          if (snapshot.hasError) {
            return _FirebaseSetupScreen(error: snapshot.error.toString());
          }

          final services = snapshot.requireData;

          return HomeScreen(
            repository: services.repository,
            uploadQueue: services.uploadQueue,
          );
        },
      ),
    );
  }
}

class _AppServices {
  const _AppServices({required this.repository, required this.uploadQueue});

  final AlbumRepository repository;
  final UploadQueueService uploadQueue;
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _FirebaseSetupScreen extends StatelessWidget {
  const _FirebaseSetupScreen({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SnapGather')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Firebase setup is required before SnapGather can run.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Add your Firebase platform configuration files, enable Firestore '
              'and Storage, then restart the app.',
            ),
            const SizedBox(height: 12),
            SelectableText(error, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
