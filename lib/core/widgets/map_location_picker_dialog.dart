import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

class LocationSuggestion {
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String category;

  const LocationSuggestion({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.category,
  });
}

/// Custom interactive Google Maps Location/Area Picker popup with Dark & Light mode compatibility
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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

  static const List<LocationSuggestion> _defaultVenues = [
    LocationSuggestion(
      name: 'Convention Centre Islamabad',
      address: 'Club Road, Rawal Lake Promenade, Islamabad',
      lat: 33.7088,
      lng: 73.1097,
      category: 'Conference Hall',
    ),
    LocationSuggestion(
      name: 'Expo Centre Lahore',
      address: '1A Abdul Haque Rd, Trade Centre Commercial Area Phase 2 Johar Town, Lahore',
      lat: 31.4682,
      lng: 74.2694,
      category: 'Exhibition Ground',
    ),
    LocationSuggestion(
      name: 'Karachi Expo Centre',
      address: 'Main University Rd, Gulshan-e-Iqbal, Karachi',
      lat: 24.9089,
      lng: 67.0784,
      category: 'Convention Center',
    ),
    LocationSuggestion(
      name: 'Serena Hotel Islamabad',
      address: 'Khayaban-e-Suhrawardy, G-5/1, Islamabad',
      lat: 33.7202,
      lng: 73.0984,
      category: 'Luxury Ballroom',
    ),
    LocationSuggestion(
      name: 'FAST-NUCES Auditorium',
      address: 'A.K. Brohi Road, H-11/4, Islamabad',
      lat: 33.6555,
      lng: 73.0153,
      category: 'Tech Campus',
    ),
    LocationSuggestion(
      name: 'LUMS Executive Center',
      address: 'DHA Phase 5, Cantt, Lahore',
      lat: 31.4704,
      lng: 74.4111,
      category: 'Academic Venue',
    ),
    LocationSuggestion(
      name: 'Pearl Continental Rawalpindi',
      address: 'Mall Road, Rawalpindi Cantt',
      lat: 33.5955,
      lng: 73.0543,
      category: 'Banquet Hall',
    ),
    LocationSuggestion(
      name: 'Arts Council of Pakistan',
      address: 'M.R. Kiyani Road, Saddar, Karachi',
      lat: 24.8569,
      lng: 67.0223,
      category: 'Cultural Center',
    ),
  ];

  late String _selectedVenueName;
  late String _selectedVenueAddress;
  late double _currentLat;
  late double _currentLng;
  double _zoomLevel = 1.0;
  Offset _mapOffset = Offset.zero;
  List<LocationSuggestion> _filteredVenues = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialLocation ?? '');
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    final matched = _defaultVenues.firstWhere(
      (v) => (widget.initialLocation != null &&
          (widget.initialLocation!.toLowerCase().contains(v.name.toLowerCase()) ||
              v.name.toLowerCase().contains(widget.initialLocation!.toLowerCase()))),
      orElse: () => _defaultVenues.first,
    );

    _selectedVenueName = widget.initialLocation?.isNotEmpty == true
        ? widget.initialLocation!
        : matched.name;
    _selectedVenueAddress = matched.address;
    _currentLat = matched.lat;
    _currentLng = matched.lng;
    _filteredVenues = _defaultVenues;

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
      if (query.isEmpty) {
        _filteredVenues = _defaultVenues;
      } else {
        _filteredVenues = _defaultVenues
            .where((v) =>
                v.name.toLowerCase().contains(query) ||
                v.address.toLowerCase().contains(query) ||
                v.category.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _selectVenue(LocationSuggestion venue) {
    setState(() {
      _selectedVenueName = venue.name;
      _selectedVenueAddress = venue.address;
      _currentLat = venue.lat;
      _currentLng = venue.lng;
      _searchController.text = venue.name;
      _mapOffset = Offset.zero;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _mapOffset += details.delta / _zoomLevel;
      // Synthesize micro coordinate change based on pan
      _currentLat -= details.delta.dy * 0.0001 / _zoomLevel;
      _currentLng += details.delta.dx * 0.0001 / _zoomLevel;
    });
  }

  void _zoomIn() {
    setState(() {
      _zoomLevel = (_zoomLevel * 1.25).clamp(0.6, 2.5);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel / 1.25).clamp(0.6, 2.5);
    });
  }

  void _centerUserLocation() {
    _selectVenue(_defaultVenues.first);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkSurfaceElevated : Colors.white;

    return Container(
      constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
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
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        Text(
                          'Google Maps Area Picker',
                          style: AppTypography.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                        ),
                        Text(
                          'Search venue or drag map to pin location',
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

            // Search Bar & Quick Chips
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              color: isDark ? const Color(0xFF14161E) : Colors.white,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search city, venue or landmark...',
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
                  SizedBox(
                    height: 32,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filteredVenues.length,
                      itemBuilder: (context, index) {
                        final v = _filteredVenues[index];
                        final isSelected = v.name == _selectedVenueName;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _selectVenue(v),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? AppColors.darkOrganizerAccent : AppColors.lightOrganizerAccent)
                                    : (isDark ? const Color(0xFF1E2232) : const Color(0xFFEBE7DD)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.place_rounded,
                                    size: 13,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    v.name,
                                    style: AppTypography.manrope(
                                      fontSize: 11.5,
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
                ],
              ),
            ),

            // Interactive Google Maps Canvas Viewport
            Expanded(
              child: GestureDetector(
                onPanUpdate: _onPanUpdate,
                child: ClipRect(
                  child: Stack(
                    children: [
                      // Google Maps Custom Styling Vector/Grid Background
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _GoogleMapCanvasPainter(
                            isDark: isDark,
                            offset: _mapOffset,
                            zoom: _zoomLevel,
                          ),
                        ),
                      ),

                      // Radar Pulse & Interactive Center Pin
                      Center(
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final pulseVal = _pulseController.value;
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Pulse wave ring
                                Container(
                                  width: 40 + (pulseVal * 36),
                                  height: 40 + (pulseVal * 36),
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
                                // Google Maps Pin Marker
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E2232) : Colors.black87,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
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
                                    const SizedBox(height: 3),
                                    Icon(
                                      Icons.location_pin,
                                      size: 38,
                                      color: isDark ? AppColors.darkAccent : AppColors.lightOrganizerAccent,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.4),
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

                      // Google Maps watermark pill
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Google',
                                style: AppTypography.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Maps Engine',
                                style: AppTypography.manrope(
                                  fontSize: 9.5,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Map Zoom and GPS Controls
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildControlBtn(
                              icon: Icons.my_location_rounded,
                              tooltip: 'Center Location',
                              isDark: isDark,
                              onTap: _centerUserLocation,
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
                        Icons.place_rounded,
                        color: isDark ? AppColors.darkAccent : AppColors.lightOrganizerAccent,
                        size: 22,
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
                              _selectedVenueAddress,
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_currentLat.toStringAsFixed(4)}°, ${_currentLng.toStringAsFixed(4)}°',
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
                  const SizedBox(height: 14),
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
                          text: 'Confirm Location',
                          icon: Icons.check_circle_outline_rounded,
                          variant: AppButtonVariant.organizer,
                          onPressed: () {
                            final chosenLocation = _selectedVenueName.isNotEmpty
                                ? _selectedVenueName
                                : '$_selectedVenueAddress (${_currentLat.toStringAsFixed(4)}, ${_currentLng.toStringAsFixed(4)})';
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
}

/// Custom painter that renders a vector-styled Google Maps canvas (light / dark themed)
class _GoogleMapCanvasPainter extends CustomPainter {
  final bool isDark;
  final Offset offset;
  final double zoom;

  _GoogleMapCanvasPainter({
    required this.isDark,
    required this.offset,
    required this.zoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Base land color
    final landColor = isDark ? const Color(0xFF12151F) : const Color(0xFFF1EFE6);
    canvas.drawRect(Offset.zero & size, Paint()..color = landColor);

    canvas.save();
    canvas.translate(size.width / 2 + offset.dx, size.height / 2 + offset.dy);
    canvas.scale(zoom);

    // River / Water body
    final waterPaint = Paint()
      ..color = isDark ? const Color(0xFF17283C) : const Color(0xFFCADBE9)
      ..style = PaintingStyle.fill;

    final waterPath = Path();
    waterPath.moveTo(-400, -180);
    waterPath.cubicTo(-200, -220, -50, -120, 120, -180);
    waterPath.cubicTo(260, -240, 420, -160, 600, -190);
    waterPath.lineTo(600, -350);
    waterPath.lineTo(-400, -350);
    waterPath.close();
    canvas.drawPath(waterPath, waterPaint);

    // Park / Greenery Zone
    final parkPaint = Paint()
      ..color = isDark ? const Color(0xFF172B20) : const Color(0xFFD8EBD5)
      ..style = PaintingStyle.fill;

    final parkRect1 = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-280, 40, 220, 180),
      const Radius.circular(24),
    );
    canvas.drawRRect(parkRect1, parkPaint);

    final parkRect2 = RRect.fromRectAndRadius(
      const Rect.fromLTWH(120, -80, 260, 200),
      const Radius.circular(28),
    );
    canvas.drawRRect(parkRect2, parkPaint);

    // Secondary Roads
    final secRoadPaint = Paint()
      ..color = isDark ? const Color(0xFF1E2436) : const Color(0xFFFFFFFF)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    for (double y = -300; y <= 300; y += 70) {
      canvas.drawLine(Offset(-500, y), Offset(500, y), secRoadPaint);
    }
    for (double x = -400; x <= 400; x += 90) {
      canvas.drawLine(Offset(x, -400), Offset(x, 400), secRoadPaint);
    }

    // Major Highways / Arteries
    final mainHwyPaint = Paint()
      ..color = isDark ? const Color(0xFF2C3550) : const Color(0xFFFEDC9D)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final hwyPath1 = Path()
      ..moveTo(-500, -100)
      ..cubicTo(-180, -90, 80, 40, 500, 80);
    canvas.drawPath(hwyPath1, mainHwyPaint);

    final hwyPath2 = Path()
      ..moveTo(-60, -400)
      ..cubicTo(-40, -120, 20, 150, 40, 400);
    canvas.drawPath(hwyPath2, mainHwyPaint);

    // Highway Core Line
    final hwyCorePaint = Paint()
      ..color = isDark ? const Color(0xFF3E4B72) : const Color(0xFFFFF6D6)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(hwyPath1, hwyCorePaint);
    canvas.drawPath(hwyPath2, hwyCorePaint);

    // Building / Venue Blocks
    final blockPaint = Paint()
      ..color = isDark ? const Color(0xFF181C2B) : const Color(0xFFE4DFD3)
      ..style = PaintingStyle.fill;

    final blockCoords = [
      const Rect.fromLTWH(-160, -60, 70, 50),
      const Rect.fromLTWH(-60, -60, 80, 50),
      const Rect.fromLTWH(-160, 10, 70, 60),
      const Rect.fromLTWH(40, 30, 60, 80),
      const Rect.fromLTWH(-60, 80, 80, 70),
    ];
    for (final b in blockCoords) {
      canvas.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(6)), blockPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GoogleMapCanvasPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.offset != offset ||
        oldDelegate.zoom != zoom;
  }
}
