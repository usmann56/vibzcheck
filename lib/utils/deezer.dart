import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, String?>> fetchDeezerPreviewUrl(
  String trackName,
  String artistName,
) async {
  final query = Uri.encodeQueryComponent('$trackName $artistName');
  final url = Uri.parse("https://api.deezer.com/search?q=$query");

  final res = await http.get(url);

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);

    if (data['data'] != null && data['data'].isNotEmpty) {
      final track = data['data'][0];

      return {
        "previewUrl": track["preview"], // can be null if unavailable
        "deezerId": track["id"]?.toString(), // needed for refresh later
      };
    }
  }

  return {"previewUrl": null, "deezerId": null};
}

Future<String?> fetchNewPreviewUrl(String deezerTrackId) async {
  print('Fetching fresh preview for Deezer track ID: $deezerTrackId');
  final url = Uri.parse("https://api.deezer.com/track/$deezerTrackId");

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print('Deezer track data: $data');
    return data["preview"];
  }

  return null;
}

bool isDeezerUrlExpired(String url) {
  final expMatch = RegExp(r"exp=(\d+)").firstMatch(url);
  if (expMatch == null) return true; // No exp found → treat as expired

  final expSeconds = int.tryParse(expMatch.group(1)!);
  if (expSeconds == null) return true;

  final expiryDate = DateTime.fromMillisecondsSinceEpoch(expSeconds * 1000);
  return DateTime.now().isAfter(expiryDate); // true → expired
}
