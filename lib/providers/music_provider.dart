import 'package:flutter/foundation.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exceptions.dart';
import '../models/paginated_response.dart';
import '../models/playlist_model.dart';
import '../models/track_model.dart';

class MusicProvider extends ChangeNotifier {
  final ApiClient apiClient;

  // Home data
  List<TrackModel> _featuredTracks = [];
  List<TrackModel> _allTracks = [];
  bool _isLoadingHome = false;
  String? _homeError;

  // Search data
  List<TrackModel> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;
  String _lastSearchQuery = '';

  // Favorites data
  List<TrackModel> _favoriteTracks = [];
  final Set<String> _favoriteIds = {};
  bool _isLoadingFavorites = false;

  // Playlists data
  List<PlaylistModel> _playlists = [];
  bool _isLoadingPlaylists = false;

  // Getters
  List<TrackModel> get featuredTracks => _featuredTracks;
  List<TrackModel> get allTracks => _allTracks;
  bool get isLoadingHome => _isLoadingHome;
  String? get homeError => _homeError;

  List<TrackModel> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get searchError => _searchError;
  String get lastSearchQuery => _lastSearchQuery;

  List<TrackModel> get favoriteTracks => _favoriteTracks;
  bool get isLoadingFavorites => _isLoadingFavorites;
  bool isFavorite(String trackId) => _favoriteIds.contains(trackId);

  List<PlaylistModel> get playlists => _playlists;
  bool get isLoadingPlaylists => _isLoadingPlaylists;

  MusicProvider({required this.apiClient});

  // --- Home Data ---
  Future<void> fetchHomeData() async {
    _isLoadingHome = true;
    _homeError = null;
    notifyListeners();

    try {
      // 1. Featured tracks
      final featRes = await apiClient.get(
        ApiEndpoints.tracksFeatured,
        queryParameters: {'page_size': 15},
      );
      if (featRes.statusCode == 200 && featRes.data != null) {
        final paginated = PaginatedResponse<TrackModel>.fromJson(
          featRes.data as Map<String, dynamic>,
          (json) => TrackModel.fromJson(json),
        );
        _featuredTracks = paginated.results;
      }

      // 2. All tracks catalog
      final allRes = await apiClient.get(
        ApiEndpoints.tracks,
        queryParameters: {'page_size': 25},
      );
      if (allRes.statusCode == 200 && allRes.data != null) {
        final paginated = PaginatedResponse<TrackModel>.fromJson(
          allRes.data as Map<String, dynamic>,
          (json) => TrackModel.fromJson(json),
        );
        _allTracks = paginated.results;
      }

      // 3. User favorites
      await fetchFavorites();

      _isLoadingHome = false;
      notifyListeners();
    } on ApiException catch (e) {
      _homeError = e.message;
      _isLoadingHome = false;
      notifyListeners();
    } catch (_) {
      _homeError = 'خطایی در دریافت اطلاعات صفحه اصلی رخ داد.';
      _isLoadingHome = false;
      notifyListeners();
    }
  }

  // --- Search Tracks (with Debounce caller) ---
  Future<void> searchTracks(String query) async {
    final trimmed = query.trim();
    _lastSearchQuery = trimmed;

    if (trimmed.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _searchError = null;
    notifyListeners();

    try {
      final res = await apiClient.get(
        ApiEndpoints.tracks,
        queryParameters: {'q': trimmed, 'page_size': 30},
      );

      if (res.statusCode == 200 && res.data != null) {
        final paginated = PaginatedResponse<TrackModel>.fromJson(
          res.data as Map<String, dynamic>,
          (json) => TrackModel.fromJson(json),
        );
        _searchResults = paginated.results;
      }
    } on ApiException catch (e) {
      _searchError = e.message;
    } catch (_) {
      _searchError = 'خطایی در جستجو رخ داد.';
    }

    _isSearching = false;
    notifyListeners();
  }

  // --- Favorites Management ---
  Future<void> fetchFavorites() async {
    _isLoadingFavorites = true;
    notifyListeners();

    try {
      final res = await apiClient.get(
        ApiEndpoints.favorites,
        queryParameters: {'page_size': 50},
      );

      if (res.statusCode == 200 && res.data != null) {
        final paginated = PaginatedResponse<TrackModel>.fromJson(
          res.data as Map<String, dynamic>,
          (json) => TrackModel.fromJson(json),
        );
        _favoriteTracks = paginated.results;
        _favoriteIds.clear();
        for (var t in _favoriteTracks) {
          _favoriteIds.add(t.id);
        }
      }
    } catch (_) {}

    _isLoadingFavorites = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(TrackModel track) async {
    final currentlyFavorite = _favoriteIds.contains(track.id);

    // Optimistic UI update
    if (currentlyFavorite) {
      _favoriteIds.remove(track.id);
      _favoriteTracks.removeWhere((t) => t.id == track.id);
    } else {
      _favoriteIds.add(track.id);
      _favoriteTracks.insert(0, track.copyWith(isFavorite: true));
    }
    notifyListeners();

    try {
      if (currentlyFavorite) {
        await apiClient.delete(ApiEndpoints.favoriteItem(track.id));
      } else {
        await apiClient.post(
          ApiEndpoints.favorites,
          data: {'track_id': track.id},
        );
      }
    } catch (_) {
      // Revert if API fails
      if (currentlyFavorite) {
        _favoriteIds.add(track.id);
        _favoriteTracks.insert(0, track);
      } else {
        _favoriteIds.remove(track.id);
        _favoriteTracks.removeWhere((t) => t.id == track.id);
      }
      notifyListeners();
    }
  }

  // --- Playlists CRUD ---
  Future<void> fetchPlaylists() async {
    _isLoadingPlaylists = true;
    notifyListeners();

    try {
      final res = await apiClient.get(
        ApiEndpoints.playlists,
        queryParameters: {'page_size': 50},
      );

      if (res.statusCode == 200 && res.data != null) {
        final paginated = PaginatedResponse<PlaylistModel>.fromJson(
          res.data as Map<String, dynamic>,
          (json) => PlaylistModel.fromJson(json),
        );
        _playlists = paginated.results;
      }
    } catch (_) {}

    _isLoadingPlaylists = false;
    notifyListeners();
  }

  Future<PlaylistModel?> createPlaylist({
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    try {
      final res = await apiClient.post(
        ApiEndpoints.playlists,
        data: {
          'name': name.trim(),
          if (description != null && description.isNotEmpty)
            'description': description.trim(),
          'is_public': isPublic,
        },
      );

      if (res.statusCode == 201 && res.data != null) {
        final newPlaylist = PlaylistModel.fromJson(res.data as Map<String, dynamic>);
        _playlists.insert(0, newPlaylist);
        notifyListeners();
        return newPlaylist;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> updatePlaylist({
    required int id,
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    try {
      final res = await apiClient.patch(
        ApiEndpoints.playlistDetail(id),
        data: {
          'name': ?name?.trim(),
          'description': ?description?.trim(),
          'is_public': ?isPublic,
        },
      );

      if (res.statusCode == 200 && res.data != null) {
        final updated = PlaylistModel.fromJson(res.data as Map<String, dynamic>);
        final index = _playlists.indexWhere((p) => p.id == id);
        if (index != -1) {
          _playlists[index] = updated;
          notifyListeners();
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deletePlaylist(int id) async {
    try {
      final res = await apiClient.delete(ApiEndpoints.playlistDetail(id));
      if (res.statusCode == 204 || res.statusCode == 200) {
        _playlists.removeWhere((p) => p.id == id);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<PlaylistModel?> getPlaylistDetails(int id) async {
    try {
      final res = await apiClient.get(ApiEndpoints.playlistDetail(id));
      if (res.statusCode == 200 && res.data != null) {
        final detailed = PlaylistModel.fromJson(res.data as Map<String, dynamic>);
        final index = _playlists.indexWhere((p) => p.id == id);
        if (index != -1) {
          _playlists[index] = detailed;
          notifyListeners();
        }
        return detailed;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> addTrackToPlaylist({
    required int playlistId,
    required String trackId,
  }) async {
    try {
      final res = await apiClient.post(
        ApiEndpoints.playlistTracks(playlistId),
        data: {'track_id': trackId},
      );
      if (res.statusCode == 201) {
        await getPlaylistDetails(playlistId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> removeTrackFromPlaylist({
    required int playlistId,
    required String trackId,
  }) async {
    try {
      final res = await apiClient.delete(
        ApiEndpoints.playlistTrackItem(playlistId, trackId),
      );
      if (res.statusCode == 204 || res.statusCode == 200) {
        await getPlaylistDetails(playlistId);
        return true;
      }
    } catch (_) {}
    return false;
  }
}
