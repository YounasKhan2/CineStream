import 'dart:convert';
import 'package:http/http.dart' as http;

class MovieService {
  static const String baseUrl = 'https://yts.mx/api/v2/list_movies.json';

  Future<List<dynamic>> fetchMovies({
    required String sortBy,
    int limit = 10,
    String? genre,
    String? queryTerm,
  }) async {
    try {
      final queryParameters = {
        'sort_by': sortBy,
        'limit': limit.toString(),
        if (genre != null) 'genre': genre,
        if (queryTerm != null) 'query_term': queryTerm,
      };

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParameters);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['movies'] ?? [];
      } else {
        throw Exception('Failed to load movies');
      }
    } catch (e) {
      throw Exception('Error fetching movies: $e');
    }
  }
}
