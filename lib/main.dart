import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/music_provider.dart';
import 'providers/player_provider.dart';
import 'services/audio_player_service.dart';
import 'services/security_service.dart';
import 'ui/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize JustAudioBackground for system notification & lock-screen media controls
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.soundify.channel.audio',
    androidNotificationChannelName: 'Soundify Music Playback',
    androidNotificationOngoing: true,
  );

  final secureStorageService = SecureStorageService();
  final securityService = SecurityService();
  final audioPlayerService = AudioPlayerService();
  await audioPlayerService.init();

  final apiClient = ApiClient(
    secureStorageService: secureStorageService,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<SecureStorageService>.value(value: secureStorageService),
        Provider<SecurityService>.value(value: securityService),
        Provider<ApiClient>.value(value: apiClient),
        Provider<AudioPlayerService>.value(value: audioPlayerService),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            apiClient: apiClient,
            secureStorageService: secureStorageService,
            securityService: securityService,
          ),
        ),
        ChangeNotifierProvider<PlayerProvider>(
          create: (_) => PlayerProvider(
            audioService: audioPlayerService,
          ),
        ),
        ChangeNotifierProvider<MusicProvider>(
          create: (_) => MusicProvider(
            apiClient: apiClient,
          ),
        ),
      ],
      child: const SoundifyApp(),
    ),
  );
}

class SoundifyApp extends StatelessWidget {
  const SoundifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soundify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [
        Locale('fa', 'IR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
