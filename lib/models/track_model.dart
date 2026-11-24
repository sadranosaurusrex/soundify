class TrackModel {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? coverUrl;
  final int duration; // In seconds
  final String streamUrl;
  final bool isFavorite;
  final int? position;

  TrackModel({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.coverUrl,
    required this.duration,
    required this.streamUrl,
    this.isFavorite = false,
    this.position,
  });

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    return TrackModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'بدون عنوان',
      artist: json['artist'] as String? ?? 'هنرمند ناشناس',
      album: json['album'] as String?,
      coverUrl: json['cover_url'] as String?,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      streamUrl: json['stream_url'] as String? ?? '',
      isFavorite: json['is_favorite'] as bool? ?? false,
      position: json['position'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'cover_url': coverUrl,
      'duration': duration,
      'stream_url': streamUrl,
      'is_favorite': isFavorite,
      if (position != null) 'position': position,
    };
  }

  TrackModel copyWith({
    bool? isFavorite,
    int? position,
  }) {
    return TrackModel(
      id: id,
      title: title,
      artist: artist,
      album: album,
      coverUrl: coverUrl,
      duration: duration,
      streamUrl: streamUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      position: position ?? this.position,
    );
  }

  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
