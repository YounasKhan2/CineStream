import 'package:flutter/material.dart';
import '../services/movie_service.dart';
import 'movie_details_page.dart';
import 'search_results_page.dart';
import 'dart:ui';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MovieService _movieService = MovieService();
  late Future<List<dynamic>> _trendingMovies;
  late Future<List<dynamic>> _topRatedMovies;
  late Future<List<dynamic>> _latestReleases;
  late Future<List<dynamic>> _actionMovies;
  late Future<List<dynamic>> _comedyMovies;
  late Future<List<dynamic>> _horrorMovies;
  late Future<List<dynamic>> _sciFiMovies;
  late Future<List<dynamic>> _dramaMovies;
  late Future<List<dynamic>> _romanceMovies;
  late Future<List<dynamic>> _thrillerMovies;
  late Future<List<dynamic>> _animationMovies;
  final PageController _pageController = PageController(
    initialPage: 0,
    viewportFraction: 1.0,
  ); // Initialize here
  int _currentPage = 0;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _trendingMovies = _movieService.fetchMovies(
      sortBy: 'download_count',
      limit: 5,
    );
    _topRatedMovies = _movieService.fetchMovies(sortBy: 'rating', limit: 10);
    _latestReleases = _movieService.fetchMovies(sortBy: 'year', limit: 10);
    _actionMovies = _movieService.fetchMovies(
      sortBy: 'download_count',
      limit: 10,
      genre: 'Action',
    );
    _comedyMovies = _movieService.fetchMovies(
      sortBy: 'download_count',
      limit: 10,
      genre: 'Comedy',
    );
    _horrorMovies = _movieService.fetchMovies(
      sortBy: 'download_count',
      limit: 10,
      genre: 'Horror',
    );
    _sciFiMovies = _movieService.fetchMovies(
      sortBy: 'download_count',
      limit: 10,
      genre: 'Sci-Fi',
    );
    _dramaMovies = _movieService.fetchMovies(
      sortBy: 'download_count',
      limit: 10,
      genre: 'Drama',
    );
    _romanceMovies = _movieService.fetchMovies(
      sortBy: 'download_count',
      limit: 10,
      genre: 'Romance',
    );
    _thrillerMovies = _movieService.fetchMovies(
      sortBy: 'download_count',
      limit: 10,
      genre: 'Thriller',
    );
    _animationMovies = _movieService.fetchMovies(
      sortBy: 'download_count',
      limit: 10,
      genre: 'Animation',
    );

    // Auto-scroll hero banner
    Future.delayed(const Duration(seconds: 1), () {
      _autoScrollHeroBanner();
    });

    // Detect scroll for app bar transparency
    _scrollController.addListener(() {
      setState(() {
        _isScrolled = _scrollController.offset > 20;
      });
    });
  }

  void _autoScrollHeroBanner() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % 5;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
        _autoScrollHeroBanner();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildHeroSlider(Future<List<dynamic>> moviesFuture) {
    return FutureBuilder<List<dynamic>>(
      future: moviesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.red),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No movies found.'));
        } else {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: PageView.builder(
              controller:
                  _pageController ??
                  PageController(initialPage: 0, viewportFraction: 1.0),
              itemCount: snapshot.data!.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final movie = snapshot.data![index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => MovieDetailsPage(movieId: movie['id']),
                      ),
                    );
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background image
                      // Updated the image display to ensure HD quality and proper fit
                      Image.network(
                        movie['background_image'] ?? '',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.7,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[900],
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.red,
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                              ),
                            ),
                          );
                        },
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.9),
                              Colors.transparent,
                              Colors.black.withOpacity(0.9),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      // Content
                      Positioned(
                        bottom: 120,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movie['title'] ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (movie['rating'] != null)
                                  Text(
                                    '${movie['rating']}/10',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                if (movie['year'] != null)
                                  Text(
                                    '${movie['year']}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              movie['summary'] ?? 'No description available',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Buttons
                      Positioned(
                        bottom: 50,
                        left: 20,
                        right: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(Icons.add, 'My List', () {
                              // TODO: Add to list functionality
                            }),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => MovieDetailsPage(
                                          movieId: movie['id'],
                                        ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Play'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _buildActionButton(Icons.info_outline, 'Info', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => MovieDetailsPage(
                                        movieId: movie['id'],
                                      ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }
      },
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: Icon(icon, color: Colors.white), onPressed: onPressed),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMovieSection(String title, Future<List<dynamic>> moviesFuture) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: FutureBuilder<List<dynamic>>(
            future: moviesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.red),
                );
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No movies found.'));
              } else {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data!.length,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (context, index) {
                    final movie = snapshot.data![index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    MovieDetailsPage(movieId: movie['id']),
                          ),
                        );
                      },
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child:
                                    movie['medium_cover_image'] != null
                                        ? Hero(
                                          tag: 'movie-${movie['id']}',
                                          child: Image.network(
                                            movie['medium_cover_image'],
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            loadingBuilder: (
                                              context,
                                              child,
                                              loadingProgress,
                                            ) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Container(
                                                color: Colors.grey[900],
                                                child: Center(
                                                  child: CircularProgressIndicator(
                                                    color: Colors.red,
                                                    value:
                                                        loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                            : null,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                        : Container(
                                          color: Colors.grey[900],
                                          child: const Center(
                                            child: Icon(
                                              Icons.image,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              movie['title'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(
    String genre,
    Future<List<dynamic>> moviesFuture,
  ) {
    return _buildMovieSection('$genre Movies', moviesFuture);
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return Container(
          width: 8.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(horizontal: 2.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index ? Colors.red : Colors.grey,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: _isScrolled ? Colors.black : Colors.transparent,
        elevation: 0,
        title: const Text(
          'Cine Stream',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () async {
              final query = await showSearch(
                context: context,
                delegate: MovieSearchDelegate((searchQuery) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => SearchResultsPage(query: searchQuery),
                    ),
                  );
                }),
              );
            },
          ),
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Colors.red,
              radius: 16,
              child: const Text(
                'U', // Placeholder for user profile
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            onPressed: () {
              // TODO: Implement profile feature
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollUpdateNotification) {
            setState(() {
              _isScrolled = _scrollController.offset > 20;
            });
          }
          return false;
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroSlider(_trendingMovies),
              const SizedBox(height: 4),
              _buildPageIndicator(),
              const SizedBox(height: 8),
              _buildMovieSection('Trending Now', _trendingMovies),
              _buildMovieSection('Top Rated', _topRatedMovies),
              _buildMovieSection('New Releases', _latestReleases),
              _buildCategorySection('Action', _actionMovies),
              _buildCategorySection('Comedy', _comedyMovies),
              _buildCategorySection('Horror', _horrorMovies),
              _buildCategorySection('Sci-Fi', _sciFiMovies),
              _buildCategorySection('Drama', _dramaMovies),
              _buildCategorySection('Romance', _romanceMovies),
              _buildCategorySection('Thriller', _thrillerMovies),
              _buildCategorySection('Animation', _animationMovies),
              const SizedBox(height: 24),
              // Added developer info card
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline),
            label: 'New & Hot',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library_outlined),
            label: 'My List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.download_outlined),
            label: 'Downloads',
          ),
        ],
      ),
    );
  }
}

class MovieSearchDelegate extends SearchDelegate<String> {
  final Function(String) onSearch;

  MovieSearchDelegate(this.onSearch);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey),
      ),
      textTheme: const TextTheme(titleLarge: TextStyle(color: Colors.white)),
      textSelectionTheme: const TextSelectionThemeData(cursorColor: Colors.red),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
      IconButton(
        icon: const Icon(Icons.mic),
        onPressed: () {
          // TODO: Implement voice search
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onSearch(query);
    });
    close(context, query);
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Top Searches',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildSuggestionItem(context, 'Action movies'),
                _buildSuggestionItem(context, 'Latest releases'),
                _buildSuggestionItem(context, 'Comedy'),
                _buildSuggestionItem(context, 'Science Fiction'),
                _buildSuggestionItem(context, 'Drama'),
              ],
            ),
          ),
        ],
      );
    }
    return Container(color: Colors.black);
  }

  Widget _buildSuggestionItem(BuildContext context, String suggestion) {
    return ListTile(
      leading: const Icon(Icons.search, color: Colors.grey),
      title: Text(suggestion, style: const TextStyle(color: Colors.white)),
      onTap: () {
        query = suggestion;
        showResults(context); // Pass the valid BuildContext here
      },
    );
  }
}
