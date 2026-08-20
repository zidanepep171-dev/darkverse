import 'package:flutter/material.dart';
import 'dv_theme.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeCeramahPage extends StatefulWidget {
  const HomeCeramahPage({super.key});

  @override
  State<HomeCeramahPage> createState() => _HomeCeramahPageState();
}

class _HomeCeramahPageState extends State<HomeCeramahPage> {
  Map<String, dynamic>? ceramahData;
  bool isLoading = true;
  bool isSearching = false;
  List<dynamic> searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _watchHistory = [];
  bool _isHistoryLoading = true;

  final String youtubeApiKey = "AIzaSyDHApPeQE_HaRhyJNkRU15J-n9wRexEG4M";

  @override
  void initState() {
    super.initState();
    fetchCeramahData();
    _loadWatchHistory();
  }

  void refreshHistory() {
    _loadWatchHistory();
  }

  Future<void> _loadWatchHistory() async {
    setState(() => _isHistoryLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('ceramah_history') ?? [];
      setState(() {
        _watchHistory = historyJson
            .map((item) => Map<String, dynamic>.from(json.decode(item))).toList();
        _isHistoryLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading history: $e');
      setState(() => _isHistoryLoading = false);
    }
  }

  Future<void> fetchCeramahData() async {
    try {
      final latestRes = await http.get(Uri.parse('https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=UC1qLqLqLqLqLqLqLqLqLqLq&maxResults=10&order=date&type=video&key=$youtubeApiKey'));
      
      final popularRes = await http.get(Uri.parse('https://www.googleapis.com/youtube/v3/search?part=snippet&q=ceramah+terbaru&maxResults=10&order=viewCount&type=video&key=$youtubeApiKey'));

      if (latestRes.statusCode == 200 && popularRes.statusCode == 200) {
        final latestJson = json.decode(latestRes.body)['items'] as List;
        final popularJson = json.decode(popularRes.body)['items'] as List;

        setState(() {
          ceramahData = {
            'latest_ceramah': latestJson.map((e) => _mapYouTubeToApp(e)).toList(),
            'popular_ceramah': popularJson.map((e) => _mapYouTubeToApp(e)).toList(),
          };
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data ceramah');
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> searchCeramah(String query) async {
    if (query.isEmpty) {
      setState(() {
        isSearching = false;
        searchResults.clear();
      });
      return;
    }

    setState(() => isSearching = true);

    try {
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/youtube/v3/search?part=snippet&q=$query+ceramah&maxResults=10&type=video&key=$youtubeApiKey'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final rawList = jsonData['items'] as List;
        setState(() {
          searchResults = rawList.map((e) => _mapYouTubeToApp(e)).toList();
        });
      } else {
        setState(() => searchResults = []);
      }
    } catch (e) {
      debugPrint('Search Error: $e');
      setState(() => searchResults = []);
    }
  }

  Map<String, dynamic> _mapYouTubeToApp(dynamic item) {
    return {
      'title': item['snippet']['title'] ?? 'No Title',
      'poster': item['snippet']['thumbnails']['high']['url'] ?? '',
      'channel': item['snippet']['channelTitle'] ?? 'Unknown',
      'published': item['snippet']['publishedAt'] ?? '',
      'videoId': item['id']['videoId'] ?? '',
      'slug': item['id']['videoId'] ?? '',
      'description': item['snippet']['description'] ?? '',
    };
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      isSearching = false;
      searchResults.clear();
    });
    _searchFocusNode.unfocus();
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);
      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()} tahun lalu';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} bulan lalu';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} hari lalu';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} jam lalu';
      } else {
        return 'Baru saja';
      }
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: "Cari ceramah atau ustadz...",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: DV.orange),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: DV.glassCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: DV.orange.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: DV.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: DV.orange),
                ),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _searchFocusNode.unfocus();
                  searchCeramah(value.trim());
                }
              },
            ),
          ),

          Expanded(
            child: isLoading
                ? _buildLoadingShimmer()
                : isSearching
                    ? _buildSearchResults()
                    : ceramahData == null
                        ? _buildErrorWidget()
                        : _buildHomeContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([fetchCeramahData(), _loadWatchHistory()]);
      },
      color: DV.amber,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isHistoryLoading && _watchHistory.isNotEmpty) ...[
              _buildSectionHeader(Icons.history, "Lanjutkan Menonton"),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _watchHistory.length,
                  itemBuilder: (context, index) {
                    return _buildHistoryCard(_watchHistory[index]);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            _buildSectionHeader(Icons.explore, "Jelajahi Ceramah"),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildQuickAccessCard("Kajian Rutin", Icons.mosque, () {
                  searchCeramah("kajian rutin");
                })),
                const SizedBox(width: 12),
                Expanded(child: _buildQuickAccessCard("Tausiyah", Icons.volume_up, () {
                  searchCeramah("tausiyah");
                })),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionHeader(Icons.fiber_new, "Ceramah Terbaru"),
            const SizedBox(height: 12),
            _buildCeramahGrid(ceramahData!['latest_ceramah']),
            const SizedBox(height: 24),

            _buildSectionHeader(Icons.trending_up, "Trending"),
            const SizedBox(height: 12),
            _buildCeramahGrid(ceramahData!['popular_ceramah']),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: DV.amber, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> ceramah) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CeramahDetailPage(
                ceramahData: ceramah,
                onHistoryUpdate: refreshHistory,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ceramah['poster'],
                    height: 160,
                    width: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: DV.bg2),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    color: DV.bg0.withOpacity(0.85),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_circle_fill, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text("Tonton", style: TextStyle(color: Colors.white, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ceramah['title'],
              style: const TextStyle(color: DV.textPrimary, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCeramahGrid(List<dynamic> list) {
    return GridView.builder(
      itemCount: list.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 280,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final ceramah = list[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CeramahDetailPage(
                  ceramahData: ceramah,
                  onHistoryUpdate: refreshHistory,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        ceramah['poster'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: DV.bg2),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, DV.bg0.withOpacity(0.85)],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: DV.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _formatDate(ceramah['published']),
                            style: const TextStyle(color: DV.textPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ceramah['title'],
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                ceramah['channel'],
                style: TextStyle(fontSize: 11, color: DV.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (searchResults.isEmpty) {
      return const Center(child: Text("Tidak ditemukan", style: TextStyle(color: Colors.white)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final ceramah = searchResults[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: DV.glassCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DV.bg2),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(ceramah['poster'], width: 60, height: 90, fit: BoxFit.cover),
            ),
            title: Text(ceramah['title'], style: const TextStyle(color: DV.textPrimary, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(ceramah['channel'], style: const TextStyle(color: DV.textSecondary)),
                const SizedBox(height: 4),
                Text(_formatDate(ceramah['published']), style: const TextStyle(color: DV.textSecondary)),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CeramahDetailPage(
                    ceramahData: ceramah,
                    onHistoryUpdate: refreshHistory,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
  }

  Widget _buildErrorWidget() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: DV.orange),
        onPressed: fetchCeramahData,
        child: const Text("Coba Lagi", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildQuickAccessCard(String title, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [DV.orange.withOpacity(0.2), DV.amber.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DV.orange.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(color: DV.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class CeramahDetailPage extends StatefulWidget {
  final Map<String, dynamic> ceramahData;
  final Function()? onHistoryUpdate;

  const CeramahDetailPage({super.key, required this.ceramahData, this.onHistoryUpdate});

  @override
  State<CeramahDetailPage> createState() => _CeramahDetailPageState();
}

class _CeramahDetailPageState extends State<CeramahDetailPage> {

  @override
  void initState() {
    super.initState();
    _saveHistory();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('ceramah_history') ?? [];
    List<Map<String, dynamic>> history = historyJson
        .map((item) => Map<String, dynamic>.from(json.decode(item))).toList();

    history.removeWhere((item) => item['slug'] == widget.ceramahData['slug']);
    history.insert(0, widget.ceramahData);
    
    if (history.length > 20) history = history.sublist(0, 20);

    await prefs.setStringList('ceramah_history', history.map((e) => json.encode(e)).toList());
    if (widget.onHistoryUpdate != null) widget.onHistoryUpdate!();
  }

  @override
  Widget build(BuildContext context) {
    final ceramah = widget.ceramahData;
    
    return Scaffold(
      backgroundColor: DV.bg0,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            backgroundColor: DV.bg0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    ceramah['poster'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: DV.bg1),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          DV.bg0.withOpacity(0.5),
                          DV.bg0,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: DV.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            ceramah['channel'],
                            style: const TextStyle(color: DV.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ceramah['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: DV.bg0, blurRadius: 10)],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time, color: DV.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(_formatDate(ceramah['published']), style: const TextStyle(color: DV.textPrimary, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [DV.orange, DV.amber]),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(color: DV.orange.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      onPressed: () {
                        final url = "https://www.youtube.com/watch?v=${ceramah['videoId']}";
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CeramahWebView(url: url, title: ceramah['title']),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      label: const Text("TONTON VIDEO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  const Text("Deskripsi", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    ceramah['description'] ?? "Tidak ada deskripsi",
                    style: TextStyle(color: DV.textSecondary, height: 1.5),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);
      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()} tahun lalu';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} bulan lalu';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} hari lalu';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} jam lalu';
      } else {
        return 'Baru saja';
      }
    } catch (e) {
      return dateStr;
    }
  }
}

class CeramahWebView extends StatefulWidget {
  final String url;
  final String? title;

  const CeramahWebView({super.key, required this.url, this.title});

  @override
  State<CeramahWebView> createState() => _CeramahWebViewState();
}

class _CeramahWebViewState extends State<CeramahWebView> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if(mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            if(mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DV.bg0,
      appBar: AppBar(
        backgroundColor: DV.bg0,
        iconTheme: IconThemeData(color: DV.textPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title ?? "Ceramah", style: const TextStyle(color: DV.textPrimary, fontSize: 14)),
            const Text("YouTube", style: TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () => launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
        ],
      ),
    );
  }
}