import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/track_model.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  List<TrackModel> _playlist = [];
  int _currentIndex = -1;

  AudioPlayer get player => _player;
  List<TrackModel> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  TrackModel? get currentTrack =>
      (_currentIndex >= 0 && _currentIndex < _playlist.length)
          ? _playlist[_currentIndex]
          : null;

  // Streams
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<SequenceState?> get sequenceStateStream => _player.sequenceStateStream;

  Future<void> init() async {
    // Configure audio session for music playback and background audio
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Listen for track completion to automatically advance
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        skipToNext();
      }
    });

    // Sync current index when queue updates
    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _playlist.length) {
        _currentIndex = index;
      }
    });
  }

  Future<void> setPlaylist(List<TrackModel> tracks, {int initialIndex = 0}) async {
    if (tracks.isEmpty) return;
    _playlist = List.from(tracks);
    _currentIndex = initialIndex.clamp(0, tracks.length - 1);

    final audioSources = _playlist.map((track) {
      return AudioSource.uri(
        Uri.parse(track.streamUrl),
        tag: MediaItem(
          id: track.id,
          album: track.album ?? 'Soundify',
          title: track.title,
          artist: track.artist,
          artUri: (track.coverUrl != null && track.coverUrl!.isNotEmpty)
              ? Uri.tryParse(track.coverUrl!)
              : null,
          duration: Duration(seconds: track.duration),
        ),
      );
    }).toList();

    try {
      final concatenatingSource = ConcatenatingAudioSource(
        useLazyPreparation: true,
        children: audioSources,
      );

      await _player.setAudioSource(
        concatenatingSource,
        initialIndex: _currentIndex,
        initialPosition: Duration.zero,
      );

      await _player.play();
    } catch (e) {
      // Fallback: single track play if concatenating source fails
      if (_currentIndex < _playlist.length) {
        await playSingleTrack(_playlist[_currentIndex]);
      }
    }
  }

  Future<void> playSingleTrack(TrackModel track) async {
    _playlist = [track];
    _currentIndex = 0;

    final source = AudioSource.uri(
      Uri.parse(track.streamUrl),
      tag: MediaItem(
        id: track.id,
        album: track.album ?? 'Soundify',
        title: track.title,
        artist: track.artist,
        artUri: (track.coverUrl != null && track.coverUrl!.isNotEmpty)
            ? Uri.tryParse(track.coverUrl!)
            : null,
        duration: Duration(seconds: track.duration),
      ),
    );

    await _player.setAudioSource(source);
    await _player.play();
  }

  Future<void> play() async => await _player.play();
  Future<void> pause() async => await _player.pause();

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else if (_playlist.isNotEmpty && _currentIndex < _playlist.length - 1) {
      _currentIndex++;
      await setPlaylist(_playlist, initialIndex: _currentIndex);
    }
  }

  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 4) {
      await _player.seek(Duration.zero);
    } else if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else if (_playlist.isNotEmpty && _currentIndex > 0) {
      _currentIndex--;
      await setPlaylist(_playlist, initialIndex: _currentIndex);
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}
