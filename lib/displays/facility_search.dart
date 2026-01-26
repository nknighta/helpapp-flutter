import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/global_layout.dart';
import '../router.dart';
import '../services/database_helper.dart';
import '../services/location_service.dart';

enum SortOption { distance, newest, name }

class FacilityListScreen extends StatefulWidget {
  const FacilityListScreen({Key? key}) : super(key: key);

  static const String routeName = '/facility_search';

  @override
  State<FacilityListScreen> createState() => _FacilityListScreenState();
}

class _FacilityListScreenState extends State<FacilityListScreen> {
  // ===== Services / Controllers =====
  final DatabaseHelper _db = DatabaseHelper();
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  // ===== Data =====
  List<Map<String, dynamic>> _places = [];
  List<Map<String, dynamic>> _filtered = [];
  List<Map<String, dynamic>> _visible = [];

  // ===== Filters / Sorting =====
  Set<String> _categories = {};
  String _activeCategory = 'All';
  SortOption _sort = SortOption.distance;

  // ===== UI State =====
  bool _loading = true;
  String _error = '';

  // ===== Pagination =====
  final int _pageSize = 20;
  int _page = 0;
  bool _isLoadingMore = false;

  // ===== Location =====
  double? _currentLat;
  double? _currentLng;

  @override
  void initState() {
    super.initState();
    _init();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // ===== Search =====
  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      _applyFiltersAndSort,
    );
  }

  // ===== Lifecycle / Init =====
  Future<void> _init() async {
    await _initLocation();
    await _fetchPlaces();
  }

  // ===== Location =====
  Future<void> _initLocation() async {
    try {
      final loc = await _locationService.getCurrentLocation();
      if (loc != null) {
        setState(() {
          _currentLat = loc.latitude;
          _currentLng = loc.longitude;
        });
      }
    } catch (_) {
      // ignore location errors
    }
  }

  // ===== Data Fetch =====
  Future<void> _fetchPlaces() async {
    setState(() {
      _loading = true;
      _error = '';
      _page = 0;
      _visible.clear();
      _places.clear();
      _categories.clear();
    });

    try {
      final uri =
          await _db.getActiveDebugServerUri('/api/v1/place/list') ??
          Uri.parse('https://helpapp-website.vercel.app/api/v1/place/list');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final items =
              data
                  .map(
                    (e) =>
                        e is Map
                            ? Map<String, dynamic>.from(e)
                            : <String, dynamic>{},
                  )
                  .toList();

          _preparePlaces(items);
          setState(() => _places = items);
          _applyFiltersAndSort();
        } else {
          setState(() => _error = 'サーバーの応答が想定と異なります。');
        }
      } else {
        setState(() => _error = '施設の読み込みに失敗しました: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = '施設の読み込みに失敗しました: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // ===== Data Helpers =====
  void _preparePlaces(List<Map<String, dynamic>> items) {
    _categories.clear();
    for (final item in items) {
      _attachDistanceIfPossible(item);
      final cat = (item['category']?.toString() ?? '').trim();
      if (cat.isNotEmpty) _categories.add(cat);
    }
  }

  // Compute & attach 'distance' (meters) when current location is available
  void _attachDistanceIfPossible(Map<String, dynamic> item) {
    final lat = _toDouble(item['latitude']) ?? _toDouble(item['lat']);
    final lng = _toDouble(item['longitude']) ?? _toDouble(item['lng']);
    if (lat != null &&
        lng != null &&
        _currentLat != null &&
        _currentLng != null) {
      item['distance'] = _haversineDistance(
        _currentLat!,
        _currentLng!,
        lat,
        lng,
      );
    } else {
      item.remove('distance');
    }
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    if (v is num) return v.toDouble();
    return null;
  }

  double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371000; // meters
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (math.pi / 180.0);

  // ===== Filter / Sort =====
  void _applyFiltersAndSort() {
    final String q = _searchController.text.trim().toLowerCase();

    final filtered =
        _places.where((p) {
          if (_activeCategory != 'All' && _activeCategory.isNotEmpty) {
            final cat = (p['category']?.toString() ?? '').toLowerCase();
            if (cat != _activeCategory.toLowerCase()) return false;
          }
          if (q.isEmpty) return true;
          final name = (p['name']?.toString() ?? '').toLowerCase();
          final category = (p['category']?.toString() ?? '').toLowerCase();
          final description =
              (p['description']?.toString() ?? '').toLowerCase();
          final address =
              (p['address']?.toString() ?? p['place_name']?.toString() ?? '')
                  .toLowerCase();
          return name.contains(q) ||
              category.contains(q) ||
              description.contains(q) ||
              address.contains(q);
        }).toList();

    // attach distances
    for (final p in filtered) {
      _attachDistanceIfPossible(p);
    }

    switch (_sort) {
      case SortOption.distance:
        filtered.sort((a, b) {
          final da = (a['distance'] as num?)?.toDouble() ?? double.infinity;
          final db = (b['distance'] as num?)?.toDouble() ?? double.infinity;
          return da.compareTo(db);
        });
        break;
      case SortOption.newest:
        filtered.sort((a, b) {
          final aTime =
              a['createdAt']?.toString() ?? a['created_at']?.toString() ?? '';
          final bTime =
              b['createdAt']?.toString() ?? b['created_at']?.toString() ?? '';
          return bTime.compareTo(aTime);
        });
        break;
      case SortOption.name:
        filtered.sort((a, b) {
          final an = (a['name']?.toString() ?? '');
          final bn = (b['name']?.toString() ?? '');
          return an.compareTo(bn);
        });
        break;
    }

    setState(() {
      _filtered = filtered;
      _resetPagination();
    });
    _loadMore();
  }

  void _resetPagination() {
    _page = 0;
    _visible = [];
  }

  // ===== Pagination =====
  void _loadMore() {
    if (_isLoadingMore) return;
    if (_visible.length >= _filtered.length) return;

    setState(() {
      _isLoadingMore = true;
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      final start = _page * _pageSize;
      final end = start + _pageSize;
      final nextSlice = _filtered.sublist(
        start,
        end > _filtered.length ? _filtered.length : end,
      );
      setState(() {
        _visible.addAll(nextSlice);
        _page += 1;
        _isLoadingMore = false;
      });
    });
  }

  // ===== Refresh =====
  Future<void> _onRefresh() async {
    await _initLocation();
    await _fetchPlaces();
  }

  // ===== Actions =====
  Future<void> _openExternalMap(double? lat, double? lng) async {
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('位置が利用できません')));
      return;
    }
    final google = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    try {
      if (!await launchUrl(google, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('地図アプリを開けませんでした')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('地図を開く時にエラーが発生しました: $e')));
    }
  }

  Future<void> _goToMap(Map<String, dynamic> facility) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_facility', jsonEncode(facility));
    } catch (_) {}

    Navigator.of(
      context,
    ).pushNamed(AppRouter.map, arguments: {'selectedFacility': facility});
  }

  // ===== UI Components =====
  Widget _buildSortMenu() {
    return PopupMenuButton<SortOption>(
      icon: const Icon(Icons.sort),
      onSelected: (opt) {
        setState(() => _sort = opt);
        _applyFiltersAndSort();
      },
      itemBuilder:
          (ctx) => [
            const PopupMenuItem(value: SortOption.distance, child: Text('距離順')),
            const PopupMenuItem(value: SortOption.newest, child: Text('更新日時順')),
            const PopupMenuItem(value: SortOption.name, child: Text('名称順')),
          ],
    );
  }

  String _formatDistance(double? meters) {
    if (meters == null) return '';
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '${meters.round()} m';
  }

  Widget _buildPlaceItem(Map<String, dynamic> p) {
    final String name = p['name']?.toString() ?? '施設名なし';
    final String description = p['description']?.toString() ?? '';
    final String address =
        p['address']?.toString() ?? p['place_name']?.toString() ?? '';
    final String category = p['category']?.toString() ?? '';
    final double? lat = _toDouble(p['latitude']) ?? _toDouble(p['lat']);
    final double? lng = _toDouble(p['longitude']) ?? _toDouble(p['lng']);
    final double? distance = (p['distance'] as num?)?.toDouble();

    return Card(
      child: ListTile(
        leading: const Icon(Icons.location_on, color: Colors.blue),
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (category.isNotEmpty) ...[
              Text(
                category,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            if (address.isNotEmpty) ...[
              Text(address, style: const TextStyle(fontSize: 12)),
            ],
            if (description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [if (distance != null) Text(_formatDistance(distance))],
        ),
        onTap: () => _goToMap(p),
      ),
    );
  }

  Widget _buildFilterBottomSheet(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('種類ごと', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              children:
                  _categories
                      .map(
                        (c) => ChoiceChip(
                          label: Text(c),
                          selected: _activeCategory == c,
                          onSelected: (_) {
                            setState(() => _activeCategory = c);
                            _applyFiltersAndSort();
                            Navigator.of(ctx).pop();
                          },
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() => _activeCategory = 'All');
              _applyFiltersAndSort();
              Navigator.of(ctx).pop();
            },
            child: const Text('クリア'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryScroller() {
    if (_categories.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: _activeCategory == 'All',
              onSelected: (_) {
                setState(() => _activeCategory = 'All');
                _applyFiltersAndSort();
              },
            ),
            const SizedBox(width: 8),
            ..._categories
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _activeCategory == c,
                      onSelected: (_) {
                        setState(() => _activeCategory = c);
                        _applyFiltersAndSort();
                      },
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ばしょ'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : _fetchPlaces,
            ),
            _buildSortMenu(),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed:
                  () => showModalBottomSheet(
                    context: context,
                    builder: _buildFilterBottomSheet,
                  ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: '検索',
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _applyFiltersAndSort();
                              },
                            )
                            : null,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),

              // category chips horizontal
              _buildCategoryScroller(),

              Expanded(
                child:
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _error.isNotEmpty
                        ? Center(child: Text(_error))
                        : RefreshIndicator(
                          onRefresh: _onRefresh,
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (scrollInfo) {
                              if (scrollInfo.metrics.pixels >=
                                  scrollInfo.metrics.maxScrollExtent - 120) {
                                // near bottom -> load more
                                if (!_isLoadingMore) _loadMore();
                              }
                              return false;
                            },
                            child: ListView.separated(
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount:
                                  _visible.length + (_isLoadingMore ? 1 : 0),
                              separatorBuilder:
                                  (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                if (index >= _visible.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                final facility = _visible[index];
                                return _buildPlaceItem(facility);
                              },
                            ),
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
