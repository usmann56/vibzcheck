import 'package:flutter/material.dart';

class VotingScreen extends StatefulWidget {
  const VotingScreen({super.key});

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  // Example placeholder song list
  final List<String> songs = [
    'Song actively being voted on (highlighted)',
    'Song 2 (placeholder)',
    'Song 3 (placeholder)',
    'Song 4 (placeholder)',
    'Song 5 (placeholder)',
    'Song 6 (placeholder)',
    'Song 7 (placeholder)',
    'Song 8 (placeholder)',
    'Song 9 (overflow)',
    'Song 10 (overflow)',
  ];
  int upvotes = 0;
  int downvotes = 0;
  String? userVote; // 'up', 'down', or null

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voting')),
      body: GestureDetector(
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
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final isActive = index == 0;
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
                        songs[index],
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
                child: const Text(
                  'Current song being played (placeholder)',
                  style: TextStyle(fontSize: 18),
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
                        onPressed: () {
                          setState(() {
                            if (userVote == 'up') {
                              // Already upvoted, do nothing
                            } else if (userVote == 'down') {
                              downvotes = (downvotes - 1).clamp(0, 9999);
                              upvotes++;
                              userVote = 'up';
                            } else {
                              upvotes++;
                              userVote = 'up';
                            }
                          });
                        },
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
                        child: const Text(
                          'Timer (placeholder)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'You can change your answer before timer runs out.',
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
                        onPressed: () {
                          setState(() {
                            if (userVote == 'down') {
                              // Already downvoted, do nothing
                            } else if (userVote == 'up') {
                              upvotes = (upvotes - 1).clamp(0, 9999);
                              downvotes++;
                              userVote = 'down';
                            } else {
                              downvotes++;
                              userVote = 'down';
                            }
                          });
                        },
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
            ],
          ),
        ),
      ),
    );
  }
}
