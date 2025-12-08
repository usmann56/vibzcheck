import 'package:flutter/material.dart';
import 'package:vibzcheck/message_board_page.dart';
import 'voting_page.dart';
import 'screens/search_screen.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

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
                      const VotingPage(),
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
            SizedBox(height: screenHeight * 0.05),
            Center(
              child: Container(
                height: screenHeight * 0.4,
                width: screenWidth * 0.90,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Text(
                    'Song list appears here-',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            Center(
              child: Container(
                height: screenHeight * 0.15,
                width: screenWidth * 0.9,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    'Current Song: [Cover Art] [Artist] [Album] [Title]',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            // Audio player placeholder
            Column(
              children: [
                // Seek bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: Row(
                    children: [
                      const Text('0:00'),
                      Expanded(
                        child: Slider(
                          value: 0,
                          min: 0,
                          max: 100,
                          onChanged: (value) {},
                        ),
                      ),
                      const Text('3:30'),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                // Playback controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 36),
                      onPressed: () {}, // To be implemented
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_arrow, size: 48),
                      onPressed: () {}, // To be implemented
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 36),
                      onPressed: () {}, // To be implemented
                    ),
                  ],
                ),
                // Note: Prepare for Spotify API integration here
              ],
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Stack(
        clipBehavior: Clip.none,
        children: [
          // left button
          Positioned(
            left: 20,
            bottom: 20,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const VotingPage()),
                );
              },
              child: Icon(Icons.how_to_vote),
            ),
          ),

          // center button
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

          // right button
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MessageBoardPage(),
                  ),
                );
              },
              child: Icon(Icons.message),
            ),
          ),
        ],
      ),
    );
  }
}
