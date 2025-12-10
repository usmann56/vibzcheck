import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'voting_screen.dart';
import 'search_screen.dart';
import 'message_board_screen.dart';
import '../utils/deezer.dart';
import '../screens/update_profile_screen.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> defaultPlaylist = [];
  String? currentPlaylistId;
  Map<String, dynamic>? currentSong;
  bool isPlaying = false;
  String? selectedGenre; // State for selected filter

  AudioPlayer audioPlayer = AudioPlayer();
  Duration currentPosition = Duration.zero;
  Duration songDuration = Duration.zero;

  String? username;
  bool isLoadingUser = true;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _playlistSub;

  @override
  void initState() {
    super.initState();
    _listenUserPlaylist();

    audioPlayer.onDurationChanged.listen((d) {
      setState(() => songDuration = d);
    });

    audioPlayer.onPositionChanged.listen((p) {
      setState(() => currentPosition = p);
    });

    audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        isPlaying = state == PlayerState.playing;
      });
    });

    loadUserData();
  }

  @override
  void dispose() {
    // _audioPlayer.dispose();
    _playlistSub?.cancel();
    // audioPlayer.dispose(); // keep if you fully close widget lifecycle
    super.dispose();
  }

  Future<String?> refreshPreviewUrl(Map<String, dynamic> song) async {
    final deezerId = song["deezerId"];
    if (deezerId == null) return null;

    final newUrl = await fetchNewPreviewUrl(deezerId);

    if (newUrl != null) {
      // Transactional update to avoid cross-playlist overwrites
      final targetId = currentPlaylistId ?? 'defaultPlaylist';
      final playlistRef = FirebaseFirestore.instance
          .collection("playlists")
          .doc(targetId);

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(playlistRef);
        if (!snap.exists) return;
        final data = snap.data() ?? {};
        final songs = List<Map<String, dynamic>>.from(data['songs'] ?? []);
        final idx = songs.indexWhere(
          (s) => s['spotifyId'] == song['spotifyId'],
        );
        if (idx == -1) return;
        songs[idx]['previewUrl'] = newUrl;
        tx.update(playlistRef, {'songs': songs});
      });
      return newUrl;
    }

    return null;
  }

  void _listenUserPlaylist() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((
      userDoc,
    ) {
      final pid = userDoc.data()?['currentPlaylistId'] as String?;
      debugPrint('[HomePage] user currentPlaylistId: $pid');
      if (pid == null || pid.isEmpty) return;
      if (currentPlaylistId != pid) {
        currentPlaylistId = pid;
        debugPrint('[HomePage] Switching playlist to: $currentPlaylistId');
        // Swap listeners and stop any current playback from previous playlist
        _playlistSub?.cancel();
        audioPlayer.stop();
        setState(() {
          currentSong = null;
          defaultPlaylist = [];
        });
        _playlistSub = FirebaseFirestore.instance
            .collection('playlists')
            .doc(pid)
            .snapshots()
            .listen((doc) async {
              if (!doc.exists) return;
              final songs = List<Map<String, dynamic>>.from(doc['songs'] ?? []);
              debugPrint('[HomePage] Received ${songs.length} songs for $pid');
              setState(() {
                defaultPlaylist = songs;
              });
              // If nothing playing, auto-start first track of the current playlist (if any)
              if (currentSong == null && songs.isNotEmpty) {
                playSong(songs[0]);
                return;
              }
              // If the currentSong is no longer in this playlist, switch to first or stop
              if (currentSong != null &&
                  !songs.any(
                    (s) => s['spotifyId'] == currentSong!['spotifyId'],
                  )) {
                if (songs.isNotEmpty) {
                  playSong(songs[0]);
                } else {
                  await audioPlayer.stop();
                  setState(() {
                    currentSong = null;
                  });
                }
              }
            });
      } else if (_playlistSub == null) {
        // Ensure we have an active listener for the current playlist
        _playlistSub = FirebaseFirestore.instance
            .collection('playlists')
            .doc(pid)
            .snapshots()
            .listen((doc) async {
              if (!doc.exists) return;
              final songs = List<Map<String, dynamic>>.from(doc['songs'] ?? []);
              debugPrint(
                '[HomePage] Listener attached; ${songs.length} songs for $pid',
              );
              setState(() {
                defaultPlaylist = songs;
              });
              if (currentSong == null && songs.isNotEmpty) {
                playSong(songs[0]);
              }
            });
      }
    });
  }

  void playSong(Map<String, dynamic> song) async {
    String? url = song["previewUrl"];

    if (url == null) return;

    // check exp
    if (isDeezerUrlExpired(url)) {
      print("Preview expired — fetching new link...");
      url = await refreshPreviewUrl(song);

      if (url == null) {
        print("Could not refresh preview URL");
        return;
      }
    }

    setState(() {
      currentSong = song;
    });

    await audioPlayer.stop();
    await audioPlayer.play(UrlSource(url), mode: PlayerMode.mediaPlayer);
  }

  // play song from filtered playlist
  List<Map<String, dynamic>> get currentPlaylist {
    if (selectedGenre == null) return defaultPlaylist;
    return defaultPlaylist
        .where((song) => song['genre'] == selectedGenre)
        .toList();
  }

  void playNextSong() {
    final playlist = currentPlaylist;
    if (currentSong == null || playlist.isEmpty) return;
    
    final currentIndex = playlist.indexWhere((s) => s['spotifyId'] == currentSong!['spotifyId']);
    
    if (currentIndex == -1) {
       if (playlist.isNotEmpty) playSong(playlist[0]);
       return;
    }

    final nextIndex = (currentIndex + 1) % playlist.length;
    playSong(playlist[nextIndex]);
  }

  void playPreviousSong() {
    final playlist = currentPlaylist;
    if (currentSong == null || playlist.isEmpty) return;

    final currentIndex = playlist.indexWhere((s) => s['spotifyId'] == currentSong!['spotifyId']);

    if (currentIndex == -1) {
       if (playlist.isNotEmpty) playSong(playlist[0]);
       return;
    }

    final prevIndex =
        (currentIndex - 1 + playlist.length) % playlist.length;
    playSong(playlist[prevIndex]);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final secondsStr = seconds.toString().padLeft(2, '0');
    return '$minutes:$secondsStr';
  }

  List<String> get availableGenres {
    final genres = <String>{};
    for (var song in defaultPlaylist) {
      if (song['genre'] != null) {
        genres.add(song['genre']);
      }
    }
    final sortedGenres = genres.toList()..sort();
    return ["All", ...sortedGenres];
  }

  Future<void> loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (doc.exists) {
      setState(() {
        username = doc['username'];
        isLoadingUser = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('VibzCheck'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () =>
                Scaffold.of(context).openDrawer(), // Open the drawer
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    child: Text(
                      username != null && username!.isNotEmpty
                          ? username![0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 24, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    username ?? 'Guest',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Update Profile'),
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        UpdateProfileScreen(username: username),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        ),
      ),

      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! > 200) {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const VotingScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        const begin = Offset(-1.0, 0.0);
                        const end = Offset.zero;
                        final tween = Tween(
                          begin: begin,
                          end: end,
                        ).chain(CurveTween(curve: Curves.ease));
                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                ),
              );
            } else if (details.primaryVelocity! < -200) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => MessageBoardScreen(
                    playlistId: currentPlaylistId ?? 'defaultPlaylist',
                    username: username ?? 'Unknown',
                    // currentSong: currentSong,
                  ),
                ),
              );
            }
          }
        },
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.03),

            // genre filter chips
            Container(
              height: 50,
              width: screenWidth * 0.9,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: availableGenres.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final genre = availableGenres[index];
                  final isSelected =
                      (selectedGenre == null && genre == "All") ||
                      selectedGenre == genre;
                  return ChoiceChip(
                    label: Text(genre),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (genre == "All") {
                          selectedGenre = null;
                        } else {
                          selectedGenre = selected ? genre : null;
                        }
                      });
                    },
                  );
                },
              ),
            ),

            Container(
              height: screenHeight * 0.4,
              width: screenWidth * 0.9,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: defaultPlaylist.where((song) {
                  if (selectedGenre == null) return true;
                  return song['genre'] == selectedGenre;
                }).length,
                itemBuilder: (context, index) {
                  // filter playlist based on selection
                  final filteredPlaylist = defaultPlaylist.where((song) {
                    if (selectedGenre == null) return true;
                    return song['genre'] == selectedGenre;
                  }).toList();

                  final song = filteredPlaylist[index];

                  return GestureDetector(
                    onTap: () => playSong(song),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              song["albumArt"],
                              height: 50,
                              width: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "${song['title']} – ${song['artist']}",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: screenHeight * 0.02),

            if (currentSong != null)
              Container(
                height: screenHeight * 0.15,
                width: screenWidth * 0.9,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: currentSong == null
                    ? const Text("No song playing")
                    : Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              currentSong!["albumArt"],
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          // removed playlist label from active song area
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "${currentSong!['title']}\n${currentSong!['artist']}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),

            SizedBox(height: screenHeight * 0.02),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(_formatDuration(currentPosition)),
                      Expanded(
                        child: Slider(
                          value: currentPosition.inSeconds.toDouble(),
                          max: songDuration.inSeconds.toDouble(),
                          onChanged: (value) {
                            audioPlayer.seek(Duration(seconds: value.toInt()));
                          },
                        ),
                      ),
                      Text(_formatDuration(songDuration)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous, size: 36),
                        onPressed: playPreviousSong,
                      ),
                      IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 48,
                        ),
                        onPressed: () async {
                          if (!isPlaying) {
                            await audioPlayer.resume();
                          } else {
                            await audioPlayer.pause();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, size: 36),
                        onPressed: playNextSong,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 20,
            bottom: 20,
            child: FloatingActionButton(
              heroTag: 'voteFab',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const VotingScreen()),
                );
              },
              child: const Icon(Icons.how_to_vote),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                heroTag: 'addFab',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                },
                child: const Icon(Icons.add),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              heroTag: 'msgFab',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MessageBoardScreen(
                      playlistId: currentPlaylistId ?? 'defaultPlaylist',
                      username: username ?? 'Unknown',
                    ),
                  ),
                );
              },
              child: const Icon(Icons.message),
            ),
          ),
        ],
      ),
    );
  }
}
