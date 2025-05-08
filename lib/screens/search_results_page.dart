import 'package:flutter/material.dart';
import '../services/movie_service.dart';
import 'movie_details_page.dart';

class SearchResultsPage extends StatelessWidget {
  final String query;

  const SearchResultsPage({Key? key, required this.query}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MovieService movieService = MovieService();
    final Future<List<dynamic>> searchResults = movieService.fetchMovies(
      sortBy: 'download_count',
      limit: 10,
      queryTerm: query,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results for "$query"'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: FutureBuilder<List<dynamic>>(
        future: searchResults,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No movies found.',
                style: TextStyle(color: Colors.white),
              ),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final movie = snapshot.data![index];
                return ListTile(
                  leading:
                      movie['medium_cover_image'] != null
                          ? Image.network(
                            movie['medium_cover_image'],
                            width: 50,
                            fit: BoxFit.cover,
                          )
                          : const Icon(Icons.image, color: Colors.white),
                  title: Text(
                    movie['title'] ?? 'Unknown',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Year: ${movie['year'] ?? 'N/A'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => MovieDetailsPage(movieId: movie['id']),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
