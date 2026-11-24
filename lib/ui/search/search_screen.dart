import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/debounce.dart';
import '../../providers/music_provider.dart';
import '../widgets/error_retry_view.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/track_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Debounce _debounce = Debounce(duration: const Duration(milliseconds: 500));

  @override
  void dispose() {
    _debounce.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce.run(() {
      if (mounted) {
        context.read<MusicProvider>().searchTracks(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header & Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'جست‌وجو',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'جست‌وجوی آهنگ، خواننده یا آلبوم...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                              onPressed: () {
                                _searchController.clear();
                                music.searchTracks('');
                              },
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: Builder(
                builder: (context) {
                  if (music.isSearching) {
                    return const LoadingIndicator(message: 'در حال جست‌وجو...');
                  }

                  if (music.searchError != null) {
                    return ErrorRetryView(
                      message: music.searchError!,
                      onRetry: () => music.searchTracks(_searchController.text),
                    );
                  }

                  if (_searchController.text.trim().isEmpty) {
                    return const EmptyStateView(
                      message: 'نام آهنگ یا خواننده مورد نظر خود را تایپ کنید.',
                      icon: Icons.search_rounded,
                    );
                  }

                  if (music.searchResults.isEmpty) {
                    return EmptyStateView(
                      message: 'نتیجه‌ای برای "${_searchController.text}" پیدا نشد.',
                      icon: Icons.music_off_rounded,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: music.searchResults.length,
                    itemBuilder: (context, index) {
                      final track = music.searchResults[index];
                      return TrackTile(
                        track: track,
                        currentQueue: music.searchResults,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
