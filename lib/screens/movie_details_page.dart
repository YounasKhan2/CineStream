import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/movie_service.dart';

class MovieDetailsPage extends StatelessWidget {
  final int movieId;

  const MovieDetailsPage({Key? key, required this.movieId}) : super(key: key);

  Future<Map<String, dynamic>> _fetchMovieDetails() async {
    final movieService = MovieService();
    final uri = Uri.parse('https://yts.mx/api/v2/movie_details.json').replace(
      queryParameters: {
        'movie_id': movieId.toString(),
        'with_images': 'true',
        'with_cast': 'true',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Map<String, dynamic>.from(data['data']['movie']);
    } else {
      throw Exception('Failed to fetch movie details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Details'),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchMovieDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Movie details not found.'));
          } else {
            final movie = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie['title'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Year: ${movie['year'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Rating: ${movie['rating'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      movie['description_full'] ?? 'No description available.',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
