import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class VotingScreen extends StatefulWidget {
  const VotingScreen({super.key});

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  // Example placeholder song list
  final List<String> songs = [
    'Song actively being voted on (highlighted)',
    'Song 2 (another song that was added after song 1- populates beaneath)',
    'Song 3 (another song that was added after song 2- populates beaneath)',
    'Song 4 (placeholder)',
    'Song 5 (placeholder)',
    'Song 6 (placeholder)',
    'Song 7 (placeholder)',
    'Song 8 (placeholder)',
    'Song 9 (overflow)',
    'Song 10 (overflow)',
  ];
  List<Map<String, dynamic>> votingSongs = [];
  Map<String, dynamic> voteUserVotes = {};
  String? userVote; // 'up', 'down', or null (derived from map)
  int upvotes = 0; // derived
  int downvotes = 0; // derived
  Timestamp? voteEndAt; // Firestore stored end time for current vote
  bool _submittedOnExpire = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voting')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('playlists')
            .doc('defaultPlaylist')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() ?? {};
          final list = (data['voting'] as List?) ?? [];
          votingSongs = list.cast<Map<String, dynamic>>();
          voteEndAt = data['voteEndAt'] as Timestamp?;
          voteUserVotes =
              (data['voteUserVotes'] as Map<String, dynamic>?) ?? {};

          // Derive counts and current user's vote
          upvotes = voteUserVotes.values.where((v) => v == 'up').length;
          downvotes = voteUserVotes.values.where((v) => v == 'down').length;
          final uid = FirebaseAuth.instance.currentUser?.uid;
          userVote = uid != null ? (voteUserVotes[uid] as String?) : null;

          _ensureVoteEndTime(data);

          // If expired and not yet submitted, submit outcome
          if (_isExpired() && !_submittedOnExpire && votingSongs.isNotEmpty) {
            _submittedOnExpire = true;
            // Defer to next frame to avoid setState during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _submitVoteOutcome();
            });
          }

          return _buildBody(context);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity! < -200) {
          Navigator.of(context).pop();
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top container: Song voting list (adjustable for up to 8 songs)
            Container(
              constraints: const BoxConstraints(
                maxHeight: 8 * 48.0 + 32.0, // 8 items * item height + padding
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF3F4E4F),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                itemCount: votingSongs.isNotEmpty ? votingSongs.length : 1,
                itemBuilder: (context, index) {
                  final isActive = index == 0;
                  if (votingSongs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No songs in voting'),
                    );
                  }
                  final song = votingSongs[index];
                  final title = song['title'] as String? ?? '';
                  final artist = song['artist'] as String? ?? '';
                  return Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.amber.withOpacity(0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$title – $artist',
                      style: TextStyle(
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Current song info container
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF3F4E4F),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: _CurrentSongBanner(
                song: votingSongs.isNotEmpty ? votingSongs.first : null,
              ),
            ),
            const SizedBox(height: 12),
            // Voting controls (with counters and vote logic, reduced spacing)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.thumb_up,
                        size: 26,
                        color: userVote == 'up'
                            ? Colors.green
                            : Colors.green[200],
                      ),
                      onPressed: () => _setUserVote('up'),
                    ),
                    Text(
                      '$upvotes',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // Timer placeholder and vote info
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _timerLabel(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      ' answer can be changed before timer runs out.',
                      style: TextStyle(
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.thumb_down,
                        size: 26,
                        color: userVote == 'down'
                            ? Colors.red
                            : Colors.red[200],
                      ),
                      onPressed: () => _setUserVote('down'),
                    ),
                    Text(
                      '$downvotes',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Submit vote button: decide outcome for active song
            ElevatedButton(
              onPressed: votingSongs.isEmpty ? null : _submitVoteOutcome,
              child: const Text('Submit Vote'),
            ),
          ],
        ),
      ),
    );
  }

  void _ensureVoteEndTime(Map<String, dynamic> docData) async {
    if (votingSongs.isEmpty) return;
    final active = votingSongs.first;
    final activeId = active['spotifyId'] as String?;
    final currentId = docData['activeVoteId'] as String?;

    // If no voteEndAt, or active song changed, set end to now + 30s
    if (voteEndAt == null || currentId != activeId) {
      final ref = FirebaseFirestore.instance
          .collection('playlists')
          .doc('defaultPlaylist');
      await ref.update({
        'activeVoteId': activeId,
        'voteEndAt': Timestamp.fromDate(
          DateTime.now().toUtc().add(const Duration(seconds: 30)),
        ),
      });
      _submittedOnExpire = false;
    }
  }

  bool _isExpired() {
    if (voteEndAt == null) return false;
    final now = DateTime.now().toUtc();
    return now.isAfter(voteEndAt!.toDate().toUtc());
  }

  String _timerLabel() {
    if (voteEndAt == null) return 'Timer starting...';
    final now = DateTime.now().toUtc();
    final end = voteEndAt!.toDate().toUtc();
    final remaining = end.difference(now);
    final secs = remaining.inSeconds.clamp(0, 30);
    return 'Time left: ${secs}s';
  }

  Future<void> _submitVoteOutcome() async {
    if (votingSongs.isEmpty) return;
    final active = votingSongs.first;
    final ref = FirebaseFirestore.instance
        .collection('playlists')
        .doc('defaultPlaylist');

    if ((upvotes) > (downvotes)) {
      // Move to songs and remove from voting
      await ref.update({
        'songs': FieldValue.arrayUnion([active]),
        'voting': FieldValue.arrayRemove([active]),
        'voteUserVotes': {},
        'activeVoteId': null,
        'voteEndAt': null,
      });
    } else {
      // Discard from voting
      await ref.update({
        'voting': FieldValue.arrayRemove([active]),
        'voteUserVotes': {},
        'activeVoteId': null,
        'voteEndAt': null,
      });
    }
    setState(() {
      voteUserVotes = {};
      upvotes = 0;
      downvotes = 0;
      userVote = null;
    });
  }

  Future<void> _setUserVote(String vote) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ref = FirebaseFirestore.instance
        .collection('playlists')
        .doc('defaultPlaylist');
    // Update per-user vote in Firestore to persist across navigation
    await ref.set({
      'voteUserVotes': {uid: vote},
    }, SetOptions(merge: true));
  }
}

class _CurrentSongBanner extends StatelessWidget {
  const _CurrentSongBanner({required this.song});

  final Map<String, dynamic>? song;

  @override
  Widget build(BuildContext context) {
    if (song == null) {
      return const Text('No active song', style: TextStyle(fontSize: 18));
    }
    final title = song!['title'] as String? ?? '';
    final artist = song!['artist'] as String? ?? '';
    final albumArt = song!['albumArt'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (albumArt.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  albumArt,
                  height: 50,
                  width: 50,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Expanded(
            child: Text(
              '$title – $artist',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
