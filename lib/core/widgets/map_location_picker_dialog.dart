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

/// Comprehensive interactive Google Maps Pakistan Location Picker popup
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        child: MapLocationPickerDialog(initialLocation: initialLocation),
      ),
    );
  }

  @override
  State<MapLocationPickerDialog> createState() => _MapLocationPickerDialogState();
}

class _MapLocationPickerDialogState extends State<MapLocationPickerDialog>
    with SingleTickerProviderStateMixin {
  late TextEditingController _searchController;
  late AnimationController _pulseController;

  // Complete nationwide Pakistan venues, cities, halls and event centers
  static const List<LocationSuggestion> _allPakistanVenues = [
    // --- KARACHI & SINDH ---
    LocationSuggestion(
      name: 'Karachi Expo Centre',
      address: 'Main University Rd, Gulshan-e-Iqbal, Karachi',
      city: 'Karachi',
      province: 'Sindh',
      lat: 24.9089,
      lng: 67.0784,
      category: 'Convention Center',
    ),
    LocationSuggestion(
      name: 'Karachi Marriott Hotel',
      address: '9 Abdullah Haroon Rd, Civil Lines, Karachi',
      city: 'Karachi',
      province: 'Sindh',
      lat: 24.8488,
      lng: 67.0272,
      category: 'Grand Ballroom',
    ),
    LocationSuggestion(
      name: 'Pearl Continental Hotel Karachi',
      address: 'Club Road, Civil Lines, Karachi',
      city: 'Karachi',
      province: 'Sindh',
      lat: 24.8465,
      lng: 67.0245,
      category: '5-Star Hotel Hall',
    ),
    LocationSuggestion(
      name: 'Mövenpick Hotel Karachi',
      address: 'Club Road, Civil Lines, Karachi',
      city: 'Karachi',
      province: 'Sindh',
      lat: 24.8492,
      lng: 67.0298,
      category: 'Exhibition & Banquet',
    ),
    LocationSuggestion(
      name: 'Arts Council of Pakistan Karachi',
      address: 'M.R. Kiyani Road, Saddar, Karachi',
      city: 'Karachi',
      province: 'Sindh',
      lat: 24.8569,
      lng: 67.0223,
      category: 'Auditorium & Theater',
    ),
    LocationSuggestion(
      name: 'PAF Museum Convention Hall',
      address: 'Shahrah-e-Faisal, Karsaz, Karachi',
      city: 'Karachi',
      province: 'Sindh',
      lat: 24.8872,
      lng: 67.0989,
      category: 'Convention Hall',
    ),
    LocationSuggestion(
      name: 'Beach Luxury Hotel',
      address: 'Moulvi Tamizuddin Khan Rd, Lalazar, Karachi',
      city: 'Karachi',
      province: 'Sindh',
      lat: 24.8402,
      lng: 67.0011,
      category: 'Waterfront Pavilion',
    ),
    LocationSuggestion(
      name: 'IBA Karachi Main Campus Hall',
      address: 'University Road, Karachi University Enclave, Karachi',
      city: 'Karachi',
      province: 'Sindh',
      lat: 24.9422,
      lng: 67.1139,
      category: 'Academic Auditorium',
    ),
    LocationSuggestion(
      name: 'Clifton Beach Arena',
      address: 'Sea View Road, Clifton Block 4, Karachi',
      city: 'Karachi',
      province: 'Sindh',
      lat: 24.8012,
      lng: 67.0305,
      category: 'Outdoor Festival Arena',
    ),
    LocationSuggestion(
      name: 'Port Grand Event Village',
      address: 'Opposite PNSC Building, M.T. Khan Road, Karachi',
      city: 'Karachi',
      province: 'Sindh',
      lat: 24.8385,
      lng: 66.9942,
      category: 'Waterfront Event Space',
    ),
    LocationSuggestion(
      name: 'Hyderabad Club Hall',
      address: 'Club Road, Cantt, Hyderabad',
      city: 'Hyderabad',
      province: 'Sindh',
      lat: 25.3960,
      lng: 68.3578,
      category: 'Banquet & Lawn',
    ),
    LocationSuggestion(
      name: 'Sukkur IBA Convention Center',
      address: 'Airport Road, Sukkur',
      city: 'Sukkur',
      province: 'Sindh',
      lat: 27.7244,
      lng: 68.8228,
      category: 'Convention Center',
    ),
    LocationSuggestion(
      name: 'Larkana Arts Council Hall',
      address: 'Station Road, Larkana',
      city: 'Larkana',
      province: 'Sindh',
      lat: 27.5590,
      lng: 68.2120,
      category: 'Auditorium',
    ),

    // --- LAHORE & PUNJAB ---
    LocationSuggestion(
      name: 'Expo Centre Lahore',
      address: '1A Abdul Haque Rd, Trade Centre Commercial Area, Johar Town, Lahore',
      city: 'Lahore',
      province: 'Punjab',
      lat: 31.4682,
      lng: 74.2694,
      category: 'Mega Exhibition Ground',
    ),
    LocationSuggestion(
      name: 'Pearl Continental Hotel Lahore',
      address: 'Shahrah-e-Quaid-e-Azam, Mall Road, Lahore',
      city: 'Lahore',
      province: 'Punjab',
      lat: 31.5546,
      lng: 74.3312,
      category: '5-Star Ballroom',
    ),
    LocationSuggestion(
      name: 'Faletti\'s Hotel Lahore',
      address: '24 Egerton Rd, Garhi Shahu, Lahore',
      city: 'Lahore',
      province: 'Punjab',
      lat: 31.5615,
      lng: 74.3275,
      category: 'Heritage Banquet Hall',
    ),
    LocationSuggestion(
      name: 'Royal Palm Golf & Country Club',
      address: '52 Canal Bank Road, Lahore',
      city: 'Lahore',
      province: 'Punjab',
      lat: 31.5645,
      lng: 74.3752,
      category: 'Luxury Marquee & Golf Lawn',
    ),
    LocationSuggestion(
      name: 'Nishat Hotel Grand Hall',
      address: 'Abdul Haque Rd, Commercial Area Phase 2 Johar Town, Lahore',
      city: 'Lahore',
      province: 'Punjab',
      lat: 31.4690,
      lng: 74.2680,
      category: 'Grand Banquet',
    ),
    LocationSuggestion(
      name: 'Alhamra Arts Council Lahore',
      address: '68 Shahrah-e-Quaid-e-Azam, Mall Road, Lahore',
      city: 'Lahore',
      province: 'Punjab',
      lat: 31.5580,
      lng: 74.3250,
      category: 'Cultural Center & Theater',
    ),
    LocationSuggestion(
      name: 'LUMS Executive Center',
      address: 'DHA Phase 5, Cantt, Lahore',
      city: 'Lahore',
      province: 'Punjab',
      lat: 31.4704,
      lng: 74.4111,
      category: 'Executive Conference Hall',
    ),
    LocationSuggestion(
      name: 'Garrison Golf & Country Club',
      address: 'Saddar, Cantt, Lahore',
      city: 'Lahore',
      province: 'Punjab',
      lat: 31.5200,
      lng: 74.3850,
      category: 'Grand Lawn & Marquee',
    ),
    LocationSuggestion(
      name: 'Serena Hotel Faisalabad',
      address: 'Club Road, Civil Lines, Faisalabad',
      city: 'Faisalabad',
      province: 'Punjab',
      lat: 31.4180,
      lng: 73.0790,
      category: 'Luxury Ballroom',
    ),
    LocationSuggestion(
      name: 'Faisalabad Arts Council',
      address: 'Club Road, Faisalabad',
      city: 'Faisalabad',
      province: 'Punjab',
      lat: 31.4210,
      lng: 73.0820,
      category: 'Auditorium',
    ),
    LocationSuggestion(
      name: 'Ramada by Wyndham Multan',
      address: '76 Abdali Road, Multan Cantt',
      city: 'Multan',
      province: 'Punjab',
      lat: 30.1984,
      lng: 71.4687,
      category: 'Convention & Banquet Hall',
    ),
    LocationSuggestion(
      name: 'Multan Arts Council Complex',
      address: 'MDA Complex, Multan',
      city: 'Multan',
      province: 'Punjab',
      lat: 30.1920,
      lng: 71.4650,
      category: 'Auditorium',
    ),
    LocationSuggestion(
      name: 'Sialkot Garrison Banquet Complex',
      address: 'Tariq Road, Sialkot Cantt',
      city: 'Sialkot',
      province: 'Punjab',
      lat: 32.5030,
      lng: 74.5380,
      category: 'Convention Hall',
    ),
    LocationSuggestion(
      name: 'Gujranwala Chamber of Commerce Hall',
      address: 'Trust Plaza, G.T. Road, Gujranwala',
      city: 'Gujranwala',
      province: 'Punjab',
      lat: 32.1600,
      lng: 74.1850,
      category: 'Business Center',
    ),

    // --- ISLAMABAD & RAWALPINDI ---
    LocationSuggestion(
      name: 'Jinnah Convention Centre',
      address: 'Club Road, Murree Road Interchange, Islamabad',
      city: 'Islamabad',
      province: 'Islamabad Capital',
      lat: 33.7088,
      lng: 73.1097,
      category: 'National Convention Centre',
    ),
    LocationSuggestion(
      name: 'Serena Hotel Islamabad',
      address: 'Khayaban-e-Suhrawardy, Sector G-5/1, Islamabad',
      city: 'Islamabad',
      province: 'Islamabad Capital',
      lat: 33.7202,
      lng: 73.0984,
      category: 'Luxury Ballroom & Gardens',
    ),
    LocationSuggestion(
      name: 'Islamabad Marriott Hotel',
      address: 'Aga Khan Road, Sector F-5/1, Islamabad',
      city: 'Islamabad',
      province: 'Islamabad Capital',
      lat: 33.7310,
      lng: 73.0840,
      category: '5-Star Banquet Hall',
    ),
    LocationSuggestion(
      name: 'Pak-China Friendship Centre',
      address: 'Garden Avenue, Shakarparian, Islamabad',
      city: 'Islamabad',
      province: 'Islamabad Capital',
      lat: 33.6960,
      lng: 73.0870,
      category: 'International Exhibition Arena',
    ),
    LocationSuggestion(
      name: 'Lok Virsa Heritage Hall',
      address: 'Garden Avenue, Shakarparian Hills, Islamabad',
      city: 'Islamabad',
      province: 'Islamabad Capital',
      lat: 33.6920,
      lng: 73.0760,
      category: 'Cultural Amphitheater',
    ),
    LocationSuggestion(
      name: 'FAST-NUCES Auditorium',
      address: 'A.K. Brohi Road, Sector H-11/4, Islamabad',
      city: 'Islamabad',
      province: 'Islamabad Capital',
      lat: 33.6555,
      lng: 73.0153,
      category: 'Tech Campus Hall',
    ),
    LocationSuggestion(
      name: 'NUST Jinnah Auditorium',
      address: 'Sector H-12, Kashmir Highway, Islamabad',
      city: 'Islamabad',
      province: 'Islamabad Capital',
      lat: 33.6420,
      lng: 72.9900,
      category: 'Auditorium Complex',
    ),
    LocationSuggestion(
      name: 'Islamabad Club Grand Marquee',
      address: 'Murree Road, Rawal Dam Promenade, Islamabad',
      city: 'Islamabad',
      province: 'Islamabad Capital',
      lat: 33.7020,
      lng: 73.1180,
      category: 'Private Club Ballroom',
    ),
    LocationSuggestion(
      name: 'Pearl Continental Hotel Rawalpindi',
      address: 'The Mall Road, Rawalpindi Cantt',
      city: 'Rawalpindi',
      province: 'Punjab',
      lat: 33.5955,
      lng: 73.0543,
      category: 'Banquet & Ballroom',
    ),
    LocationSuggestion(
      name: 'Rawalpindi Arts Council',
      address: 'Stadium Road, Shamsabad, Rawalpindi',
      city: 'Rawalpindi',
      province: 'Punjab',
      lat: 33.6470,
      lng: 73.0780,
      category: 'Theater & Exhibition Hall',
    ),
    LocationSuggestion(
      name: 'Arena Marquee Bahria Town',
      address: 'Phase 4, Bahria Town, Rawalpindi',
      city: 'Rawalpindi',
      province: 'Punjab',
      lat: 33.5350,
      lng: 73.1020,
      category: 'Grand Marquee',
    ),

    // --- PESHAWAR & KHYBER PAKHTUNKHWA ---
    LocationSuggestion(
      name: 'Pearl Continental Hotel Peshawar',
      address: 'Khyber Road, Peshawar Cantt',
      city: 'Peshawar',
      province: 'Khyber Pakhtunkhwa',
      lat: 34.0150,
      lng: 71.5580,
      category: 'Luxury Ballroom',
    ),
    LocationSuggestion(
      name: 'Nishtar Hall Peshawar',
      address: 'Museum Road, Peshawar Cantt',
      city: 'Peshawar',
      province: 'Khyber Pakhtunkhwa',
      lat: 34.0080,
      lng: 71.5520,
      category: 'Auditorium & Arts Center',
    ),
    LocationSuggestion(
      name: 'Shiraz Arena Banquet',
      address: 'University Road, Peshawar',
      city: 'Peshawar',
      province: 'Khyber Pakhtunkhwa',
      lat: 33.9980,
      lng: 71.4920,
      category: 'Grand Banquet',
    ),
    LocationSuggestion(
      name: 'Abbottabad Club Hall',
      address: 'The Mall, Abbottabad Cantt',
      city: 'Abbottabad',
      province: 'Khyber Pakhtunkhwa',
      lat: 34.1500,
      lng: 73.2200,
      category: 'Banquet Hall',
    ),
    LocationSuggestion(
      name: 'Swat Serena Hotel Lawn',
      address: 'Saidu Sharif, Swat Valley',
      city: 'Mingora / Swat',
      province: 'Khyber Pakhtunkhwa',
      lat: 35.7500,
      lng: 72.3600,
      category: 'Resort Pavilion',
    ),

    // --- QUETTA & BALOCHISTAN ---
    LocationSuggestion(
      name: 'Serena Hotel Quetta',
      address: 'Shahrah-e-Zarghoon, Quetta Cantt',
      city: 'Quetta',
      province: 'Balochistan',
      lat: 30.1980,
      lng: 67.0180,
      category: '5-Star Ballroom & Lawn',
    ),
    LocationSuggestion(
      name: 'Quetta Club Auditorium',
      address: 'Club Road, Cantt, Quetta',
      city: 'Quetta',
      province: 'Balochistan',
      lat: 30.2050,
      lng: 67.0250,
      category: 'Banquet & Meeting Hall',
    ),
    LocationSuggestion(
      name: 'Gwadar Business Center Pavilion',
      address: 'Main Airport Road, Gwadar Free Zone',
      city: 'Gwadar',
      province: 'Balochistan',
      lat: 25.1260,
      lng: 62.3250,
      category: 'International Convention Hall',
    ),

    // --- GILGIT-BALTISTAN & AZAD KASHMIR ---
    LocationSuggestion(
      name: 'Serena Hotel Gilgit Gardens',
      address: 'Sherullah Beg Road, Jutial, Gilgit',
      city: 'Gilgit',
      province: 'Gilgit-Baltistan',
      lat: 35.9180,
      lng: 74.3460,
      category: 'Alpine Event Lawn',
    ),
    LocationSuggestion(
      name: 'Shangrila Resort Auditorium Skardu',
      address: 'Kachura Lake, Skardu, Gilgit-Baltistan',
      city: 'Skardu',
      province: 'Gilgit-Baltistan',
      lat: 35.4250,
      lng: 75.4480,
      category: 'Resort Convention Center',
    ),
    LocationSuggestion(
      name: 'Pearl Continental Hotel Muzaffarabad',
      address: 'Upper Chattar, Muzaffarabad AJK',
      city: 'Muzaffarabad',
      province: 'Azad Kashmir',
      lat: 34.3650,
      lng: 73.4720,
      category: 'Mountain View Ballroom',
    ),
    LocationSuggestion(
      name: 'Mirpur International Convention Hall',
      address: 'Allama Iqbal Road, Sector F-1, Mirpur AJK',
      city: 'Mirpur AJK',
      province: 'Azad Kashmir',
      lat: 33.1480,
      lng: 73.7510,
      category: 'Convention & Exhibition Hall',
    ),
  ];

  static const List<String> _provinces = [
    'All Pakistan',
    'Sindh',
    'Punjab',
    'Islamabad Capital',
    'Khyber Pakhtunkhwa',
    'Balochistan',
    'Gilgit-Baltistan',
    'Azad Kashmir',
  ];

  late String _selectedVenueName;
  late String _selectedVenueAddress;
  late String _selectedCity;
  late String _selectedProvince;
  late double _currentLat;
  late double _currentLng;
  double _zoomLevel = 1.0;
  int _osmZoom = 13;
  String _mapMode = 'osm'; // 'osm', 'hybrid', 'vector'
  Offset _mapOffset = Offset.zero;
  List<LocationSuggestion> _filteredVenues = [];
  String _selectedProvinceFilter = 'All Pakistan';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialLocation ?? '');
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    final matched = _allPakistanVenues.firstWhere(
      (v) => (widget.initialLocation != null &&
          (widget.initialLocation!.toLowerCase().contains(v.name.toLowerCase()) ||
              widget.initialLocation!.toLowerCase().contains(v.city.toLowerCase()) ||
              v.name.toLowerCase().contains(widget.initialLocation!.toLowerCase()))),
      orElse: () => _allPakistanVenues.first,
    );

    _selectedVenueName = widget.initialLocation?.isNotEmpty == true
        ? widget.initialLocation!
        : matched.name;
    _selectedVenueAddress = matched.address;
    _selectedCity = matched.city;
    _selectedProvince = matched.province;
    _currentLat = matched.lat;
    _currentLng = matched.lng;
    _filteredVenues = _allPakistanVenues;

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredVenues = _allPakistanVenues.where((v) {
        final matchesProvince = _selectedProvinceFilter == 'All Pakistan' ||
            v.province.toLowerCase() == _selectedProvinceFilter.toLowerCase();

        if (!matchesProvince) return false;
        if (query.isEmpty) return true;

        return v.name.toLowerCase().contains(query) ||
            v.city.toLowerCase().contains(query) ||
            v.address.toLowerCase().contains(query) ||
            v.province.toLowerCase().contains(query) ||
            v.category.toLowerCase().contains(query);
      }).toList();
    });

    // If query matches a specific city or venue directly, auto-snap pin
    if (query.isNotEmpty) {
      final directMatch = _allPakistanVenues.firstWhere(
        (v) => v.name.toLowerCase().contains(query) || v.city.toLowerCase() == query,
        orElse: () => _filteredVenues.isNotEmpty ? _filteredVenues.first : _allPakistanVenues.first,
      );
      if (directMatch.name.toLowerCase().contains(query) || directMatch.city.toLowerCase() == query) {
        _selectVenue(directMatch, updateSearchText: false);
      }
    }
  }

  void _filterByProvince(String province) {
    setState(() {
      _selectedProvinceFilter = province;
      _onSearchChanged();
      if (_filteredVenues.isNotEmpty) {
        _selectVenue(_filteredVenues.first, updateSearchText: false);
      }
    });
  }

  void _selectVenue(LocationSuggestion venue, {bool updateSearchText = true}) {
    setState(() {
      _selectedVenueName = venue.name;
      _selectedVenueAddress = venue.address;
      _selectedCity = venue.city;
      _selectedProvince = venue.province;
      _currentLat = venue.lat;
      _currentLng = venue.lng;
      if (updateSearchText) {
        _searchController.text = venue.name;
      }
      _mapOffset = _calculateOffsetForCoordinates(venue.lat, venue.lng);
    });
  }

  Offset _calculateOffsetForCoordinates(double lat, double lng) {
    const centerLat = 30.3753;
    const centerLng = 69.3451;
    final dx = -(lng - centerLng) * 28.0;
    final dy = (lat - centerLat) * 32.0;
    return Offset(dx, dy);
  }

  void _onMapTapped(TapUpDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final touchPos = details.localPosition;
    final relativeOffset = (touchPos - center);

    double tappedLat;
    double tappedLng;

    if (_mapMode == 'vector') {
      final vecOffset = (touchPos - center - _mapOffset) / _zoomLevel;
      const centerLat = 30.3753;
      const centerLng = 69.3451;
      tappedLng = centerLng + (vecOffset.dx / 28.0);
      tappedLat = centerLat - (vecOffset.dy / 32.0);
    } else {
      // Real OpenStreetMap Slippy Map Mercator projection
      final scale = 256.0 * (1 << _osmZoom);
      final dLng = (relativeOffset.dx / scale) * 360.0;
      final dLat = -(relativeOffset.dy / scale) * 180.0;
      tappedLng = _currentLng + dLng;
      tappedLat = _currentLat + dLat;
    }

    // Find closest venue in database
    LocationSuggestion closest = _allPakistanVenues.first;
    double minDistance = double.infinity;

    for (final v in _allPakistanVenues) {
      final d = math.sqrt(math.pow(v.lat - tappedLat, 2) + math.pow(v.lng - tappedLng, 2));
      if (d < minDistance) {
        minDistance = d;
        closest = v;
      }
    }

    if (minDistance < 0.6) {
      _selectVenue(closest);
    } else {
      setState(() {
        _currentLat = tappedLat.clamp(23.5, 37.1);
        _currentLng = tappedLng.clamp(60.8, 77.5);
        _selectedCity = closest.city;
        _selectedProvince = closest.province;
        _selectedVenueName = '${closest.city} Landmark Area';
        _selectedVenueAddress = 'Near ${closest.name}, ${closest.city}, ${closest.province}, Pakistan';
        _searchController.text = _selectedVenueName;
        _mapOffset = _calculateOffsetForCoordinates(_currentLat, _currentLng);
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      if (_mapMode == 'vector') {
        _mapOffset += details.delta / _zoomLevel;
      } else {
        final scale = 256.0 * (1 << _osmZoom);
        final dLng = -(details.delta.dx / scale) * 360.0;
        final dLat = (details.delta.dy / scale) * 180.0;
        _currentLng = (_currentLng + dLng).clamp(60.8, 77.5);
        _currentLat = (_currentLat + dLat).clamp(23.5, 37.1);
      }
    });
  }

  void _zoomIn() {
    setState(() {
      _zoomLevel = (_zoomLevel * 1.25).clamp(0.5, 3.0);
      _osmZoom = (_osmZoom + 1).clamp(5, 17);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel / 1.25).clamp(0.5, 3.0);
      _osmZoom = (_osmZoom - 1).clamp(5, 17);
    });
  }

  void _resetToPakistanOverview() {
    setState(() {
      _zoomLevel = 1.0;
      _osmZoom = 6;
      _mapOffset = Offset.zero;
      _selectedProvinceFilter = 'All Pakistan';
      _currentLat = 30.3753;
      _currentLng = 69.3451;
      _selectVenue(_allPakistanVenues.first, updateSearchText: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkSurfaceElevated : Colors.white;

    return Container(
      constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14161E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
            blurRadius: 36,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header with Pakistan Flag Emblem
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B1E2B) : const Color(0xFFF7F6F1),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.map_rounded,
                      size: 20,
                      color: isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Pakistan Nationwide Map & Venue Picker',
                              style: AppTypography.manrope(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: primaryTextColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('🇵🇰', style: TextStyle(fontSize: 15)),
                          ],
                        ),
                        Text(
                          'Click anywhere on Pakistan map or search any city / hall',
                          style: AppTypography.manrope(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Search Bar & Province Filter Chips
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              color: isDark ? const Color(0xFF14161E) : Colors.white,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search city (e.g. Karachi, Lahore, Islamabad), hall, or venue...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E2232) : const Color(0xFFF3EFE6),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Province Tabs
                  SizedBox(
                    height: 30,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _provinces.length,
                      itemBuilder: (context, index) {
                        final p = _provinces[index];
                        final isSelected = p == _selectedProvinceFilter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _filterByProvince(p),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent)
                                    : (isDark ? const Color(0xFF1E2232) : const Color(0xFFEBE7DD)),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  p,
                                  style: AppTypography.manrope(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Interactive Pakistan Map Canvas Viewport
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final mapSize = Size(constraints.maxWidth, constraints.maxHeight);
                  return GestureDetector(
                    onTapUp: (details) => _onMapTapped(details, mapSize),
                    onPanUpdate: _onPanUpdate,
                    child: ClipRect(
                      child: Stack(
                        children: [
                          // 1. Base Layer: Real OpenStreetMap / Satellite Tiles
                          if (_mapMode != 'vector')
                            Positioned.fill(
                              child: _OpenStreetMapTileLayer(
                                lat: _currentLat,
                                lng: _currentLng,
                                zoom: _osmZoom,
                                mapMode: _mapMode,
                                isDark: isDark,
                              ),
                            ),

                          // 2. Vector Painter Layer (when in Vector mode or as overlay)
                          if (_mapMode == 'vector')
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _PakistanMapCanvasPainter(
                                  isDark: isDark,
                                  offset: _mapOffset,
                                  zoom: _zoomLevel,
                                  venues: _allPakistanVenues,
                                  selectedVenueName: _selectedVenueName,
                                  currentLat: _currentLat,
                                  currentLng: _currentLng,
                                ),
                              ),
                            ),

                          // 3. Map Mode Layer Switcher (OpenStreetMap / Satellite / Vector)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: (isDark ? const Color(0xFF1B1E2B) : Colors.white).withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                                  width: 0.8,
                                ),
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
                                  _buildMapModeButton('osm', '🗺️ OSM Street', isDark),
                                  _buildMapModeButton('hybrid', '🛰️ Satellite', isDark),
                                  _buildMapModeButton('vector', '🇵🇰 GIS Vector', isDark),
                                ],
                              ),
                            ),
                          ),

                          // Animated Center Target Pin
                          Center(
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                final pulseVal = _pulseController.value;
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Radar Pulse Ring
                                    Container(
                                      width: 44 + (pulseVal * 36),
                                      height: 44 + (pulseVal * 36),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: (isDark ? AppColors.darkAccent : AppColors.lightOrganizerAccent)
                                            .withValues(alpha: (1.0 - pulseVal) * 0.4),
                                        border: Border.all(
                                          color: (isDark ? AppColors.darkAccent : AppColors.lightOrganizerAccent)
                                              .withValues(alpha: (1.0 - pulseVal) * 0.7),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    // Pin Marker & Name Callout
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF1E2232) : Colors.black87,
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.35),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.location_on_rounded, size: 12, color: Colors.amber),
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
                                        Icon(
                                          Icons.location_pin,
                                          size: 40,
                                          color: isDark ? AppColors.darkAccent : AppColors.lightOrganizerAccent,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withValues(alpha: 0.5),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                          // Pakistan Watermark & Compass
                          Positioned(
                            left: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.black87 : Colors.white).withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🇵🇰', style: TextStyle(fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'PAKISTAN GIS MAP',
                                        style: AppTypography.manrope(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: primaryTextColor,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        'All Provinces & Venues',
                                        style: AppTypography.manrope(
                                          fontSize: 9,
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Map Zoom & Center Controls
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildControlBtn(
                                  icon: Icons.refresh_rounded,
                                  tooltip: 'Reset to Pakistan Overview',
                                  isDark: isDark,
                                  onTap: _resetToPakistanOverview,
                                ),
                                const SizedBox(height: 6),
                                _buildControlBtn(
                                  icon: Icons.add_rounded,
                                  tooltip: 'Zoom In',
                                  isDark: isDark,
                                  onTap: _zoomIn,
                                ),
                                const SizedBox(height: 4),
                                _buildControlBtn(
                                  icon: Icons.remove_rounded,
                                  tooltip: 'Zoom Out',
                                  isDark: isDark,
                                  onTap: _zoomOut,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Live Venue Quick Selection Bar
            Container(
              height: 38,
              color: isDark ? const Color(0xFF1B1E2B) : const Color(0xFFF3EFE6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _filteredVenues.length,
                itemBuilder: (context, index) {
                  final v = _filteredVenues[index];
                  final isSelected = v.name == _selectedVenueName;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _selectVenue(v),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent)
                              : (isDark ? const Color(0xFF242838) : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.place_rounded,
                              size: 13,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? AppColors.darkAccent : AppColors.lightOrganizerAccent),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${v.name} (${v.city})',
                              style: AppTypography.manrope(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer with Selected Location Summary & Confirm Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedVenueName,
                              style: AppTypography.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: primaryTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$_selectedVenueAddress • $_selectedCity, $_selectedProvince',
                              style: AppTypography.manrope(
                                fontSize: 11.5,
                                color: secondaryTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_currentLat.toStringAsFixed(4)}° N, ${_currentLng.toStringAsFixed(4)}° E',
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Cancel',
                          variant: AppButtonVariant.outlined,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: AppButton(
                          text: 'Select This Location',
                          icon: Icons.check_circle_outline_rounded,
                          variant: AppButtonVariant.organizer,
                          onPressed: () {
                            final chosenLocation = _selectedVenueName.isNotEmpty
                                ? '$_selectedVenueName, $_selectedCity'
                                : '$_selectedVenueAddress, $_selectedCity, Pakistan';
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

  Widget _buildControlBtn({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark ? const Color(0xFF1E2232) : Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildMapModeButton(String modeKey, String label, bool isDark) {
    final isSelected = _mapMode == modeKey;
    final accentColor = isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        setState(() {
          _mapMode = modeKey;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.transparent,
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
}

/// Custom painter that renders a vector-styled map of the entire country of Pakistan
class _PakistanMapCanvasPainter extends CustomPainter {
  final bool isDark;
  final Offset offset;
  final double zoom;
  final List<LocationSuggestion> venues;
  final String selectedVenueName;
  final double currentLat;
  final double currentLng;

  _PakistanMapCanvasPainter({
    required this.isDark,
    required this.offset,
    required this.zoom,
    required this.venues,
    required this.selectedVenueName,
    required this.currentLat,
    required this.currentLng,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Ocean / Arabian Sea base color
    final seaColor = isDark ? const Color(0xFF0F1826) : const Color(0xFFCADEEB);
    canvas.drawRect(Offset.zero & size, Paint()..color = seaColor);

    canvas.save();
    canvas.translate(size.width / 2 + offset.dx, size.height / 2 + offset.dy);
    canvas.scale(zoom);

    // 1. Pakistan Mainland Landmass Shape
    final landColor = isDark ? const Color(0xFF161B28) : const Color(0xFFF3EFE3);
    final borderPaint = Paint()
      ..color = isDark ? const Color(0xFF2E3850) : const Color(0xFFD0C8B6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final pakPath = Path();
    // Contour of Pakistan from South Coast (Gwadar/Karachi) up through Balochistan, KP, GB, Kashmir, Punjab, Sindh
    pakPath.moveTo(-220, 180); // Gwadar / Makran coast
    pakPath.lineTo(-120, 190); // Ormara
    pakPath.lineTo(-20, 210);  // Karachi coastline
    pakPath.lineTo(40, 220);   // Indus Delta / Badin / Rann of Kutch
    pakPath.lineTo(90, 160);   // Thar Desert border
    pakPath.lineTo(120, 60);   // Cholistan / Bahawalpur
    pakPath.lineTo(160, -20);  // Lahore / Kasur East border
    pakPath.lineTo(150, -100); // Sialkot / Narowal border
    pakPath.lineTo(120, -160); // Kashmir / Jammu border
    pakPath.lineTo(140, -230); // Skardu / Karakoram / Siachen
    pakPath.lineTo(80, -280);  // Khunjerab Pass / K2 North
    pakPath.lineTo(0, -270);   // Gilgit / Hunza
    pakPath.lineTo(-60, -230); // Chitral / Hindu Kush
    pakPath.lineTo(-120, -150);// Khyber Pass / Torkham
    pakPath.lineTo(-170, -100);// Waziristan
    pakPath.lineTo(-240, -40); // Chaman / Quetta West border
    pakPath.lineTo(-270, 60);  // Taftan / Western Balochistan
    pakPath.lineTo(-260, 150); // Jiwni
    pakPath.close();

    canvas.drawPath(pakPath, Paint()..color = landColor..style = PaintingStyle.fill);
    canvas.drawPath(pakPath, borderPaint);

    // 2. Province Zones & Colors
    // Sindh
    final sindhPath = Path()
      ..moveTo(-30, 210)
      ..lineTo(40, 220)
      ..lineTo(90, 160)
      ..lineTo(40, 110)
      ..lineTo(-30, 110)
      ..close();
    canvas.drawPath(
      sindhPath,
      Paint()..color = (isDark ? const Color(0xFF1E2838) : const Color(0xFFE8E2D2)).withValues(alpha: 0.7),
    );

    // Punjab
    final punjabPath = Path()
      ..moveTo(-30, 110)
      ..lineTo(40, 110)
      ..lineTo(90, 160)
      ..lineTo(120, 60)
      ..lineTo(160, -20)
      ..lineTo(150, -100)
      ..lineTo(60, -110)
      ..lineTo(10, -40)
      ..close();
    canvas.drawPath(
      punjabPath,
      Paint()..color = (isDark ? const Color(0xFF1A2A22) : const Color(0xFFE0EAD8)).withValues(alpha: 0.7),
    );

    // Khyber Pakhtunkhwa
    final kpkPath = Path()
      ..moveTo(60, -110)
      ..lineTo(10, -40)
      ..lineTo(-80, -70)
      ..lineTo(-120, -150)
      ..lineTo(-60, -230)
      ..lineTo(0, -200)
      ..close();
    canvas.drawPath(
      kpkPath,
      Paint()..color = (isDark ? const Color(0xFF262030) : const Color(0xFFE6DCED)).withValues(alpha: 0.7),
    );

    // Balochistan
    final balochPath = Path()
      ..moveTo(-220, 180)
      ..lineTo(-30, 210)
      ..lineTo(-30, 110)
      ..lineTo(10, -40)
      ..lineTo(-80, -70)
      ..lineTo(-170, -100)
      ..lineTo(-240, -40)
      ..lineTo(-270, 60)
      ..close();
    canvas.drawPath(
      balochPath,
      Paint()..color = (isDark ? const Color(0xFF28241D) : const Color(0xFFEFE6D6)).withValues(alpha: 0.7),
    );

    // Gilgit-Baltistan & Azad Kashmir
    final northPath = Path()
      ..moveTo(60, -110)
      ..lineTo(120, -160)
      ..lineTo(140, -230)
      ..lineTo(80, -280)
      ..lineTo(0, -270)
      ..lineTo(-60, -230)
      ..lineTo(0, -200)
      ..close();
    canvas.drawPath(
      northPath,
      Paint()..color = (isDark ? const Color(0xFF182E32) : const Color(0xFFD6EAEB)).withValues(alpha: 0.7),
    );

    // 3. Indus River System (Blue Curves)
    final riverPaint = Paint()
      ..color = isDark ? const Color(0xFF284C72) : const Color(0xFF7AA8CE)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final indusPath = Path()
      ..moveTo(60, -240)
      ..cubicTo(20, -180, 50, -120, 20, -40)
      ..cubicTo(-10, 30, 10, 100, -10, 200);
    canvas.drawPath(indusPath, riverPaint);

    // Punjab Tributaries
    final riverP2 = Paint()
      ..color = isDark ? const Color(0xFF203E5E) : const Color(0xFF90BCD8)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final jhelumPath = Path()
      ..moveTo(100, -150)
      ..cubicTo(70, -100, 40, -60, 20, -40);
    final chenabPath = Path()
      ..moveTo(130, -120)
      ..cubicTo(90, -80, 50, -40, 20, -40);
    final raviPath = Path()
      ..moveTo(150, -60)
      ..cubicTo(100, -40, 60, -10, 10, 30);
    canvas.drawPath(jhelumPath, riverP2);
    canvas.drawPath(chenabPath, riverP2);
    canvas.drawPath(raviPath, riverP2);

    // 4. National Motorway & Highway Network (Golden Arteries)
    final hwyPaint = Paint()
      ..color = isDark ? const Color(0xFF4A4432) : const Color(0xFFE8C88A)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Karachi M-9 -> Sukkur M-5 -> Multan -> Lahore M-2 -> Islamabad M-2 -> Peshawar M-1
    final motorWayPath = Path()
      ..moveTo(-15, 205)  // Karachi
      ..lineTo(0, 175)    // Hyderabad
      ..lineTo(15, 95)    // Sukkur
      ..lineTo(45, 10)    // Multan
      ..lineTo(85, -25)   // Faisalabad
      ..lineTo(140, -45)  // Lahore
      ..lineTo(70, -120)  // Islamabad / Rawalpindi
      ..lineTo(0, -135);  // Peshawar
    canvas.drawPath(motorWayPath, hwyPaint);

    // 5. Province Region Name Labels
    _drawText(canvas, 'BALOCHISTAN', const Offset(-150, 40), 12, isDark ? Colors.white24 : Colors.black26, FontWeight.w800);
    _drawText(canvas, 'PUNJAB', const Offset(80, 0), 12, isDark ? Colors.white24 : Colors.black26, FontWeight.w800);
    _drawText(canvas, 'SINDH', const Offset(15, 160), 12, isDark ? Colors.white24 : Colors.black26, FontWeight.w800);
    _drawText(canvas, 'KHYBER PAKHTUNKHWA', const Offset(-45, -120), 9.5, isDark ? Colors.white24 : Colors.black26, FontWeight.w800);
    _drawText(canvas, 'GILGIT-BALTISTAN', const Offset(45, -240), 9.5, isDark ? Colors.white24 : Colors.black26, FontWeight.w800);
    _drawText(canvas, 'AZAD KASHMIR', const Offset(105, -145), 9, isDark ? Colors.white24 : Colors.black26, FontWeight.w800);
    _drawText(canvas, 'ARABIAN SEA', const Offset(-120, 240), 11, isDark ? const Color(0xFF324E72) : const Color(0xFF6B92B2), FontWeight.w700);

    // 6. Cities and Venues Nodes on Pakistan Map
    final cityDotPaint = Paint()..color = isDark ? Colors.white70 : Colors.black87;
    final capitalDotPaint = Paint()..color = const Color(0xFF10B981);
    final textStyle = TextStyle(
      fontSize: 8.5,
      fontWeight: FontWeight.w700,
      color: isDark ? Colors.white70 : Colors.black87,
    );

    for (final v in venues) {
      // Map Lat/Lng to Canvas offset
      const centerLat = 30.3753;
      const centerLng = 69.3451;
      final dx = (v.lng - centerLng) * 28.0;
      final dy = -(v.lat - centerLat) * 32.0;

      final isCapital = v.city == 'Islamabad';
      final isKarachiOrLahore = v.city == 'Karachi' || v.city == 'Lahore';

      // Draw node dot
      canvas.drawCircle(
        Offset(dx, dy),
        isCapital ? 4.5 : (isKarachiOrLahore ? 3.5 : 2.5),
        isCapital ? capitalDotPaint : cityDotPaint,
      );

      // Label text
      final textSpan = TextSpan(
        text: v.city,
        style: textStyle.copyWith(
          fontSize: isCapital || isKarachiOrLahore ? 9.5 : 8.0,
          fontWeight: isCapital || isKarachiOrLahore ? FontWeight.w800 : FontWeight.w600,
          color: isCapital
              ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
              : (isDark ? Colors.white70 : Colors.black87),
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(dx + 5, dy - 5));
    }

    canvas.restore();
  }

  void _drawText(Canvas canvas, String text, Offset offset, double size, Color color, FontWeight weight) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: 1.5,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _PakistanMapCanvasPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.offset != offset ||
        oldDelegate.zoom != zoom ||
        oldDelegate.selectedVenueName != selectedVenueName ||
        oldDelegate.currentLat != currentLat ||
        oldDelegate.currentLng != currentLng;
  }
}

/// Live Slippy Map tile renderer for OpenStreetMap & Satellite cartography
class _OpenStreetMapTileLayer extends StatelessWidget {
  final double lat;
  final double lng;
  final int zoom;
  final String mapMode; // 'osm', 'hybrid', 'vector'
  final bool isDark;

  const _OpenStreetMapTileLayer({
    required this.lat,
    required this.lng,
    required this.zoom,
    required this.mapMode,
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

        // Render 5x4 tile grid around current center coordinates
        final tiles = <Widget>[];
        for (int dx = -2; dx <= 2; dx++) {
          for (int dy = -2; dy <= 2; dy++) {
            final tx = centerTileX + dx;
            final ty = centerTileY + dy;
            if (tx < 0 || ty < 0) continue;

            final tileLeft = offsetX + (dx * 256.0);
            final tileTop = offsetY + (dy * 256.0);

            // Alternate between OpenStreetMap fast subdomains
            final sub = ['a', 'b', 'c'][(tx + ty).abs() % 3];
            final tileUrl = mapMode == 'hybrid'
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
                    color: isDark ? const Color(0xFF1E2230) : const Color(0xFFE9E5DB),
                    child: Center(
                      child: Icon(
                        Icons.map_outlined,
                        size: 24,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
        }

        return Stack(
          children: tiles,
        );
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
