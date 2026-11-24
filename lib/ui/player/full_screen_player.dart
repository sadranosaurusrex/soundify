import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/music_provider.dart';
import '../../providers/player_provider.dart';

class FullScreenPlayer extends StatefulWidget {
  const FullScreenPlayer({super.key});

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  double? _dragValue;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final track = player.currentTrack;

    if (track == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return const Scaffold(backgroundColor: AppColors.background);
    }

    if (!player.isPlaying) {
      if (_rotationController.isAnimating) _rotationController.stop();
    } else {
      if (!_rotationController.isAnimating) _rotationController.repeat();
    }

    final currentPos = _dragValue != null
        ? Duration(milliseconds: _dragValue!.round())
        : player.position;
    final totalDuration = player.duration > Duration.zero
        ? player.duration
        : Duration(seconds: track.duration);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2E3D32),
              AppColors.background,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              children: [
                // Top Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textPrimary,
                        size: 36,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Column(
                      children: [
                        const Text(
                          'در حال پخش',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (track.album != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            track.album!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(width: 48), // balance space
                  ],
                ),

                const Spacer(),

                // Center Album Art (Vinyl Style with Rotation)
                Center(
                  child: RotationTransition(
                    turns: _rotationController,
                    child: Container(
                      width: 270,
                      height: 270,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 30,
                            spreadRadius: 8,
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.cardLight,
                          width: 6,
                        ),
                      ),
                      child: ClipOval(
                        child: track.coverUrl != null && track.coverUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: track.coverUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => const Icon(
                                  Icons.music_note,
                                  size: 100,
                                  color: AppColors.textMuted,
                                ),
                              )
                            : const Icon(
                                Icons.music_note,
                                size: 100,
                                color: AppColors.textMuted,
                              ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Track Info & Favorite Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Consumer<MusicProvider>(
                      builder: (context, music, _) {
                        final isFav = music.isFavorite(track.id);
                        return IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? AppColors.error : AppColors.textSecondary,
                            size: 28,
                          ),
                          onPressed: () {
                            music.toggleFavorite(track);
                            player.updateTrackFavoriteStatus(track.id, !isFav);
                          },
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress Bar & Durations
                Slider(
                  min: 0.0,
                  max: totalDuration.inMilliseconds.toDouble() > 0
                      ? totalDuration.inMilliseconds.toDouble()
                      : 1.0,
                  value: currentPos.inMilliseconds
                      .toDouble()
                      .clamp(0.0, totalDuration.inMilliseconds.toDouble() > 0 ? totalDuration.inMilliseconds.toDouble() : 1.0),
                  onChanged: (val) {
                    setState(() => _dragValue = val);
                  },
                  onChangeEnd: (val) {
                    player.seek(Duration(milliseconds: val.round()));
                    setState(() => _dragValue = null);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(currentPos),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatTime(totalDuration),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Controls Row (Shuffle, Previous, Play/Pause, Next, Repeat)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Shuffle
                    IconButton(
                      icon: Icon(
                        Icons.shuffle_rounded,
                        color: player.isShuffleEnabled
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 24,
                      ),
                      onPressed: () => player.toggleShuffle(),
                    ),

                    // Previous
                    IconButton(
                      icon: const Icon(
                        Icons.skip_previous_rounded,
                        color: AppColors.textPrimary,
                        size: 40,
                      ),
                      onPressed: () => player.previous(),
                    ),

                    // Play/Pause Big Button
                    Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: player.isBuffering
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.black,
                                ),
                              )
                            : Icon(
                                player.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.black,
                                size: 40,
                              ),
                        onPressed: () => player.togglePlayPause(),
                      ),
                    ),

                    // Next
                    IconButton(
                      icon: const Icon(
                        Icons.skip_next_rounded,
                        color: AppColors.textPrimary,
                        size: 40,
                      ),
                      onPressed: () => player.next(),
                    ),

                    // Repeat
                    IconButton(
                      icon: Icon(
                        player.loopMode == LoopMode.one
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                        color: player.loopMode != LoopMode.off
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 24,
                      ),
                      onPressed: () => player.toggleRepeat(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
