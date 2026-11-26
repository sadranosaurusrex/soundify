import 'track_model.dart';

class PlaylistModel {
  final int id;
  final String name;
  final String? description;
  final bool isPublic;
  final int trackCount;
  final String? createdAt;
  final String? updatedAt;
  final List<TrackModel> tracks;

  PlaylistModel({
    required this.id,
    required this.name,
    this.description,
    this.isPublic = false,
    this.trackCount = 0,
    this.createdAt,
    this.updatedAt,
    this.tracks = const [],
  });

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    final rawTracks = json['tracks'];
    List<TrackModel> trackList = [];
    if (rawTracks is List) {
      trackList = rawTracks
          .map((item) => TrackModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return PlaylistModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'پلی‌لیست بدون نام',
      description: json['description'] as String?,
      isPublic: json['is_public'] as bool? ?? false,
      trackCount: (json['track_count'] as num?)?.toInt() ?? trackList.length,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      tracks: trackList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_public': isPublic,
      'track_count': trackCount,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'tracks': tracks.map((t) => t.toJson()).toList(),
    };
  }

  PlaylistModel copyWith({
    String? name,
    String? description,
    bool? isPublic,
    int? trackCount,
    List<TrackModel>? tracks,
  }) {
    return PlaylistModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      trackCount: trackCount ?? this.trackCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      tracks: tracks ?? this.tracks,
    );
  }
}
