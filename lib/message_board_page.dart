import 'package:flutter/material.dart';

class MessageBoardPage extends StatelessWidget {
  const MessageBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(title: const Text('Message Board')),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 200) {
            Navigator.of(context).pop();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Top container: Current song and playlist info
              Container(
                height: screenHeight * 0.15,
                width: screenWidth * 0.9,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Current Song: [Placeholder]\nActive Playlist: [Placeholder]',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              // Middle container: Chat messages
              Container(
                height: screenHeight * 0.5,
                width: screenWidth * 0.9,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'Chat messages appear here (placeholder)',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              // Bottom container: Text input field
              Container(
                height: screenHeight * 0.1,
                width: screenWidth * 0.9,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter your message (placeholder)',
                    border: InputBorder.none,
                  ),
                  enabled: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
