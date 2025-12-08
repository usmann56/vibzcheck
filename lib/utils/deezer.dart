import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String?> fetchDeezerPreviewUrl(
  String trackName,
  String artistName,
) async {
  final query = Uri.encodeQueryComponent("$trackName $artistName");

  final url = Uri.parse("https://api.deezer.com/search?q=$query");

  final res = await http.get(url);

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);

    if (data['data'] != null && data['data'].isNotEmpty) {
      final preview = data['data'][0]['preview'];
      return preview; // Might be null but usually is valid
    }
  }

  return null;
}
