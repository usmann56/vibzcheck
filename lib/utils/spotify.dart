import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

Future<String?> fetchSpotifyAccessToken() async {
  // func to get spotify access token
  try {
    final doc = await FirebaseFirestore.instance
        .collection('spotify')
        .doc('env')
        .get();

    if (!doc.exists) {
      print("No token document found in Firestore.");
      return null;
    }
    final docToken = doc['token'] as String;

    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Authorization': 'Basic $docToken',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'grant_type': 'client_credentials'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['access_token'] as String;
    } else {
      print(
        "Spotify token request failed: ${response.statusCode} ${response.body}",
      );
      return null;
    }
  } catch (e) {
    print("Error fetching Spotify token: $e");
    return null;
  }
}

Future<String> fetchArtistGenre(String artistId) async {
  try {
    final String? accessToken = await fetchSpotifyAccessToken();
    if (accessToken == null) return "Unknown";

    final url = Uri.parse("https://api.spotify.com/v1/artists/$artistId");
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $accessToken"},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final genres = List<String>.from(data['genres'] ?? []);
      if (genres.isNotEmpty) {
        return genres.first; // Return the first genre
      }
    }
  } catch (e) {
    print("Error fetching artist genre: $e");
  }
  return "Unknown";
}
