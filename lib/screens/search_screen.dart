import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/spotify.dart';
import '../../utils/deezer.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _results = [];
  dynamic _selectedTrack;

  bool _isLoading = false;

  Future<void> searchSpotify(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _selectedTrack = null;
    });

    final url = Uri.parse(
      "https://api.spotify.com/v1/search?q=$query&type=track&limit=10",
    );

    final String? _accessToken = await fetchSpotifyAccessToken();
    final res = await http.get(
      url,
      headers: {"Authorization": "Bearer $_accessToken"},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        _results = data['tracks']['items'];
      });
    } else {
      print("Error: ${res.body}");
    }

    setState(() {
      _isLoading = false;
    });
  }

  void addToPlaylist() async {
    if (_selectedTrack == null) return;

    final trackName = _selectedTrack["name"];
    final artist = _selectedTrack["artists"][0]["name"];
    final albumArt = _selectedTrack["album"]["images"][0]["url"];

    // Fetch preview from deezer since spotify doesnt provide it easily
    final deezerData = await fetchDeezerPreviewUrl(trackName, artist);

    final previewUrl = deezerData["previewUrl"];
    final deezerId = deezerData["deezerId"];

    // Fetch genre from Spotify Artist API since track api doesnt have that
    final artistId = _selectedTrack["artists"][0]["id"];
    final genre = await fetchArtistGenre(artistId);

    final songData = {
      "title": trackName,
      "artist": artist,
      "albumArt": albumArt,
      "spotifyId": _selectedTrack["id"],
      "previewUrl": previewUrl,
      "deezerId": deezerId,
      "genre": genre,
    };

    // Use user's selected playlist
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    final userDoc = await DatabaseService().getUser(uid);
    final playlistId = userDoc.data()?['currentPlaylistId'] as String?;
    final targetId = playlistId ?? 'defaultPlaylist';

    await DatabaseService().addSongToVoting(targetId, songData);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Added: $trackName – $artist")));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text("Search Songs")),

      body: Column(
        children: [
          SizedBox(height: screenHeight * 0.03),

          // search bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: TextField(
              controller: _searchController,
              onSubmitted: searchSpotify,
              decoration: InputDecoration(
                hintText: "Search song, artist, or album...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),

          SizedBox(height: screenHeight * 0.02),

          // search results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      final name = item["name"];
                      final artist = item["artists"][0]["name"];
                      final albumArt = item["album"]["images"].isNotEmpty
                          ? item["album"]["images"][0]["url"]
                          : null;

                      final isSelected = _selectedTrack == item;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTrack = item;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05,
                            vertical: 8,
                          ),
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
                                child: albumArt != null
                                    ? Image.network(
                                        albumArt,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      artist,
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

          // add button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: ElevatedButton(
              onPressed: _selectedTrack == null ? null : addToPlaylist,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.3,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "Add to Voting",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
