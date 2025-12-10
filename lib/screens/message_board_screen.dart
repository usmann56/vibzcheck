import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import 'package:flutter/material.dart';

class MessageBoardScreen extends StatefulWidget {
  final String playlistId;
  final String username;

  const MessageBoardScreen({
    super.key,
    required this.playlistId,
    required this.username,
  });

  @override
  State<MessageBoardScreen> createState() => _MessageBoardScreenState();
}

class _MessageBoardScreenState extends State<MessageBoardScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    await DatabaseService().sendMessage(
      widget.playlistId,
      widget.username,
      text.trim(),
    );

    controller.clear();

    Future.delayed(const Duration(milliseconds: 150), () {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    });
  }

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return "Today";
    if (difference == 1) return "Yesterday";
    return "${date.day}/${date.month}/${date.year}";
  }

  bool isDifferentDay(DateTime a, DateTime b) {
    return a.year != b.year || a.month != b.month || a.day != b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat for ${widget.playlistId}')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: DatabaseService().getMessagesStream(widget.playlistId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("No messages yet. Say hi!"));
                }

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final username = data['username'] ?? "Unknown";
                    final text = data['text'] ?? "";
                    final timestamp =
                        (data['timestamp'] as Timestamp?)?.toDate() ??
                        DateTime.now();

                    final isMe = username == widget.username;

                    // group by day
                    bool showDateHeader = false;
                    if (index == 0)
                      showDateHeader = true;
                    else {
                      final prevTime =
                          (docs[index - 1].data() as Map)['timestamp'] != null
                          ? (docs[index - 1]['timestamp'] as Timestamp).toDate()
                          : timestamp;
                      showDateHeader = isDifferentDay(prevTime, timestamp);
                    }

                    return Column(
                      children: [
                        if (showDateHeader)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  formatDate(timestamp),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        messageTile(
                          username: username,
                          message: text,
                          isMine: isMe,
                          timestamp: Timestamp.fromDate(timestamp),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // input box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.black12,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Type a message…",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, size: 28),
                  onPressed: () => sendMessage(controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget messageTile({
  required String username,
  required String message,
  required bool isMine,
  required Timestamp timestamp,
}) {
  return Row(
    mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Flexible(
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Text(
                username,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 3),
            // message bubble
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMine ? Colors.blue : Colors.grey.shade800,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: isMine ? const Radius.circular(14) : Radius.zero,
                  bottomRight: isMine ? Radius.zero : const Radius.circular(14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTimestamp(timestamp),
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

String _formatTimestamp(Timestamp ts) {
  final date = ts.toDate();
  return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
}
