import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Users collection
  Future<void> createUser(String uid, String username, String email) async {
    await _db.collection('users').doc(uid).set({
      'username': username,
      'email': email,
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) {
    return _db.collection('users').doc(uid).get();
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  Future<void> updateUserPlaylist(String uid, String playlistId) async {
    await _db.collection('users').doc(uid).set({
      'currentPlaylistId': playlistId,
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  // Playlists collection
  Future<void> createPlaylistIfMissing(String id) async {
    final ref = _db.collection('playlists').doc(id);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'songs': [],
        'voting': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getPlaylist(String id) {
    return _db.collection('playlists').doc(id).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getPlaylistStream(String id) {
    return _db.collection('playlists').doc(id).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllPlaylistsStream() {
    return _db.collection('playlists').snapshots();
  }

  Future<void> addSongToVoting(
    String playlistId,
    Map<String, dynamic> songData,
  ) async {
    await _db.collection('playlists').doc(playlistId).update({
      "voting": FieldValue.arrayUnion([songData]),
    });
  }

  Future<void> updatePlaylist(
    String playlistId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('playlists').doc(playlistId).update(data);
  }

  Future<void> setPlaylist(
    String playlistId,
    Map<String, dynamic> data, [
    bool merge = false,
  ]) async {
    await _db
        .collection('playlists')
        .doc(playlistId)
        .set(data, SetOptions(merge: merge));
  }

  // update song preview URL once expired
  Future<void> updateSongPreviewUrl(
    String playlistId,
    String spotifyId,
    String newUrl,
  ) async {
    final playlistRef = _db.collection("playlists").doc(playlistId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(playlistRef);
      if (!snap.exists) return;
      final data = snap.data() ?? {};
      final songs = List<Map<String, dynamic>>.from(data['songs'] ?? []);
      final idx = songs.indexWhere((s) => s['spotifyId'] == spotifyId);
      if (idx == -1) return;
      songs[idx]['previewUrl'] = newUrl;
      tx.update(playlistRef, {'songs': songs});
    });
  }

  // Spotify collection
  Future<DocumentSnapshot<Map<String, dynamic>>> getSpotifyToken() {
    return _db.collection('spotify').doc('env').get();
  }

  // Messaging collection
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessagesStream(
    String playlistId,
  ) {
    return _db
        .collection('playlists')
        .doc(playlistId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> sendMessage(
    String playlistId,
    String username,
    String text,
  ) async {
    await _db
        .collection('playlists')
        .doc(playlistId)
        .collection('messages')
        .add({
          'text': text,
          'username': username,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }
}
