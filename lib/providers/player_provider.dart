import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track_model.dart';
import '../services/audio_player_service.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayerService audioService;

  TrackModel? _currentTrack;
  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isShuffleEnabled = false;
  LoopMode _loopMode = LoopMode.off;

  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _sequenceSub;

  TrackModel? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isShuffleEnabled => _isShuffleEnabled;
  LoopMode get loopMode => _loopMode;
  bool get hasActiveTrack => _currentTrack != null;

  PlayerProvider({required this.audioService}) {
    _initListeners();
  }

  void _initListeners() {
    _playerStateSub = audioService.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isBuffering = state.processingState == ProcessingState.buffering ||
          state.processingState == ProcessingState.loading;
      notifyListeners();
    });

    _positionSub = audioService.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _durationSub = audioService.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        notifyListeners();
      }
    });

    _sequenceSub = audioService.sequenceStateStream.listen((state) {
      if (state != null) {
        final currentTag = state.currentSource?.tag;
        if (currentTag != null && currentTag is IndexedAudioSource) {
          // matched
        }
        final track = audioService.currentTrack;
        if (track != null && track.id != _currentTrack?.id) {
          _currentTrack = track;
          notifyListeners();
        }
      }
    });
  }

  Future<void> playTrack(TrackModel track, {List<TrackModel>? playlist}) async {
    _currentTrack = track;
    _position = Duration.zero;
    _duration = Duration(seconds: track.duration);
    notifyListeners();

    if (playlist != null && playlist.isNotEmpty) {
      final index = playlist.indexWhere((t) => t.id == track.id);
      await audioService.setPlaylist(
        playlist,
        initialIndex: index >= 0 ? index : 0,
      );
    } else {
      await audioService.playSingleTrack(track);
    }
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await audioService.pause();
    } else {
      await audioService.play();
    }
  }

  Future<void> seek(Duration position) async {
    _position = position;
    notifyListeners();
    await audioService.seek(position);
  }

  Future<void> next() async {
    await audioService.skipToNext();
    _currentTrack = audioService.currentTrack;
    notifyListeners();
  }

  Future<void> previous() async {
    await audioService.skipToPrevious();
    _currentTrack = audioService.currentTrack;
    notifyListeners();
  }

  Future<void> toggleShuffle() async {
    _isShuffleEnabled = !_isShuffleEnabled;
    await audioService.player.setShuffleModeEnabled(_isShuffleEnabled);
    notifyListeners();
  }

  Future<void> toggleRepeat() async {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.all;
    } else if (_loopMode == LoopMode.all) {
      _loopMode = LoopMode.one;
    } else {
      _loopMode = LoopMode.off;
    }
    await audioService.player.setLoopMode(_loopMode);
    notifyListeners();
  }

  void updateTrackFavoriteStatus(String trackId, bool isFavorite) {
    if (_currentTrack != null && _currentTrack!.id == trackId) {
      _currentTrack = _currentTrack!.copyWith(isFavorite: isFavorite);
      notifyListeners();
    }
  }

  Future<void> stopAndClose() async {
    await audioService.stop();
    _currentTrack = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _sequenceSub?.cancel();
    super.dispose();
  }
}
