import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

class LocationSuggestion {
  final String name;
  final String address;
  final String city;
  final String province;
  final double lat;
  final double lng;
  final String category;

  const LocationSuggestion({
    required this.name,
    required this.address,
    required this.city,
    required this.province,
    required this.lat,
    required this.lng,
    required this.category,
  });
}

/// Commercial-grade OpenStreetMap & Google Maps Location Picker Dialog with Real-Time Global Search & Reverse-Geocoding
class MapLocationPickerDialog extends StatefulWidget {
  final String? initialLocation;

  const MapLocationPickerDialog({
    super.key,
    this.initialLocation,
  });

  static Future<String?> show(BuildContext context, {String? initialLocation}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: MapLocationPickerDialog(initialLocation: initialLocation),
      ),
    );
  }

  @override
  State<MapLocationPickerDialog> createState() => _MapLocationPickerDialogState();
}

class _MapLocationPickerDialogState extends State<MapLocationPickerDialog> {
  late TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _searchDebounceTimer;
  Timer? _reverseGeocodeDebounceTimer;
  bool _isSearching = false;
  bool _isReverseGeocoding = false;

  static const List<LocationSuggestion> _localVenues = [
    // --- KARACHI ---
    LocationSuggestion(
      name: 'Karachi Expo Centre',
      address: 'Main University Road, Gulshan-e-Iqbal, Karachi',
      city: 'Karachi',
      province: 'Sindh',
      lat: 24.9089,
      lng: 67.0784,
      category: 'Convention Center',
    ),
    LocationSuggestion(
      name: 'Arts Council of Pakistan',
      address: 'M.R. Kiyani Road, Saddar, Karachi',
      city: 'Karachi',
      province: 'Sindh',
      lat: 24.8560,
      lng: 67.0180,
      category: 'Auditorium & Arts Center',
    ),
    LocationSuggestion(
      name: 'Karachi Marriott Hotel',
      address: '9 Abdullah Haroon Road, Civil Lines, Karachi',
      city: 'Karachi',
      province: 'Sindh',
      lat: 24.8488,
      lng: 67.0272,
      category: 'Hotel Ballroom',
    ),
    LocationSuggestion(
      name: 'Pearl Continental Hotel Karachi',
      address: 'Club Road, Civil Lines, Karachi',
      city: 'Karachi',
      province: 'Sindh',
      lat: 24.8465,
      lng: 67.0245,
      category: '5-Star Hotel',
    ),
    LocationSuggestion(
      name: 'Mövenpick Hotel Karachi',
      address: 'Club Road, Civil Lines, Karachi',
      city: 'Karachi',
      province: 'Sindh',
      lat: 24.8492,
      lng: 67.0298,
      category: 'Banquet Hall',
    ),
    LocationSuggestion(
      name: 'Clifton Beach & Park',
      address: 'Block 4, Clifton, Karachi',
      city: 'Karachi',
      province: 'Sindh',
      lat: 24.8138,
      lng: 67.0305,
      category: 'Open Air Venue',
    ),
    LocationSuggestion(
      name: 'Mehmoodabad Community Hall',
      address: 'Mehmoodabad No. 3, Karachi',
      city: 'Karachi',
      province: 'Sindh',
      lat: 24.8632,
      lng: 67.0705,
      category: 'Community Center',
    ),
    LocationSuggestion(
      name: 'PAF Museum Convention Grounds',
      address: 'Shahrah-e-Faisal, Faisal Cantonment, Karachi',
      city: 'Karachi',
      province: 'Sindh',
      lat: 24.8732,
      lng: 67.0945,
      category: 'Convention Arena',
    ),
    LocationSuggestion(
      name: 'DHA Golf Club & Marquee',
      address: 'Zulfiqar Street 1, Phase 8, DHA, Karachi',
      city: 'Karachi',
      province: 'Sindh',
      lat: 24.7780,
      lng: 67.0580,
      category: 'Luxury Marquee',
    ),

    // --- LAHORE ---
    LocationSuggestion(
      name: 'Lahore Expo Centre',
      address: '1-A Abdul Haque Road, Trade Centre Commercial Area, Phase 2, Johar Town, Lahore',
      city: 'Lahore',
      province: 'Punjab',
      lat: 31.4676,
      lng: 74.2697,
      category: 'Exhibition Centre',
    ),
    LocationSuggestion(
      name: 'Pearl Continental Hotel Lahore',
      address: 'Shahrah-e-Quaid-e-Azam, Mall Road, Lahore',
      city: 'Lahore',
      province: 'Punjab',
      lat: 31.5546,
      lng: 74.3312,
      category: 'Grand Ballroom',
    ),
    LocationSuggestion(
      name: 'Faletti\'s Hotel Lahore',
      address: '24 Egerton Road, Commercial Zone, Lahore',
      city: 'Lahore',
      province: 'Punjab',
      lat: 31.5610,
      lng: 74.3290,
      category: 'Heritage Banquet Hall',
    ),
    LocationSuggestion(
      name: 'Alhamra Arts Council',
      address: '68 Mall Road, G.O.R. - I, Lahore',
      city: 'Lahore',
      province: 'Punjab',
      lat: 31.5582,
      lng: 74.3275,
      category: 'Cultural Complex',
    ),
    LocationSuggestion(
      name: 'Royal Palm Golf & Country Club',
      address: '52 Canal Bank Road, Lahore',
      city: 'Lahore',
      province: 'Punjab',
      lat: 31.5562,
      lng: 74.3820,
      category: 'Country Club Marquee',
    ),

    // --- ISLAMABAD & RAWALPINDI ---
    LocationSuggestion(
      name: 'Jinnah Convention Centre',
      address: 'Srinagar Highway, Club Road, Islamabad',
      city: 'Islamabad',
      province: 'Islamabad Capital',
      lat: 33.7085,
      lng: 73.1118,
      category: 'National Convention Centre',
    ),
    LocationSuggestion(
      name: 'Serena Hotel Islamabad',
      address: 'Khayaban-e-Suhrwardy, Sector G-5/1, Islamabad',
      city: 'Islamabad',
      province: 'Islamabad Capital',
      lat: 33.7145,
      lng: 73.1022,
      category: '5-Star Luxury Banquet',
    ),
    LocationSuggestion(
      name: 'Islamabad Marriott Hotel',
      address: 'Aga Khan Road, Sector F-5/1, Islamabad',
      city: 'Islamabad',
      province: 'Islamabad Capital',
      lat: 33.7292,
      lng: 73.0880,
      category: 'Grand Ballroom',
    ),
    LocationSuggestion(
      name: 'Faisal Mosque Grounds',
      address: 'Shah Faisal Avenue, Sector E-7, Islamabad',
      city: 'Islamabad',
      province: 'Islamabad Capital',
      lat: 33.7298,
      lng: 73.0372,
      category: 'Landmark Venue',
    ),
    LocationSuggestion(
      name: 'Pearl Continental Hotel Rawalpindi',
      address: 'The Mall, Rawalpindi Cantonment',
      city: 'Rawalpindi',
      province: 'Punjab',
      lat: 33.5930,
      lng: 73.0560,
      category: 'Grand Banquet',
    ),
    LocationSuggestion(
      name: 'Ayub National Park & Marquees',
      address: 'Jhelum Road, Rawalpindi',
      city: 'Rawalpindi',
      province: 'Punjab',
      lat: 33.5680,
      lng: 73.0850,
      category: 'Event Complex',
    ),

    // --- PESHAWAR ---
    LocationSuggestion(
      name: 'Pearl Continental Hotel Peshawar',
      address: 'Khyber Road, Peshawar Cantonment',
      city: 'Peshawar',
      province: 'Khyber Pakhtunkhwa',
      lat: 34.0086,
      lng: 71.5540,
      category: 'Convention Hall',
    ),
    LocationSuggestion(
      name: 'Nishtar Hall',
      address: 'Cinema Road, Peshawar',
      city: 'Peshawar',
      province: 'Khyber Pakhtunkhwa',
      lat: 34.0150,
      lng: 71.5720,
      category: 'Cultural Center',
    ),

    // --- QUETTA ---
    LocationSuggestion(
      name: 'Serena Hotel Quetta',
      address: 'Shahrah-e-Zarghoon, Quetta Cantonment',
      city: 'Quetta',
      province: 'Balochistan',
      lat: 30.1980,
      lng: 67.0120,
      category: 'Grand Ballroom',
    ),

    // --- MULTAN & FAISALABAD ---
    LocationSuggestion(
      name: 'Multan Arts Council & Auditoriums',
      address: 'Old Bahawalpur Road, Multan',
      city: 'Multan',
      province: 'Punjab',
      lat: 30.1970,
      lng: 71.4680,
      category: 'Auditorium',
    ),
    LocationSuggestion(
      name: 'Faisalabad Serena Hotel',
      address: 'Club Road, Civil Lines, Faisalabad',
      city: 'Faisalabad',
      province: 'Punjab',
      lat: 31.4230,
      lng: 73.0890,
      category: 'Luxury Banquet',
    ),
  ];

  late String _selectedVenueName;
  late String _selectedVenueAddress;
  late String _selectedCity;
  late String _selectedProvince;
  late double _currentLat;
  late double _currentLng;
  int _osmZoom = 14;
  String _mapMode = 'osm'; // 'osm' (Street) or 'satellite' (Esri World Imagery)
  List<LocationSuggestion> _searchResults = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialLocation ?? '');

    final matched = _localVenues.firstWhere(
      (v) => (widget.initialLocation != null &&
          (widget.initialLocation!.toLowerCase().contains(v.name.toLowerCase()) ||
              widget.initialLocation!.toLowerCase().contains(v.city.toLowerCase()) ||
              v.name.toLowerCase().contains(widget.initialLocation!.toLowerCase()))),
      orElse: () => _localVenues.first,
    );

    _selectedVenueName = widget.initialLocation?.isNotEmpty == true
        ? widget.initialLocation!
        : matched.name;
    _selectedVenueAddress = matched.address;
    _selectedCity = matched.city;
    _selectedProvince = matched.province;
    _currentLat = matched.lat;
    _currentLng = matched.lng;

    _searchController.addListener(_onSearchQueryChanged);
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _reverseGeocodeDebounceTimer?.cancel();
    _searchController.removeListener(_onSearchQueryChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Live Global Search Engine: combines instant local matching with live OpenStreetMap Nominatim geocoding
  void _onSearchQueryChanged() {
    final query = _searchController.text.trim();
    _searchDebounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSuggestions = false;
        _isSearching = false;
      });
      return;
    }

    // 1. Immediate instant local suggestions
    final qLower = query.toLowerCase();
    final localMatches = _localVenues.where((v) {
      return v.name.toLowerCase().contains(qLower) ||
          v.city.toLowerCase().contains(qLower) ||
          v.address.toLowerCase().contains(qLower) ||
          v.province.toLowerCase().contains(qLower) ||
          v.category.toLowerCase().contains(qLower);
    }).take(4).toList();

    setState(() {
      _searchResults = localMatches;
      _showSuggestions = localMatches.isNotEmpty;
      _isSearching = true;
    });

    // 2. Fetch live global OpenStreetMap Nominatim search results with debounce
    _searchDebounceTimer = Timer(const Duration(milliseconds: 320), () async {
      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=8'
        );
        final response = await http.get(url, headers: {
          'User-Agent': 'EventEase-Pakistan-App/2.0',
          'Accept': 'application/json',
        }).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200 && mounted) {
          final List<dynamic> data = jsonDecode(response.body);
          final remoteResults = <LocationSuggestion>[];

          for (final item in data) {
            final lat = double.tryParse(item['lat']?.toString() ?? '') ?? 0.0;
            final lon = double.tryParse(item['lon']?.toString() ?? '') ?? 0.0;
            if (lat == 0.0 && lon == 0.0) continue;

            final displayName = item['display_name']?.toString() ?? '';
            final parts = displayName.split(',');
            final name = parts.isNotEmpty ? parts[0].trim() : query;
            final address = parts.length > 1 ? parts.sublist(1).take(3).join(',').trim() : displayName;
            final addr = item['address'] as Map<String, dynamic>?;
            final city = addr?['city'] ?? addr?['town'] ?? addr?['suburb'] ?? addr?['county'] ?? (parts.length > 1 ? parts[1].trim() : 'Pakistan');
            final state = addr?['state'] ?? addr?['country'] ?? 'Pakistan';

            remoteResults.add(LocationSuggestion(
              name: name,
              address: address.isNotEmpty ? address : name,
              city: city.toString(),
              province: state.toString(),
              lat: lat,
              lng: lon,
              category: item['type']?.toString() ?? 'Location',
            ));
          }

          if (mounted && _searchController.text.trim() == query) {
            final combined = <LocationSuggestion>[...localMatches];
            for (final r in remoteResults) {
              if (!combined.any((c) => (c.lat - r.lat).abs() < 0.001 && (c.lng - r.lng).abs() < 0.001)) {
                combined.add(r);
              }
            }
            setState(() {
              _searchResults = combined.take(8).toList();
              _showSuggestions = _searchResults.isNotEmpty;
              _isSearching = false;
            });
          }
        }
      } catch (e) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  void _selectLocation(LocationSuggestion venue) {
    setState(() {
      _selectedVenueName = venue.name;
      _selectedVenueAddress = venue.address;
      _selectedCity = venue.city;
      _selectedProvince = venue.province;
      _currentLat = venue.lat;
      _currentLng = venue.lng;
      _searchController.text = venue.name;
      _showSuggestions = false;
      _osmZoom = 15;
    });
    _searchFocusNode.unfocus();
  }

  /// Live Reverse Geocoding: resolves exact area, road, suburb, and city coordinates just like Google Maps
  void _triggerReverseGeocode(double lat, double lng) {
    _reverseGeocodeDebounceTimer?.cancel();
    _reverseGeocodeDebounceTimer = Timer(const Duration(milliseconds: 280), () async {
      setState(() => _isReverseGeocoding = true);
      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&addressdetails=1&zoom=18'
        );
        final response = await http.get(url, headers: {
          'User-Agent': 'EventEase-Pakistan-App/2.0',
          'Accept': 'application/json',
        }).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200 && mounted) {
          final data = jsonDecode(response.body);
          final displayName = data['display_name']?.toString() ?? '';
          final addr = data['address'] as Map<String, dynamic>?;

          final road = addr?['road'] ?? addr?['street'];
          final suburb = addr?['suburb'] ?? addr?['neighbourhood'] ?? addr?['quarter'] ?? addr?['residential'];
          final city = addr?['city'] ?? addr?['town'] ?? addr?['village'] ?? addr?['county'] ?? 'Pakistan';
          final state = addr?['state'] ?? addr?['province'] ?? 'Pakistan';

          String name = '';
          if (road != null && suburb != null) {
            name = '$road, $suburb';
          } else if (suburb != null) {
            name = '$suburb, $city';
          } else if (road != null) {
            name = '$road, $city';
          } else if (displayName.isNotEmpty) {
            name = displayName.split(',').take(2).join(',').trim();
          } else {
            name = '$city Area';
          }

          final fullAddress = displayName.isNotEmpty
              ? displayName.split(',').take(4).join(',').trim()
              : '$name, $city, $state';

          setState(() {
            _selectedVenueName = name;
            _selectedVenueAddress = fullAddress;
            _selectedCity = city.toString();
            _selectedProvince = state.toString();
            _isReverseGeocoding = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isReverseGeocoding = false);
      }
    });
  }

  void _onMapTapped(TapUpDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final relativeOffset = (details.localPosition - center);

    final scale = 256.0 * (1 << _osmZoom);
    final dLng = (relativeOffset.dx / scale) * 360.0;
    final dLat = -(relativeOffset.dy / scale) * 180.0;

    final tappedLng = (_currentLng + dLng).clamp(-180.0, 180.0);
    final tappedLat = (_currentLat + dLat).clamp(-85.0, 85.0);

    setState(() {
      _currentLat = tappedLat;
      _currentLng = tappedLng;
      _showSuggestions = false;
    });

    _triggerReverseGeocode(tappedLat, tappedLng);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final scale = 256.0 * (1 << _osmZoom);
    final dLng = -(details.delta.dx / scale) * 360.0;
    final dLat = (details.delta.dy / scale) * 180.0;

    setState(() {
      _currentLng = (_currentLng + dLng).clamp(-180.0, 180.0);
      _currentLat = (_currentLat + dLat).clamp(-85.0, 85.0);
      _showSuggestions = false;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _triggerReverseGeocode(_currentLat, _currentLng);
  }

  void _zoomIn() {
    setState(() {
      _osmZoom = (_osmZoom + 1).clamp(4, 19);
    });
  }

  void _zoomOut() {
    setState(() {
      _osmZoom = (_osmZoom - 1).clamp(4, 19);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accentColor = isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent;

    return Container(
      constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141722) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
            blurRadius: 32,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1E2B) : const Color(0xFFF8F7F2),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.map_rounded, color: accentColor, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pick Venue Location',
                          style: AppTypography.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                        ),
                        Text(
                          'Search any place worldwide or drag the map to locate the venue',
                          style: AppTypography.manrope(
                            fontSize: 11.5,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Search Bar with Live Global Autocomplete Suggestions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark ? const Color(0xFF161924) : Colors.white,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: AppTypography.manrope(fontSize: 13.5, color: primaryTextColor),
                    decoration: InputDecoration(
                      hintText: 'Search any city, street, or landmark (e.g. Karachi, Lahore, G-11 Islamabad...)',
                      hintStyle: AppTypography.manrope(fontSize: 12.5, color: secondaryTextColor),
                      prefixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : Icon(Icons.search, size: 18, color: accentColor),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                  _showSuggestions = false;
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E2232) : const Color(0xFFF3F1EA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Map Viewport with Suggestions Overlay
            Expanded(
              child: Stack(
                children: [
                  // 1. Live Slippy Map Tiles (OpenStreetMap Street or Esri Satellite)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final mapSize = Size(constraints.maxWidth, constraints.maxHeight);
                      return GestureDetector(
                        onTapUp: (details) => _onMapTapped(details, mapSize),
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: ClipRect(
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: _LiveMapTileRenderer(
                                  lat: _currentLat,
                                  lng: _currentLng,
                                  zoom: _osmZoom,
                                  isSatellite: _mapMode == 'satellite',
                                  isDark: isDark,
                                ),
                              ),

                              // Center Pin Target Marker
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Location Tooltip Callout
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_isReverseGeocoding)
                                            const Padding(
                                              padding: EdgeInsets.only(right: 6),
                                              child: SizedBox(
                                                width: 10,
                                                height: 10,
                                                child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.amber),
                                              ),
                                            )
                                          else
                                            const Icon(Icons.place_rounded, size: 13, color: Colors.amber),
                                          const SizedBox(width: 4),
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 220),
                                            child: Text(
                                              _selectedVenueName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    // Red Location Pin
                                    const Icon(
                                      Icons.location_pin,
                                      size: 38,
                                      color: Color(0xFFEF4444),
                                      shadows: [
                                        Shadow(
                                          color: Colors.black54,
                                          blurRadius: 8,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Map Layer Switcher (Street / Satellite)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: (isDark ? const Color(0xFF1A1E2B) : Colors.white).withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildModePill('osm', '🗺️ Street', _mapMode == 'osm', isDark),
                                      _buildModePill('satellite', '🛰️ Satellite', _mapMode == 'satellite', isDark),
                                    ],
                                  ),
                                ),
                              ),

                              // Zoom In / Out Controls
                              Positioned(
                                bottom: 16,
                                right: 12,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildZoomBtn(Icons.add, _zoomIn, isDark),
                                    const SizedBox(height: 6),
                                    _buildZoomBtn(Icons.remove, _zoomOut, isDark),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // 2. Live Global Autocomplete Suggestions Overlay
                  if (_showSuggestions && _searchResults.isNotEmpty)
                    Positioned(
                      top: 0,
                      left: 16,
                      right: 16,
                      child: Material(
                        elevation: 14,
                        borderRadius: BorderRadius.circular(12),
                        color: isDark ? const Color(0xFF1E2232) : Colors.white,
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 240),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                            ),
                          ),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            separatorBuilder: (ctx, i) => Divider(
                              height: 1,
                              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                            ),
                            itemBuilder: (context, index) {
                              final item = _searchResults[index];
                              return ListTile(
                                dense: true,
                                leading: Icon(Icons.location_on_outlined, size: 18, color: accentColor),
                                title: Text(
                                  item.name,
                                  style: AppTypography.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: primaryTextColor,
                                  ),
                                ),
                                subtitle: Text(
                                  '${item.city}, ${item.province}',
                                  style: AppTypography.manrope(
                                    fontSize: 11,
                                    color: secondaryTextColor,
                                  ),
                                ),
                                onTap: () => _selectLocation(item),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Location Confirmation Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1E2B) : const Color(0xFFF9F8F4),
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedVenueName,
                              style: AppTypography.manrope(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: primaryTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$_selectedVenueAddress • $_selectedProvince (${_currentLat.toStringAsFixed(4)}° N, ${_currentLng.toStringAsFixed(4)}° E)',
                              style: AppTypography.manrope(fontSize: 11, color: secondaryTextColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: AppButton(
                          text: 'Confirm Location',
                          icon: Icons.check,
                          onPressed: () {
                            final chosenLocation = '$_selectedVenueName, $_selectedCity';
                            Navigator.pop(context, chosenLocation);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModePill(String key, String label, bool isSelected, bool isDark) {
    return InkWell(
      onTap: () => setState(() => _mapMode = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomBtn(IconData icon, VoidCallback onTap, bool isDark) {
    return Material(
      color: isDark ? const Color(0xFF1E2232) : Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: isDark ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}

/// Dynamic live slippy map tile grid renderer
class _LiveMapTileRenderer extends StatelessWidget {
  final double lat;
  final double lng;
  final int zoom;
  final bool isSatellite;
  final bool isDark;

  const _LiveMapTileRenderer({
    required this.lat,
    required this.lng,
    required this.zoom,
    required this.isSatellite,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final centerTileX = _lon2tileX(lng, zoom);
        final centerTileY = _lat2tileY(lat, zoom);

        final centerTilePixelX = _lon2tilePixelX(lng, zoom);
        final centerTilePixelY = _lat2tilePixelY(lat, zoom);

        final offsetX = (width / 2) - centerTilePixelX;
        final offsetY = (height / 2) - centerTilePixelY;

        final tiles = <Widget>[];
        for (int dx = -2; dx <= 2; dx++) {
          for (int dy = -2; dy <= 2; dy++) {
            final tx = centerTileX + dx;
            final ty = centerTileY + dy;
            if (tx < 0 || ty < 0) continue;

            final tileLeft = offsetX + (dx * 256.0);
            final tileTop = offsetY + (dy * 256.0);

            final sub = ['a', 'b', 'c'][(tx + ty).abs() % 3];
            final tileUrl = isSatellite
                ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/$zoom/$ty/$tx'
                : 'https://$sub.tile.openstreetmap.org/$zoom/$tx/$ty.png';

            tiles.add(
              Positioned(
                left: tileLeft,
                top: tileTop,
                width: 256,
                height: 256,
                child: Image.network(
                  tileUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    color: isDark ? const Color(0xFF1A1D27) : const Color(0xFFE5E0D8),
                    child: Center(
                      child: Icon(
                        Icons.map_outlined,
                        size: 20,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
        }

        return Stack(children: tiles);
      },
    );
  }

  static int _lon2tileX(double lon, int z) {
    return ((lon + 180.0) / 360.0 * (1 << z)).floor();
  }

  static int _lat2tileY(double lat, int z) {
    final latRad = lat * math.pi / 180.0;
    return ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * (1 << z)).floor();
  }

  static double _lon2tilePixelX(double lon, int z) {
    final exactX = (lon + 180.0) / 360.0 * (1 << z);
    return (exactX - exactX.floor()) * 256.0;
  }

  static double _lat2tilePixelY(double lat, int z) {
    final latRad = lat * math.pi / 180.0;
    final exactY = ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * (1 << z));
    return (exactY - exactY.floor()) * 256.0;
  }
}
