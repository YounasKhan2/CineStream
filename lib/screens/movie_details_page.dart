import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';

class MovieDetailsPage extends StatefulWidget {
  final int movieId;

  const MovieDetailsPage({Key? key, required this.movieId}) : super(key: key);

  @override
  State<MovieDetailsPage> createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends State<MovieDetailsPage>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _movieDetails;
  VideoPlayerController? _trailerController;
  VideoPlayerController? _movieController;
  ChewieController? _chewieController;
  bool _isFullScreen = false;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isLoadingMovie = false;

  // For tab navigation
  late TabController _tabController;
  final List<String> _tabs = ['Overview', 'More Like This', 'Trailers & More'];

  Future<Map<String, dynamic>> _fetchMovieDetails() async {
    final uri = Uri.parse('https://yts.mx/api/v2/movie_details.json').replace(
      queryParameters: {
        'movie_id': widget.movieId.toString(),
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

  Future<List<Map<String, dynamic>>> _fetchSimilarMovies(String genre) async {
    final uri = Uri.parse('https://yts.mx/api/v2/list_movies.json').replace(
      queryParameters: {
        'genre': genre,
        'limit': '10',
        'sort_by': 'rating',
        'order_by': 'desc',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final movies = data['data']['movies'] as List;
      return movies.map((movie) => Map<String, dynamic>.from(movie)).toList();
    } else {
      throw Exception('Failed to fetch similar movies');
    }
  }

  void _initializeTrailer(String trailerCode) {
    _trailerController = VideoPlayerController.network(
        'https://www.youtube.com/watch?v=$trailerCode',
      )
      ..initialize().then((_) {
        setState(() {});
      });
  }

  void _initializeMoviePlayer(String torrentUrl) {
    setState(() {
      _isLoadingMovie = true;
    });

    // Here we would typically use the torrent url to stream the movie
    // For demonstration purposes, we'll use a sample video
    _movieController = VideoPlayerController.network(
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      )
      ..initialize()
          .then((_) {
            _chewieController = ChewieController(
              videoPlayerController: _movieController!,
              autoPlay: true,
              looping: false,
              allowFullScreen: true,
              aspectRatio: _movieController!.value.aspectRatio,
              deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
              placeholder: Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.red),
                ),
              ),
              materialProgressColors: ChewieProgressColors(
                playedColor: Colors.red,
                handleColor: Colors.red,
                backgroundColor: Colors.grey.shade800,
                bufferedColor: Colors.grey.shade500,
              ),
            );

            setState(() {
              _isLoadingMovie = false;
              _isPlaying = true;
            });
          })
          .catchError((error) {
            setState(() {
              _isLoadingMovie = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error initializing video: ${error.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }
    });
  }

  void _playMovie(Map<String, dynamic> movie) {
    if (movie['torrents'] != null && movie['torrents'].isNotEmpty) {
      final torrentUrl = movie['torrents'][0]['url'];
      _initializeMoviePlayer(torrentUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No streaming sources available for this movie'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _movieDetails = _fetchMovieDetails();
    _tabController = TabController(length: _tabs.length, vsync: this);

    // Auto-hide controls after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _trailerController?.dispose();
    _movieController?.dispose();
    _chewieController?.dispose();
    _tabController.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar:
          _isFullScreen
              ? null
              : AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
      body:
          _isPlaying && _chewieController != null
              ? _buildMoviePlayer()
              : _buildMovieDetails(),
    );
  }

  Widget _buildMoviePlayer() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio:
                  _isFullScreen
                      ? MediaQuery.of(context).size.width /
                          MediaQuery.of(context).size.height
                      : _chewieController!.aspectRatio ?? 16 / 9,
              child: Chewie(controller: _chewieController!),
            ),
          ),
          if (_showControls)
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () {
                  setState(() {
                    _isPlaying = false;
                    _movieController?.pause();
                  });
                },
              ),
            ),
          if (_showControls)
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Icon(
                  _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: _toggleFullScreen,
              ),
            ),
          if (_isLoadingMovie)
            const Center(child: CircularProgressIndicator(color: Colors.red)),
        ],
      ),
    );
  }

  Widget _buildMovieDetails() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _movieDetails,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
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
              'Movie details not found.',
              style: TextStyle(color: Colors.white),
            ),
          );
        } else {
          final movie = snapshot.data!;

          // Initialize trailer if available and not already initialized
          if (movie['yt_trailer_code'] != null &&
              movie['yt_trailer_code'].isNotEmpty &&
              _trailerController == null) {
            _initializeTrailer(movie['yt_trailer_code']);
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeroSection(movie)),
              SliverToBoxAdapter(child: _buildActionsRow(movie)),
              SliverToBoxAdapter(child: _buildInfoSection(movie)),
              SliverToBoxAdapter(child: _buildTabBar()),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(movie),
                    _buildSimilarMoviesTab(movie),
                    _buildTrailersTab(movie),
                  ],
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildHeroSection(Map<String, dynamic> movie) {
    return Stack(
      children: [
        // Background image
        ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.transparent],
            ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
          },
          blendMode: BlendMode.dstIn,
          child: CachedNetworkImage(
            imageUrl:
                movie['background_image_original'] ??
                movie['background_image'] ??
                '',
            height: MediaQuery.of(context).size.height * 0.7,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder:
                (context, url) => Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  ),
                ),
            errorWidget:
                (context, url, error) => Container(
                  color: Colors.black,
                  child: const Center(
                    child: Icon(Icons.error, color: Colors.red),
                  ),
                ),
          ),
        ),

        // Gradient overlay
        Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.6),
                Colors.black.withOpacity(0.8),
                Colors.black,
              ],
              stops: const [0.1, 0.4, 0.7, 0.9],
            ),
          ),
        ),

        // Movie info overlay
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                movie['title'] ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '${movie['year'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(width: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      movie['mpa_rating'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    '${movie['runtime'] ?? 'N/A'} min',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(width: 15),
                  Icon(Icons.hd, color: Colors.white70, size: 20),
                ],
              ),
            ],
          ),
        ),

        // Play button
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () => _playMovie(movie),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(Icons.play_arrow, color: Colors.black, size: 40),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsRow(Map<String, dynamic> movie) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(Icons.add, 'My List'),
          _buildActionButton(Icons.thumb_up_alt_outlined, 'Rate'),
          _buildActionButton(Icons.share, 'Share'),
          _buildActionButton(Icons.file_download_outlined, 'Download'),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildInfoSection(Map<String, dynamic> movie) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.thumb_up_alt, color: Colors.green, size: 16),
              const SizedBox(width: 5),
              Text(
                '${movie['rating'] ?? 'N/A'}/10',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              for (var genre in movie['genres'] ?? [])
                Text(
                  genre,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.red,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, dynamic> movie) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            movie['description_full'] ?? 'No description available.',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          if (movie['cast'] != null && movie['cast'].isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cast',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 5,
                  children: [
                    for (var actor in movie['cast'])
                      Text(
                        actor['name'] ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSimilarMoviesTab(Map<String, dynamic> movie) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future:
          movie['genres'] != null && movie['genres'].isNotEmpty
              ? _fetchSimilarMovies(movie['genres'][0])
              : Future.value([]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Text(
              'No similar movies found',
              style: TextStyle(color: Colors.white70),
            ),
          );
        } else {
          final similarMovies =
              snapshot.data!
                  .where((m) => m['id'] != movie['id'])
                  .take(8)
                  .toList();

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: similarMovies.length,
            itemBuilder: (context, index) {
              final similarMovie = similarMovies[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              MovieDetailsPage(movieId: similarMovie['id']),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: CachedNetworkImage(
                          imageUrl: similarMovie['medium_cover_image'] ?? '',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder:
                              (context, url) => Container(
                                color: Colors.grey[900],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color: Colors.grey[900],
                                child: const Center(
                                  child: Icon(Icons.error, color: Colors.white),
                                ),
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      similarMovie['title'] ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${similarMovie['year'] ?? 'N/A'} • ${similarMovie['rating'] ?? 'N/A'}/10',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildTrailersTab(Map<String, dynamic> movie) {
    if (movie['yt_trailer_code'] == null || movie['yt_trailer_code'].isEmpty) {
      return const Center(
        child: Text(
          'No trailers available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Official Trailer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          if (_trailerController != null &&
              _trailerController!.value.isInitialized)
            Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: _trailerController!.value.aspectRatio,
                  child: VideoPlayer(_trailerController!),
                ),
                IconButton(
                  icon: Icon(
                    _trailerController!.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 50,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_trailerController!.value.isPlaying) {
                        _trailerController!.pause();
                      } else {
                        _trailerController!.play();
                      }
                    });
                  },
                ),
              ],
            )
          else
            Container(
              height: 200,
              color: Colors.grey[900],
              child: const Center(
                child: CircularProgressIndicator(color: Colors.red),
              ),
            ),
          const SizedBox(height: 20),
          if (movie['medium_screenshot_image1'] != null ||
              movie['medium_screenshot_image2'] != null ||
              movie['medium_screenshot_image3'] != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Screenshots',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (movie['medium_screenshot_image1'] != null)
                        _buildScreenshotItem(movie['medium_screenshot_image1']),
                      if (movie['medium_screenshot_image2'] != null)
                        _buildScreenshotItem(movie['medium_screenshot_image2']),
                      if (movie['medium_screenshot_image3'] != null)
                        _buildScreenshotItem(movie['medium_screenshot_image3']),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildScreenshotItem(String imageUrl) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder:
              (context, url) => Container(
                color: Colors.grey[900],
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.red),
                ),
              ),
          errorWidget:
              (context, url, error) => Container(
                color: Colors.grey[900],
                child: const Center(
                  child: Icon(Icons.error, color: Colors.white),
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildTrailersAndMoreSection(List<dynamic> trailers) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var trailer in trailers)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        trailer['thumbnail'] ?? '',
                        fit: BoxFit.cover,
                        height: 100,
                        width: 150,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trailer['title'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            trailer['duration'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
