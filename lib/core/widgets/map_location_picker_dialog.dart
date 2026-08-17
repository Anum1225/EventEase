import 'dart:math' as math;
import 'package:flutter/material.dart';
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

/// Commercial-grade OpenStreetMap & Google Maps Location Picker Dialog
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

  static const List<LocationSuggestion> _allVenues = [
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

    // --- HYDERABAD, SUKKUR & OTHERS ---
    LocationSuggestion(
      name: 'Indus Hotel & Banquets',
      address: 'Thandi Sarak, Hyderabad',
      city: 'Hyderabad',
      province: 'Sindh',
      lat: 25.3960,
      lng: 68.3578,
      category: 'Hotel & Conference',
    ),
    LocationSuggestion(
      name: 'Sukkur IBA Convention Center',
      address: 'Nisar Ahmed Siddiqui Road, Sukkur',
      city: 'Sukkur',
      province: 'Sindh',
      lat: 27.7240,
      lng: 68.8220,
      category: 'Auditorium Complex',
    ),
    LocationSuggestion(
      name: 'Pearl Continental Hotel Muzaffarabad',
      address: 'Upper Chattar, Muzaffarabad AJK',
      city: 'Muzaffarabad',
      province: 'Azad Kashmir',
      lat: 34.3650,
      lng: 73.4720,
      category: 'Resort Ballroom',
    ),
    LocationSuggestion(
      name: 'Serena Hotel Gilgit',
      address: 'Jutial, Gilgit',
      city: 'Gilgit',
      province: 'Gilgit-Baltistan',
      lat: 35.9180,
      lng: 74.3310,
      category: 'Hotel Conference Hall',
    ),
  ];

  late String _selectedVenueName;
  late String _selectedVenueAddress;
  late String _selectedCity;
  late String _selectedProvince;
  late double _currentLat;
  late double _currentLng;
  int _osmZoom = 13;
  String _mapMode = 'osm'; // 'osm' (Street) or 'satellite' (Esri World Imagery)
  List<LocationSuggestion> _searchResults = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialLocation ?? '');

    final matched = _allVenues.firstWhere(
      (v) => (widget.initialLocation != null &&
          (widget.initialLocation!.toLowerCase().contains(v.name.toLowerCase()) ||
              widget.initialLocation!.toLowerCase().contains(v.city.toLowerCase()) ||
              v.name.toLowerCase().contains(widget.initialLocation!.toLowerCase()))),
      orElse: () => _allVenues.first,
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
    _searchController.removeListener(_onSearchQueryChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchQueryChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSuggestions = false;
      });
      return;
    }

    final matches = _allVenues.where((v) {
      return v.name.toLowerCase().contains(query) ||
          v.city.toLowerCase().contains(query) ||
          v.address.toLowerCase().contains(query) ||
          v.province.toLowerCase().contains(query) ||
          v.category.toLowerCase().contains(query);
    }).take(6).toList();

    setState(() {
      _searchResults = matches;
      _showSuggestions = matches.isNotEmpty;
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
      _osmZoom = 14;
    });
    _searchFocusNode.unfocus();
  }

  void _onMapTapped(TapUpDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final relativeOffset = (details.localPosition - center);

    // Slippy Map Mercator coordinates
    final scale = 256.0 * (1 << _osmZoom);
    final dLng = (relativeOffset.dx / scale) * 360.0;
    final dLat = -(relativeOffset.dy / scale) * 180.0;

    final tappedLng = (_currentLng + dLng).clamp(60.0, 78.5);
    final tappedLat = (_currentLat + dLat).clamp(23.0, 37.5);

    // Find nearest registered landmark
    LocationSuggestion closest = _allVenues.first;
    double minDistance = double.infinity;
    for (final v in _allVenues) {
      final d = math.sqrt(math.pow(v.lat - tappedLat, 2) + math.pow(v.lng - tappedLng, 2));
      if (d < minDistance) {
        minDistance = d;
        closest = v;
      }
    }

    setState(() {
      _currentLat = tappedLat;
      _currentLng = tappedLng;
      if (minDistance < 0.05) {
        _selectedVenueName = closest.name;
        _selectedVenueAddress = closest.address;
        _selectedCity = closest.city;
        _selectedProvince = closest.province;
      } else {
        _selectedCity = closest.city;
        _selectedProvince = closest.province;
        _selectedVenueName = 'Selected Location near ${closest.city}';
        _selectedVenueAddress = '${closest.city}, ${closest.province}, Pakistan';
      }
      _searchController.text = _selectedVenueName;
      _showSuggestions = false;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final scale = 256.0 * (1 << _osmZoom);
    final dLng = -(details.delta.dx / scale) * 360.0;
    final dLat = (details.delta.dy / scale) * 180.0;

    setState(() {
      _currentLng = (_currentLng + dLng).clamp(60.0, 78.5);
      _currentLat = (_currentLat + dLat).clamp(23.0, 37.5);
      _showSuggestions = false;
    });
  }

  void _zoomIn() {
    setState(() {
      _osmZoom = (_osmZoom + 1).clamp(5, 18);
    });
  }

  void _zoomOut() {
    setState(() {
      _osmZoom = (_osmZoom - 1).clamp(5, 18);
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
                          'Search a venue or drag the map to position the pin marker',
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

            // Search Bar with Live Suggestions Dropdown
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
                      hintText: 'Search city, venue, or address (e.g. Karachi, Lahore, PC Hotel...)',
                      hintStyle: AppTypography.manrope(fontSize: 12.5, color: secondaryTextColor),
                      prefixIcon: Icon(Icons.search, size: 18, color: accentColor),
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
                  // 1. Live Real OpenStreetMap / Satellite Slippy Tiles
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final mapSize = Size(constraints.maxWidth, constraints.maxHeight);
                      return GestureDetector(
                        onTapUp: (details) => _onMapTapped(details, mapSize),
                        onPanUpdate: _onPanUpdate,
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
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.4),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.place_rounded, size: 12, color: Colors.amber),
                                          const SizedBox(width: 4),
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 180),
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

                  // 2. Autocomplete Suggestions Overlay List
                  if (_showSuggestions && _searchResults.isNotEmpty)
                    Positioned(
                      top: 0,
                      left: 16,
                      right: 16,
                      child: Material(
                        elevation: 12,
                        borderRadius: BorderRadius.circular(12),
                        color: isDark ? const Color(0xFF1E2232) : Colors.white,
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 220),
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
