import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/music_provider.dart';
import '../widgets/error_retry_view.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/track_tile.dart';
import 'playlist_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final music = context.read<MusicProvider>();
      music.fetchPlaylists();
      music.fetchFavorites();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreatePlaylistDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('پلی‌لیست جدید', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'نام پلی‌لیست'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'توضیحات (اختیاری)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('انصراف', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40)),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.of(ctx).pop();
              final music = context.read<MusicProvider>();
              await music.createPlaylist(
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim(),
              );
            },
            child: const Text('ایجاد'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'کتابخانه شما',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 28),
            tooltip: 'ایجاد پلی‌لیست جدید',
            onPressed: _showCreatePlaylistDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'پلی‌لیست‌ها'),
            Tab(text: 'علاقه‌مندی‌ها'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Playlists Tab
          RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () => music.fetchPlaylists(),
            child: music.isLoadingPlaylists && music.playlists.isEmpty
                ? const LoadingIndicator(message: 'در حال بارگذاری پلی‌لیست‌ها...')
                : music.playlists.isEmpty
                    ? Center(
                        child: EmptyStateView(
                          message: 'هنوز پلی‌لیستی نساخته‌اید.',
                          icon: Icons.playlist_add_check_rounded,
                          action: ElevatedButton.icon(
                            onPressed: _showCreatePlaylistDialog,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('ساخت پلی‌لیست اول'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(180, 46),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 12, bottom: 100),
                        itemCount: music.playlists.length,
                        itemBuilder: (context, index) {
                          final pl = music.playlists[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            leading: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.queue_music_rounded,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            title: Text(
                              pl.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              '${pl.trackCount} قطعه${pl.description != null && pl.description!.isNotEmpty ? " • ${pl.description}" : ""}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                            trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.textMuted),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PlaylistDetailScreen(
                                    playlistId: pl.id,
                                    playlistName: pl.name,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),

          // 2. Favorites Tab
          RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () => music.fetchFavorites(),
            child: music.isLoadingFavorites && music.favoriteTracks.isEmpty
                ? const LoadingIndicator(message: 'در حال دریافت آهنگ‌های محبوب...')
                : music.favoriteTracks.isEmpty
                    ? const EmptyStateView(
                        message: 'هنوز آهنگی را به علاقه‌مندی‌ها اضافه نکرده‌اید.\nروی آیکون قلب هر ترانه بزنید تا اینجا نمایش داده شود.',
                        icon: Icons.favorite_border_rounded,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 12, bottom: 100),
                        itemCount: music.favoriteTracks.length,
                        itemBuilder: (context, index) {
                          final track = music.favoriteTracks[index];
                          return TrackTile(
                            track: track,
                            currentQueue: music.favoriteTracks,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
