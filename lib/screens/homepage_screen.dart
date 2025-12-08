import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'voting_screen.dart';
import 'search_screen.dart';
import 'message_board_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> defaultPlaylist = [];
  Map<String, dynamic>? currentSong;
  bool isPlaying = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration(seconds: 180);

  @override
  void initState() {
    super.initState();
    listenDefaultPlaylist();

    // Listen to audio player position
    _audioPlayer.positionStream.listen((position) {
      setState(() {
        _currentPosition = position;
      });
    });

    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        playNextSong();
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
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

  Future<void> playSong(Map<String, dynamic> song) async {
    setState(() {
      currentSong = song;
      isPlaying = true;
    });

    print('Playing song: ${song['previewUrl']}');
    final url = song['previewUrl'];
    if (url != null && url.isNotEmpty) {
      try {
        await _audioPlayer.setUrl(url);
        _audioPlayer.play();
      } catch (e) {
        print("Error playing song: $e");
      }
    }
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
              child: defaultPlaylist.isEmpty
                  ? const Center(
                      child: Text(
                        'Song list appears here-',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: defaultPlaylist.length,
                      itemBuilder: (context, index) {
                        final song = defaultPlaylist[index];
                        final isSelected = song == currentSong;

                        return GestureDetector(
                          onTap: () => playSong(song),
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.secondary
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: song['albumArt'] != null
                                      ? Image.network(
                                          song['albumArt'],
                                          height: 55,
                                          width: 55,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          height: 55,
                                          width: 55,
                                          color: Colors.black26,
                                          child: const Icon(Icons.music_note),
                                        ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song['name'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        song['artist'],
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
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
                child: Row(
                  children: [
                    currentSong!['albumArt'] != null
                        ? Image.network(
                            currentSong!['albumArt'],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: Colors.black26,
                            child: const Icon(Icons.music_note),
                          ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentSong!['name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            currentSong!['artist'],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
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
                      Text(_formatDuration(_currentPosition)),
                      Expanded(
                        child: Slider(
                          value: _currentPosition.inSeconds.toDouble(),
                          min: 0,
                          max: _totalDuration.inSeconds.toDouble(),
                          onChanged: (value) {
                            _audioPlayer.seek(Duration(seconds: value.toInt()));
                          },
                        ),
                      ),
                      Text(_formatDuration(_totalDuration)),
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
                        onPressed: () {
                          setState(() {
                            isPlaying = !isPlaying;
                          });
                          isPlaying
                              ? _audioPlayer.play()
                              : _audioPlayer.pause();
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
