import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'voting_screen.dart';
import 'search_screen.dart';
import 'message_board_screen.dart';
import '../utils/deezer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> defaultPlaylist = [];
  Map<String, dynamic>? currentSong;
  bool isPlaying = false;

  AudioPlayer audioPlayer = AudioPlayer();
  Duration currentPosition = Duration.zero;
  Duration songDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    listenDefaultPlaylist();

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
  }

  @override
  void dispose() {
    // _audioPlayer.dispose();
    super.dispose();
  }

  Future<String?> refreshPreviewUrl(Map<String, dynamic> song) async {
    final deezerId = song["deezerId"];
    if (deezerId == null) return null;

    final newUrl = await fetchNewPreviewUrl(deezerId);

    if (newUrl != null) {
      // update Firestore
      final playlistRef = FirebaseFirestore.instance
          .collection("playlists")
          .doc("defaultPlaylist");

      final songs = List<Map<String, dynamic>>.from(defaultPlaylist);
      final index = songs.indexWhere((s) => s["id"] == song["id"]);
      if (index != -1) {
        songs[index]["previewUrl"] = newUrl;
      }

      await playlistRef.update({"songs": songs});
      return newUrl;
    }

    return null;
  }

  void listenDefaultPlaylist() {
    FirebaseFirestore.instance
        .collection('playlists')
        .doc('defaultPlaylist')
        .snapshots()
        .listen((doc) {
          if (doc.exists) {
            final songs = List<Map<String, dynamic>>.from(doc['songs'] ?? []);
            setState(() {
              defaultPlaylist = songs;

              // If no song is playing yet, start the first song
              if (currentSong == null && songs.isNotEmpty) {
                currentSong = songs[0];
                playSong(currentSong!);
              }

              // Ensure current song is still in the playlist
              if (currentSong != null &&
                  !songs.any((song) => song['id'] == currentSong!['id'])) {
                currentSong = songs.isNotEmpty ? songs[0] : null;
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

  void playNextSong() {
    if (currentSong == null || defaultPlaylist.isEmpty) return;
    final currentIndex = defaultPlaylist.indexOf(currentSong!);
    final nextIndex = (currentIndex + 1) % defaultPlaylist.length;
    playSong(defaultPlaylist[nextIndex]);
  }

  void playPreviousSong() {
    if (currentSong == null || defaultPlaylist.isEmpty) return;
    final currentIndex = defaultPlaylist.indexOf(currentSong!);
    final prevIndex =
        (currentIndex - 1 + defaultPlaylist.length) % defaultPlaylist.length;
    playSong(defaultPlaylist[prevIndex]);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final secondsStr = seconds.toString().padLeft(2, '0');
    return '$minutes:$secondsStr';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text('VibzCheck')),
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
              Navigator.of(context).pushNamed('/messageboard');
            }
          }
        },
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.03),

            Container(
              height: screenHeight * 0.4,
              width: screenWidth * 0.9,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: defaultPlaylist.length,
                itemBuilder: (context, index) {
                  final song = defaultPlaylist[index];

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
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MessageBoardScreen(),
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
