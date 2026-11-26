import 'package:flutter_test/flutter_test.dart';
import 'package:soundify/models/paginated_response.dart';
import 'package:soundify/models/playlist_model.dart';
import 'package:soundify/models/track_model.dart';
import 'package:soundify/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    test('fromJson parses valid JSON and nullable fields correctly', () {
      // Arrange
      final json = {
        'id': 1,
        'username': 'student01',
        'email': 'student@example.com',
        'display_name': null,
        'avatar_url': 'https://example.com/avatar.png',
      };

      // Act
      final user = UserModel.fromJson(json);

      // Assert
      expect(user.id, equals(1));
      expect(user.username, equals('student01'));
      expect(user.email, equals('student@example.com'));
      expect(user.displayName, isNull);
      expect(user.avatarUrl, equals('https://example.com/avatar.png'));
      expect(user.isVerified, isTrue);
    });

    test('copyWith updates only provided fields and preserves others', () {
      // Arrange
      final user = UserModel(
        id: 1,
        username: 'student01',
        email: 'student@example.com',
        displayName: 'Old Name',
      );

      // Act
      final updated = user.copyWith(displayName: 'New Name');

      // Assert
      expect(updated.displayName, equals('New Name'));
      expect(updated.username, equals('student01'));
      expect(updated.email, equals('student@example.com'));
    });
  });

  group('TrackModel Tests', () {
    test('fromJson parses real server response and double duration safely', () {
      // Arrange (Real payload sample from soundify.easyfound.ir)
      final json = {
        'id': 'BVVEUN627BS7VL4K2JU2E2JJYQ3GMMMK',
        'title': 'Ye Mardi',
        'artist': 'Ebi',
        'album': 'Jane Javani',
        'cover_url': 'https://lh3.googleusercontent.com/sample.jpg',
        'duration': 214.0, // double instead of int to test defensive parsing
        'stream_url':
            'https://soundify.easyfound.ir/api/v1/tracks/BVVEUN627BS7VL4K2JU2E2JJYQ3GMMMK/stream/',
      };

      // Act
      final track = TrackModel.fromJson(json);

      // Assert
      expect(track.id, equals('BVVEUN627BS7VL4K2JU2E2JJYQ3GMMMK'));
      expect(track.title, equals('Ye Mardi'));
      expect(track.artist, equals('Ebi'));
      expect(track.duration, equals(214));
      expect(track.isFavorite, isFalse);
      expect(track.position, isNull);
    });

    test('formattedDuration converts seconds to mm:ss properly', () {
      // Arrange
      final track1 = TrackModel(
        id: '1',
        title: 'A',
        artist: 'B',
        duration: 214,
        streamUrl: '',
      );
      final track2 = TrackModel(
        id: '2',
        title: 'C',
        artist: 'D',
        duration: 65,
        streamUrl: '',
      );

      // Act & Assert
      expect(track1.formattedDuration, equals('03:34'));
      expect(track2.formattedDuration, equals('01:05'));
    });

    test('toJson omits position when null and includes it when set', () {
      // Arrange
      final normalTrack = TrackModel(
        id: '1',
        title: 'A',
        artist: 'B',
        duration: 120,
        streamUrl: 'https://example.com/s',
      );
      final playlistTrack = normalTrack.copyWith(position: 2);

      // Act
      final normalMap = normalTrack.toJson();
      final playlistMap = playlistTrack.toJson();

      // Assert
      expect(normalMap.containsKey('position'), isFalse);
      expect(playlistMap['position'], equals(2));
    });
  });

  group('PlaylistModel Tests', () {
    test('fromJson handles summary response when tracks key is absent', () {
      // Arrange
      final json = {
        'id': 1,
        'name': 'Road Trip',
        'track_count': 5,
      };

      // Act
      final playlist = PlaylistModel.fromJson(json);

      // Assert
      expect(playlist.id, equals(1));
      expect(playlist.name, equals('Road Trip'));
      expect(playlist.trackCount, equals(5));
      expect(playlist.tracks, isEmpty);
    });

    test('fromJson parses nested tracks and infers trackCount when omitted', () {
      // Arrange
      final json = {
        'id': 2,
        'name': 'Study',
        'tracks': [
          {
            'id': 'T1',
            'title': 'Song A',
            'artist': 'X',
            'duration': 100,
            'stream_url': '',
            'position': 0,
          },
        ],
      };

      // Act
      final playlist = PlaylistModel.fromJson(json);

      // Assert
      expect(playlist.tracks.length, equals(1));
      expect(playlist.tracks.first.title, equals('Song A'));
      expect(playlist.tracks.first.position, equals(0));
      expect(playlist.trackCount, equals(1));
    });
  });

  group('PaginatedResponse Tests', () {
    test('fromJson parses count, next, results correctly with TrackModel', () {
      // Arrange — یه JSON صفحه‌بندی شده مثل پاسخ واقعی سرور
      final json = {
        'count': 588,
        'next': 'https://soundify.easyfound.ir/api/v1/tracks/?page=2',
        'previous': null,
        'results': [
          {
            'id': 'AAA111',
            'title': 'Dokhtar Irooni',
            'artist': 'Dariush',
            'duration': 240,
            'stream_url': 'https://example.com/stream/1',
          },
          {
            'id': 'BBB222',
            'title': 'Ey Iran',
            'artist': 'Various',
            'duration': 185,
            'stream_url': 'https://example.com/stream/2',
          },
        ],
      };

      // Act — fromJsonT رو با TrackModel.fromJson پر می‌کنیم
      final page = PaginatedResponse.fromJson(
        json,
        (item) => TrackModel.fromJson(item),
      );

      // Assert
      expect(page.count, equals(588));
      expect(page.next, equals('https://soundify.easyfound.ir/api/v1/tracks/?page=2'));
      expect(page.previous, isNull);
      expect(page.hasMore, isTrue);            // چون next != null
      expect(page.results.length, equals(2));
      expect(page.results[0].id, equals('AAA111'));
      expect(page.results[0].title, equals('Dokhtar Irooni'));
      expect(page.results[1].artist, equals('Various'));
    });

    test('hasMore is false when next is null', () {
      // Arrange — صفحه آخر، next نداره
      final json = {
        'count': 2,
        'next': null,
        'previous': 'https://soundify.easyfound.ir/api/v1/tracks/?page=1',
        'results': [
          {
            'id': 'CCC333',
            'title': 'Akharin Bahar',
            'artist': 'Googoosh',
            'duration': 210,
            'stream_url': 'https://example.com/stream/3',
          },
        ],
      };

      // Act
      final page = PaginatedResponse.fromJson(
        json,
        (item) => TrackModel.fromJson(item),
      );

      // Assert
      expect(page.hasMore, isFalse);           // چون next == null
      expect(page.results.length, equals(1));
    });

    test('fromJson handles empty results list gracefully', () {
      // Arrange — نتیجه خالی (مثلاً جست‌وجوی بی‌نتیجه)
      final json = {
        'count': 0,
        'next': null,
        'previous': null,
        'results': [],
      };

      // Act
      final page = PaginatedResponse.fromJson(
        json,
        (item) => TrackModel.fromJson(item),
      );

      // Assert
      expect(page.count, equals(0));
      expect(page.results, isEmpty);
      expect(page.hasMore, isFalse);
    });
  });
}
