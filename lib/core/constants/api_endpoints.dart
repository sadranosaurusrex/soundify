class ApiEndpoints {
  static const String baseUrl = 'https://soundify.easyfound.ir/api/v1';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String otpRequest = '/auth/otp/request';
  static const String otpVerify = '/auth/otp/verify';
  static const String tokenRefresh = '/auth/token/refresh';
  static const String logout = '/auth/logout';
  static const String passwordResetRequest = '/auth/password/reset/request';
  static const String passwordResetConfirm = '/auth/password/reset/confirm';

  // Users
  static const String userMe = '/users/me';

  // Tracks
  static const String tracks = '/tracks';
  static const String tracksFeatured = '/tracks/featured';
  static String trackDetails(String id) => '/tracks/$id';
  static String trackStream(String id) => '$baseUrl/tracks/$id/stream';

  // Favorites
  static const String favorites = '/favorites';
  static String favoriteItem(String trackId) => '/favorites/$trackId';

  // Playlists
  static const String playlists = '/playlists';
  static String playlistDetail(int id) => '/playlists/$id';
  static String playlistTracks(int id) => '/playlists/$id/tracks';
  static String playlistTrackItem(int playlistId, String trackId) =>
      '/playlists/$playlistId/tracks/$trackId';
}
