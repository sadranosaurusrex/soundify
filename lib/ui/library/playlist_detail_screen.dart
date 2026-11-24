import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/playlist_model.dart';
import '../../providers/music_provider.dart';
import '../../providers/player_provider.dart';
import '../widgets/error_retry_view.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/track_tile.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final int playlistId;
  final String playlistName;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  PlaylistModel? _playlist;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    final music = context.read<MusicProvider>();
    final detailed = await music.getPlaylistDetails(widget.playlistId);
    if (mounted) {
      setState(() {
        _playlist = detailed;
        _isLoading = false;
      });
    }
  }

  void _showEditDialog() {
    final nameCtrl = TextEditingController(text: _playlist?.name ?? widget.playlistName);
    final descCtrl = TextEditingController(text: _playlist?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('ویرایش پلی‌لیست', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
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
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.of(ctx).pop();
              final music = context.read<MusicProvider>();
              await music.updatePlaylist(
                id: widget.playlistId,
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim(),
              );
              _loadDetails();
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40)),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('حذف پلی‌لیست', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'آیا از حذف این پلی‌لیست اطمینان دارید؟',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('خیر', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(80, 40),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final music = context.read<MusicProvider>();
              await music.deletePlaylist(widget.playlistId);
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final music = context.watch<MusicProvider>();

    final tracks = _playlist?.tracks ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_playlist?.name ?? widget.playlistName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: _showEditDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'در حال بارگذاری جزئیات...')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Playlist Header
                Container(
                  padding: const EdgeInsets.all(20),
                  color: AppColors.surface,
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.queue_music_rounded,
                          size: 38,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _playlist?.name ?? widget.playlistName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_playlist?.description != null &&
                                _playlist!.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                _playlist!.description!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              '${tracks.length} آهنگ',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (tracks.isNotEmpty)
                        FloatingActionButton.small(
                          backgroundColor: AppColors.primary,
                          onPressed: () {
                            player.playTrack(tracks.first, playlist: tracks);
                          },
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 28),
                        ),
                    ],
                  ),
                ),

                // Tracks List
                Expanded(
                  child: tracks.isEmpty
                      ? const EmptyStateView(
                          message: 'هنوز آهنگی به این پلی‌لیست اضافه نشده است.\nاز صفحه اصلی یا جست‌وجو آهنگ‌ها را اضافه کنید.',
                          icon: Icons.music_off_rounded,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 100),
                          itemCount: tracks.length,
                          itemBuilder: (context, index) {
                            final track = tracks[index];
                            return TrackTile(
                              track: track,
                              currentQueue: tracks,
                              showRemoveAction: true,
                              onRemove: () async {
                                await music.removeTrackFromPlaylist(
                                  playlistId: widget.playlistId,
                                  trackId: track.id,
                                );
                                _loadDetails();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
