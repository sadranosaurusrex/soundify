import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/track_model.dart';
import '../../providers/music_provider.dart';
import '../../providers/player_provider.dart';

class TrackTile extends StatelessWidget {
  final TrackModel track;
  final List<TrackModel>? currentQueue;
  final VoidCallback? onRemove; // For playlist removal
  final bool showRemoveAction;

  const TrackTile({
    super.key,
    required this.track,
    this.currentQueue,
    this.onRemove,
    this.showRemoveAction = false,
  });

  void _showAddToPlaylistDialog(BuildContext context, MusicProvider music) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final playlists = music.playlists;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Text(
                    'افزودن به پلی‌لیست',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(color: AppColors.divider),
                if (playlists.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        'هیچ پلی‌لیستی وجود ندارد. لطفاً ابتدا در بخش کتابخانه یک پلی‌لیست ایجاد کنید.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final pl = playlists[index];
                        return ListTile(
                          leading: const Icon(Icons.playlist_add_rounded, color: AppColors.primary),
                          title: Text(
                            pl.name,
                            style: const TextStyle(color: AppColors.textPrimary),
                          ),
                          subtitle: Text(
                            '${pl.trackCount} قطعه',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          onTap: () async {
                            Navigator.of(ctx).pop();
                            final success = await music.addTrackToPlaylist(
                              playlistId: pl.id,
                              trackId: track.id,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'قطعه به پلی‌لیست ${pl.name} اضافه شد.'
                                        : 'این قطعه قبلاً به این پلی‌لیست افزوده شده است.',
                                  ),
                                  backgroundColor: success
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final music = context.watch<MusicProvider>();
    final isPlayingThis = player.currentTrack?.id == track.id;
    final isFav = music.isFavorite(track.id);

    return InkWell(
      onTap: () {
        player.playTrack(track, playlist: currentQueue);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            // Cover Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    color: AppColors.surface,
                    child: track.coverUrl != null && track.coverUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: track.coverUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => const Icon(
                              Icons.music_note,
                              color: AppColors.textMuted,
                            ),
                          )
                        : const Icon(
                            Icons.music_note,
                            color: AppColors.textMuted,
                          ),
                  ),
                  if (isPlayingThis)
                    Container(
                      width: 52,
                      height: 52,
                      color: Colors.black.withValues(alpha: 0.5),
                      child: Icon(
                        player.isPlaying ? Icons.equalizer_rounded : Icons.play_arrow_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Title & Artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isPlayingThis ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${track.artist}${track.album != null ? " • ${track.album}" : ""}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Duration
            Text(
              track.formattedDuration,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),

            // Favorite Button
            IconButton(
              icon: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? AppColors.error : AppColors.textMuted,
                size: 22,
              ),
              onPressed: () {
                music.toggleFavorite(track);
                player.updateTrackFavoriteStatus(track.id, !isFav);
              },
            ),

            // More Options (Add to playlist or remove)
            if (showRemoveAction)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 22),
                onPressed: onRemove,
              )
            else
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 22),
                onPressed: () => _showAddToPlaylistDialog(context, music),
              ),
          ],
        ),
      ),
    );
  }
}
