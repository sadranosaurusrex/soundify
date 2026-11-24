import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/player_provider.dart';
import '../widgets/error_retry_view.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/track_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final music = context.read<MusicProvider>();
      if (music.featuredTracks.isEmpty && music.allTracks.isEmpty) {
        music.fetchHomeData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final music = context.watch<MusicProvider>();
    final player = context.watch<PlayerProvider>();

    final user = auth.currentUser;
    final userName = user?.displayName ?? user?.username ?? 'کاربر گرامی';

    if (music.isLoadingHome && music.featuredTracks.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingIndicator(message: 'در حال بارگذاری کاتالوگ آهنگ‌ها...'),
      );
    }

    if (music.homeError != null && music.featuredTracks.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: ErrorRetryView(
          message: music.homeError!,
          onRetry: () => music.fetchHomeData(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () => music.fetchHomeData(),
          child: CustomScrollView(
            slivers: [
              // Top Bar with Greeting
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'خوش آمدید،',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Featured Section Title
              if (music.featuredTracks.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Text(
                      'آهنگ‌های منتخب و برگزیده',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Featured Horizontal List
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: music.featuredTracks.length,
                      itemBuilder: (context, index) {
                        final track = music.featuredTracks[index];
                        final isPlayingThis = player.currentTrack?.id == track.id;

                        return GestureDetector(
                          onTap: () {
                            player.playTrack(
                              track,
                              playlist: music.featuredTracks,
                            );
                          },
                          child: Container(
                            width: 145,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Cover Card
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        width: 145,
                                        height: 145,
                                        color: AppColors.surface,
                                        child: track.coverUrl != null &&
                                                track.coverUrl!.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: track.coverUrl!,
                                                fit: BoxFit.cover,
                                                errorWidget: (_, _, _) =>
                                                    const Icon(
                                                  Icons.music_note,
                                                  size: 50,
                                                  color: AppColors.textMuted,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.music_note,
                                                size: 50,
                                                color: AppColors.textMuted,
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isPlayingThis
                                              ? AppColors.primary
                                              : Colors.black.withValues(alpha: 0.7),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isPlayingThis && player.isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          color: isPlayingThis
                                              ? Colors.black
                                              : Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Title
                                Text(
                                  track.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isPlayingThis
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),

                                // Artist
                                Text(
                                  track.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // All Tracks Section Title
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                  child: Text(
                    'همه ترانه‌ها',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // All Tracks List
              if (music.allTracks.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'ترانه‌ای یافت نشد.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final track = music.allTracks[index];
                      return TrackTile(
                        track: track,
                        currentQueue: music.allTracks,
                      );
                    },
                    childCount: music.allTracks.length,
                  ),
                ),

              // Bottom padding for miniplayer
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
