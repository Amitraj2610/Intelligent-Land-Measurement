import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'field_storage.dart';

class GPSMeasurementPage extends StatefulWidget {
  const GPSMeasurementPage({super.key});

  @override
  State<GPSMeasurementPage> createState() => _GPSMeasurementPageState();
}

enum MapTypeMode {
  standard,
  satellite,
  terrain,
  dark,
}

class _GPSMeasurementPageState extends State<GPSMeasurementPage> {
  // ===========================================================================
  // COLORS
  // ===========================================================================

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color darkGreen = Color(0xFF1B5E20);

  // ===========================================================================
  // CONTROLLERS
  // ===========================================================================

  final MapController _mapController = MapController();

  final GlobalKey _mapKey = GlobalKey();

  final TextEditingController _searchController = TextEditingController();

  // ===========================================================================
  // LOCATION
  // ===========================================================================

  LatLng _currentLocation = const LatLng(20.5937, 78.9629);

  double? _gpsAccuracy;

  bool _isLoadingLocation = true;

  bool _isAddingGPSPoint = false;
  bool _isSavingToDatabase = false;

  // ===========================================================================
  // LAND BOUNDARY
  // ===========================================================================

  final List<LatLng> _polygonPoints = <LatLng>[];

  double? _calculatedAreaSqMeters;

  int? _draggingPointIndex;

  // ===========================================================================
  // MAP
  // ===========================================================================

  MapTypeMode _selectedMapType = MapTypeMode.standard;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _determinePosition();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // GPS LOCATION
  // ===========================================================================

  Future<void> _determinePosition() async {
    if (!mounted) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        setState(() {
          _isLoadingLocation = false;
        });

        _showMessage(
          'Location services are disabled. Please enable GPS.',
        );

        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;

        setState(() {
          _isLoadingLocation = false;
        });

        _showMessage(
          'Location permission was denied.',
        );

        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          _isLoadingLocation = false;
        });

        _showMessage(
          'Location permission is permanently denied. '
          'Enable it from device settings.',
        );

        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final LatLng location = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _currentLocation = location;
        _gpsAccuracy = position.accuracy;
        _isLoadingLocation = false;
      });

      _moveMapTo(location, 18.0);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingLocation = false;
      });

      _showMessage(
        'Unable to fetch location.',
      );
    }
  }

  // ===========================================================================
  // ADD CURRENT GPS POINT
  // ===========================================================================

  Future<void> _addCurrentGPSPin() async {
    if (!mounted || _isAddingGPSPoint) {
      return;
    }

    setState(() {
      _isAddingGPSPoint = true;
    });

    try {
      _showMessage(
        'Getting high-accuracy GPS location...',
      );

      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showMessage(
          'Please enable GPS/location services first.',
        );

        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMessage(
          'Location permission was denied.',
        );

        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage(
          'Location permission is permanently denied. '
          'Enable it from device settings.',
        );

        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      final double accuracy = position.accuracy;

      final LatLng location = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _currentLocation = location;
        _gpsAccuracy = accuracy;
      });

      if (accuracy > 20) {
        final bool? continueAdding = await _showPoorAccuracyDialog(
          accuracy,
        );

        if (continueAdding != true) {
          return;
        }
      }

      if (!mounted) return;

      setState(() {
        _polygonPoints.add(location);
      });

      _calculateArea();

      _moveMapTo(location, 18.0);

      _showMessage(
        'GPS point ${_polygonPoints.length} added '
        '(±${accuracy.toStringAsFixed(1)} m)',
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Could not acquire GPS location.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingGPSPoint = false;
        });
      }
    }
  }

  // ===========================================================================
  // SAVE LAND TO MONGODB BACKEND
  // ===========================================================================

  Future<void> _saveLandToDatabase() async {
    if (_polygonPoints.length < 3 || _calculatedAreaSqMeters == null) {
      _showMessage(
          'Please add at least 3 points to form a valid land boundary.');
      return;
    }

    final TextEditingController fieldNameController = TextEditingController();

    final String? fieldName = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Save Land Measurement'),
          content: TextField(
            controller: fieldNameController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter Field Name (e.g., North Farm)',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(fieldNameController.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (fieldName == null || fieldName.isEmpty) return;

    setState(() {
      _isSavingToDatabase = true;
    });

    try {
      final boundaryPoints = _polygonPoints
          .map((point) => FieldPoint(
                latitude: point.latitude,
                longitude: point.longitude,
              ))
          .toList();

      final double centerLat = _polygonPoints.map((p) => p.latitude).reduce((a, b) => a + b) / _polygonPoints.length;
      final double centerLng = _polygonPoints.map((p) => p.longitude).reduce((a, b) => a + b) / _polygonPoints.length;

      final newRecord = FieldRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fieldName,
        areaSqMeters: _calculatedAreaSqMeters!,
        latitude: centerLat,
        longitude: centerLng,
        measuredAt: DateTime.now(),
        boundary: boundaryPoints,
      );

      await FieldStorage.saveField(newRecord, measurementType: 'GPS');

      if (!mounted) return;
      _showMessage('Land "$fieldName" successfully saved to MongoDB Compass!');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Saved locally. Database sync will retry.');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingToDatabase = false;
        });
      }
    }
  }

  // ===========================================================================
  // GPS ACCURACY WARNING
  // ===========================================================================

  Future<bool?> _showPoorAccuracyDialog(
    double accuracy,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: <Widget>[
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Low GPS Accuracy',
                ),
              ),
            ],
          ),
          content: Text(
            'Current GPS accuracy is approximately '
            '±${accuracy.toStringAsFixed(1)} meters.\n\n'
            'For more accurate land measurement, '
            'move to an open area and wait for a '
            'better GPS signal.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'Add Anyway',
              ),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // MOVE MAP
  // ===========================================================================

  void _moveMapTo(
    LatLng location,
    double zoom,
  ) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted) return;

        try {
          _mapController.move(
            location,
            zoom,
          );
        } catch (_) {}
      },
    );
  }

  // ===========================================================================
  // POINT MANAGEMENT
  // ===========================================================================

  void _addPoint(LatLng point) {
    if (_draggingPointIndex != null) {
      return;
    }

    setState(() {
      _polygonPoints.add(point);
    });

    _calculateArea();
  }

  void _undoLastPoint() {
    if (_polygonPoints.isEmpty) {
      return;
    }

    setState(() {
      _polygonPoints.removeLast();
      _draggingPointIndex = null;
    });

    _calculateArea();
  }

  void _clearAllPoints() {
    if (_polygonPoints.isEmpty) {
      return;
    }

    setState(() {
      _polygonPoints.clear();
      _calculatedAreaSqMeters = null;
      _draggingPointIndex = null;
    });
  }

  // ===========================================================================
  // DRAGGABLE CORNER POINTS
  // ===========================================================================

  void _startDraggingPoint(
    int index,
  ) {
    if (index < 0 || index >= _polygonPoints.length) {
      return;
    }

    setState(() {
      _draggingPointIndex = index;
    });
  }

  void _finishDraggingPoint() {
    if (!mounted) return;

    setState(() {
      _draggingPointIndex = null;
    });

    _calculateArea();
  }

  void _movePoint(
    int index,
    DragUpdateDetails details,
    BuildContext markerContext,
  ) {
    if (index < 0 || index >= _polygonPoints.length) {
      return;
    }

    try {
      final RenderObject? renderObject =
          _mapKey.currentContext?.findRenderObject();

      if (renderObject is! RenderBox) {
        return;
      }

      final Offset mapLocalPosition = renderObject.globalToLocal(
        details.globalPosition,
      );

      final MapCamera camera = MapCamera.of(markerContext);

      final LatLng newPosition = camera.offsetToCrs(
        mapLocalPosition,
      );

      if (!mounted) return;

      setState(() {
        _polygonPoints[index] = newPosition;
      });

      _calculateArea();
    } catch (_) {}
  }

  // ===========================================================================
  // AREA CALCULATION
  // ===========================================================================

  void _calculateArea() {
    if (_polygonPoints.length < 3) {
      if (!mounted) return;

      setState(() {
        _calculatedAreaSqMeters = null;
      });

      return;
    }

    const double earthRadius = 6378137.0;

    double areaSum = 0.0;

    for (int i = 0; i < _polygonPoints.length; i++) {
      final LatLng p1 = _polygonPoints[i];

      final LatLng p2 = _polygonPoints[(i + 1) % _polygonPoints.length];

      final double lat1 = p1.latitude * pi / 180.0;

      final double lat2 = p2.latitude * pi / 180.0;

      double longitudeDifference = (p2.longitude - p1.longitude) * pi / 180.0;

      if (longitudeDifference > pi) {
        longitudeDifference -= 2 * pi;
      }

      if (longitudeDifference < -pi) {
        longitudeDifference += 2 * pi;
      }

      areaSum += longitudeDifference * (2.0 + sin(lat1) + sin(lat2));
    }

    final double area = (areaSum * earthRadius * earthRadius / 4.0).abs();

    if (!mounted) return;

    setState(() {
      _calculatedAreaSqMeters = area;
    });
  }

  // ===========================================================================
  // WORLDWIDE SEARCH
  // ===========================================================================

  Future<List<_PlaceSearchResult>> _performWorldwideSearch(
    String searchText,
  ) async {
    final Uri uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      <String, String>{
        'q': searchText,
        'format': 'jsonv2',
        'limit': '10',
        'addressdetails': '1',
        'accept-language': 'en',
      },
    );

    final http.Response response = await http.get(
      uri,
      headers: const <String, String>{
        'User-Agent': 'IntelligentLandMeasurement/1.0',
        'Accept': 'application/json',
      },
    ).timeout(
      const Duration(
        seconds: 15,
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Search returned HTTP '
        '${response.statusCode}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception(
        'Invalid search response.',
      );
    }

    final Map<String, _PlaceSearchResult> uniqueResults =
        <String, _PlaceSearchResult>{};

    for (final dynamic item in decoded) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final double? latitude = double.tryParse(
        item['lat']?.toString() ?? '',
      );

      final double? longitude = double.tryParse(
        item['lon']?.toString() ?? '',
      );

      if (latitude == null || longitude == null) {
        continue;
      }

      final String displayName =
          item['display_name']?.toString() ?? 'Unknown location';

      final String key = '${latitude.toStringAsFixed(6)},'
          '${longitude.toStringAsFixed(6)}';

      uniqueResults[key] = _PlaceSearchResult(
        displayName: displayName,
        latitude: latitude,
        longitude: longitude,
      );
    }

    return uniqueResults.values.toList();
  }

  // ===========================================================================
  // SEARCH DIALOG
  // ===========================================================================

  void _openSearchDialog() {
    _searchController.clear();

    showDialog<void>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        bool isSearching = false;

        List<_PlaceSearchResult> searchResults = <_PlaceSearchResult>[];

        return StatefulBuilder(
          builder: (
            BuildContext localContext,
            StateSetter setDialogState,
          ) {
            Future<void> runSearch() async {
              final String query = _searchController.text.trim();

              if (query.isEmpty) {
                _showMessage(
                  'Enter a place to search.',
                );

                return;
              }

              setDialogState(() {
                isSearching = true;
                searchResults = <_PlaceSearchResult>[];
              });

              try {
                final List<_PlaceSearchResult> results =
                    await _performWorldwideSearch(
                  query,
                );

                if (!dialogContext.mounted) {
                  return;
                }

                setDialogState(() {
                  isSearching = false;
                  searchResults = results;
                });

                if (results.isEmpty) {
                  _showMessage(
                    'No matching location found. '
                    'Try a more specific place name.',
                  );
                }
              } catch (_) {
                if (!dialogContext.mounted) {
                  return;
                }

                setDialogState(() {
                  isSearching = false;
                  searchResults = <_PlaceSearchResult>[];
                });

                _showMessage(
                  'Unable to search. '
                  'Check your internet connection.',
                );
              }
            }

            return AlertDialog(
              title: const Row(
                children: <Widget>[
                  Icon(
                    Icons.search,
                    color: primaryGreen,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search Location',
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: _searchController,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) {
                        runSearch();
                      },
                      decoration: InputDecoration(
                        hintText: 'Search any place in the world...',
                        prefixIcon: const Icon(
                          Icons.location_on,
                        ),
                        suffixIcon: IconButton(
                          tooltip: 'Search',
                          icon: isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: primaryGreen,
                                  ),
                                )
                              : const Icon(
                                  Icons.search,
                                ),
                          onPressed: isSearching ? null : runSearch,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    if (isSearching)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: <Widget>[
                            CircularProgressIndicator(
                              color: primaryGreen,
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              'Searching worldwide...',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!isSearching && searchResults.isNotEmpty)
                      SizedBox(
                        height: 300,
                        child: ListView.separated(
                          itemCount: searchResults.length,
                          separatorBuilder: (
                            BuildContext _,
                            int __,
                          ) {
                            return const Divider(
                              height: 1,
                            );
                          },
                          itemBuilder: (
                            BuildContext itemContext,
                            int index,
                          ) {
                            final _PlaceSearchResult result =
                                searchResults[index];

                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(
                                  0xFFE8F5E9,
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  color: primaryGreen,
                                ),
                              ),
                              title: Text(
                                result.shortName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                result.displayName,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                _selectSearchResult(
                                  result,
                                  dialogContext,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    if (!isSearching && searchResults.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(
                          top: 14,
                        ),
                        child: Text(
                          'Examples: Chandigarh University, '
                          'PP Savani University, Eiffel Tower, '
                          'London, New York',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Text(
                      'Search powered by OpenStreetMap',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _selectSearchResult(
    _PlaceSearchResult result,
    BuildContext dialogContext,
  ) {
    final LatLng location = LatLng(
      result.latitude,
      result.longitude,
    );

    setState(() {
      _currentLocation = location;
    });

    Navigator.of(
      dialogContext,
    ).pop();

    _moveMapTo(
      location,
      17.0,
    );

    _showMessage(
      'Map moved to ${result.shortName}',
    );
  }

  void _showMapTypeSelector() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (
        BuildContext sheetContext,
      ) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Map Type',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                _mapTypeTile(
                  sheetContext,
                  MapTypeMode.standard,
                  Icons.map_outlined,
                  'Standard',
                  'Road map',
                ),
                _mapTypeTile(
                  sheetContext,
                  MapTypeMode.satellite,
                  Icons.satellite_alt,
                  'Satellite',
                  'Satellite imagery',
                ),
                _mapTypeTile(
                  sheetContext,
                  MapTypeMode.terrain,
                  Icons.terrain,
                  'Terrain',
                  'Terrain map',
                ),
                _mapTypeTile(
                  sheetContext,
                  MapTypeMode.dark,
                  Icons.dark_mode_outlined,
                  'Dark',
                  'Dark map',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mapTypeTile(
    BuildContext sheetContext,
    MapTypeMode type,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final bool selected = _selectedMapType == type;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      leading: CircleAvatar(
        backgroundColor: selected
            ? const Color(
                0xFFE8F5E9,
              )
            : Colors.grey.shade100,
        child: Icon(
          icon,
          color: selected ? primaryGreen : Colors.grey.shade700,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: selected
          ? const Icon(
              Icons.check_circle,
              color: primaryGreen,
            )
          : null,
      onTap: () {
        setState(() {
          _selectedMapType = type;
        });

        Navigator.of(
          sheetContext,
        ).pop();
      },
    );
  }

  String _tileUrl() {
    switch (_selectedMapType) {
      case MapTypeMode.standard:
        return 'https://tile.openstreetmap.org/'
            '{z}/{x}/{y}.png';

      case MapTypeMode.satellite:
        return 'https://server.arcgisonline.com/'
            'ArcGIS/rest/services/World_Imagery/'
            'MapServer/tile/{z}/{y}/{x}';

      case MapTypeMode.terrain:
        return 'https://{s}.tile.opentopomap.org/'
            '{z}/{x}/{y}.png';

      case MapTypeMode.dark:
        return 'https://{s}.basemaps.cartocdn.com/'
            'dark_all/{z}/{x}/{y}.png';
    }
  }

  String _mapAttribution() {
    switch (_selectedMapType) {
      case MapTypeMode.standard:
        return '© OpenStreetMap contributors';

      case MapTypeMode.satellite:
        return 'Imagery © Esri';

      case MapTypeMode.terrain:
        return '© OpenStreetMap contributors • SRTM';

      case MapTypeMode.dark:
        return '© OpenStreetMap contributors • © CARTO';
    }
  }

  String _mapTypeName(
    MapTypeMode type,
  ) {
    switch (type) {
      case MapTypeMode.standard:
        return 'Standard';

      case MapTypeMode.satellite:
        return 'Satellite';

      case MapTypeMode.terrain:
        return 'Terrain';

      case MapTypeMode.dark:
        return 'Dark';
    }
  }

  Color _gpsAccuracyColor(
    double accuracy,
  ) {
    if (accuracy <= 5) {
      return Colors.green;
    }

    if (accuracy <= 10) {
      return Colors.lightGreen.shade700;
    }

    if (accuracy <= 20) {
      return Colors.orange;
    }

    return Colors.red;
  }

  String _helperText() {
    if (_polygonPoints.isEmpty) {
      return 'Tap the map or use "Add GPS Pin" '
          'to mark your first boundary point.';
    }

    if (_polygonPoints.length == 1) {
      return 'Add the next corner of your land.';
    }

    if (_polygonPoints.length == 2) {
      return 'Add at least one more point '
          'to calculate the area.';
    }

    if (_draggingPointIndex != null) {
      return 'Drag the point and release it '
          'at the new boundary position.';
    }

    return 'Drag any numbered point to '
        'adjust your land boundary.';
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Widget _floatingMapButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white,
      elevation: 5,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 18,
                color: primaryGreen,
              ),
              const SizedBox(
                width: 6,
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GPS Land Measurement',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            tooltip: 'Search Place',
            icon: const Icon(
              Icons.search,
            ),
            onPressed: _openSearchDialog,
          ),
          IconButton(
            tooltip: 'Map Type',
            icon: const Icon(
              Icons.layers_outlined,
            ),
            onPressed: _showMapTypeSelector,
          ),
          IconButton(
            tooltip: 'My Location',
            icon: const Icon(
              Icons.my_location,
            ),
            onPressed: _determinePosition,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: SizedBox(
                    key: _mapKey,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentLocation,
                        initialZoom: 18.0,
                        minZoom: 3.0,
                        maxZoom: 20.0,
                        onTap: (
                          TapPosition tapPosition,
                          LatLng point,
                        ) {
                          _addPoint(
                            point,
                          );
                        },
                      ),
                      children: <Widget>[
                        TileLayer(
                          urlTemplate: _tileUrl(),
                          subdomains: _selectedMapType == MapTypeMode.terrain ||
                                  _selectedMapType == MapTypeMode.dark
                              ? const <String>[
                                  'a',
                                  'b',
                                  'c',
                                ]
                              : const <String>[],
                          userAgentPackageName:
                              'com.example.intelligent_land_measurement',
                        ),
                        if (_polygonPoints.length >= 3)
                          PolygonLayer(
                            polygons: <Polygon>[
                              Polygon(
                                points: _polygonPoints,
                                color: primaryGreen.withValues(
                                  alpha: 0.30,
                                ),
                                borderColor: darkGreen,
                                borderStrokeWidth: 3.0,
                              ),
                            ],
                          ),
                        if (_polygonPoints.length == 2)
                          PolylineLayer(
                            polylines: <Polyline>[
                              Polyline(
                                points: _polygonPoints,
                                color: darkGreen,
                                strokeWidth: 3.0,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: <Marker>[
                            Marker(
                              point: _currentLocation,
                              width: 36,
                              height: 36,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(
                                    alpha: 0.20,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            ...List<Marker>.generate(
                              _polygonPoints.length,
                              (
                                int index,
                              ) {
                                final bool isDragging =
                                    _draggingPointIndex == index;

                                return Marker(
                                  point: _polygonPoints[index],
                                  width: 58,
                                  height: 58,
                                  child: Builder(
                                    builder: (
                                      BuildContext markerContext,
                                    ) {
                                      return GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onPanStart: (_) {
                                          _startDraggingPoint(
                                            index,
                                          );
                                        },
                                        onPanUpdate: (
                                          DragUpdateDetails details,
                                        ) {
                                          _movePoint(
                                            index,
                                            details,
                                            markerContext,
                                          );
                                        },
                                        onPanEnd: (_) {
                                          _finishDraggingPoint();
                                        },
                                        child: AnimatedScale(
                                          scale: isDragging ? 1.25 : 1.0,
                                          duration: const Duration(
                                            milliseconds: 100,
                                          ),
                                          child: Container(
                                            alignment: Alignment.center,
                                            child: Container(
                                              width: isDragging ? 38 : 34,
                                              height: isDragging ? 38 : 34,
                                              decoration: BoxDecoration(
                                                color: primaryGreen,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 3,
                                                ),
                                                boxShadow: const <BoxShadow>[
                                                  BoxShadow(
                                                    color: Colors.black38,
                                                    blurRadius: 6,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${index + 1}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        RichAttributionWidget(
                          attributions: <TextSourceAttribution>[
                            TextSourceAttribution(
                              _mapAttribution(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: _openSearchDialog,
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          14,
                        ),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(
                              0,
                              3,
                            ),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: <Widget>[
                          Icon(
                            Icons.search,
                            color: primaryGreen,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Text(
                              'Search any place in the world...',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_right,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 76,
                  child: _floatingMapButton(
                    icon: Icons.layers_outlined,
                    label: _mapTypeName(
                      _selectedMapType,
                    ),
                    onPressed: _showMapTypeSelector,
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 18,
                  child: FloatingActionButton(
                    heroTag: 'gps_location_button',
                    backgroundColor: Colors.white,
                    foregroundColor: primaryGreen,
                    onPressed: _determinePosition,
                    child: const Icon(
                      Icons.my_location,
                    ),
                  ),
                ),
                if (_gpsAccuracy != null)
                  Positioned(
                    left: 12,
                    bottom: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          10,
                        ),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            _gpsAccuracy! <= 10
                                ? Icons.gps_fixed
                                : Icons.gps_not_fixed,
                            size: 16,
                            color: _gpsAccuracyColor(
                              _gpsAccuracy!,
                            ),
                          ),
                          const SizedBox(
                            width: 6,
                          ),
                          Text(
                            'GPS ±${_gpsAccuracy!.toStringAsFixed(1)} m',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 78,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: 0.72,
                        ),
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                      ),
                      child: Text(
                        _helperText(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isLoadingLocation)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black26,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: primaryGreen,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildResultPanel(),
        ],
      ),
    );
  }

  Widget _buildResultPanel() {
    final double sqMeters = _calculatedAreaSqMeters ?? 0.0;
    final double acres = sqMeters / 4046.8564224;
    final double hectares = sqMeters / 10000.0;
    final double sqFeet = sqMeters * 10.7639;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.polyline,
                  color: primaryGreen,
                  size: 20,
                ),
                const SizedBox(
                  width: 7,
                ),
                Text(
                  '${_polygonPoints.length} Boundary Points',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (_polygonPoints.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearAllPoints,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                    ),
                    label: const Text(
                      'Clear',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                  ),
              ],
            ),
            const SizedBox(
              height: 8,
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAddingGPSPoint ? null : _addCurrentGPSPin,
                    icon: _isAddingGPSPoint
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.add_location_alt,
                          ),
                    label: Text(
                      _isAddingGPSPoint ? 'Getting GPS...' : 'Add GPS Pin',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          11,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _polygonPoints.isNotEmpty ? _undoLastPoint : null,
                    icon: const Icon(
                      Icons.undo,
                    ),
                    label: const Text(
                      'Undo',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryGreen,
                      side: const BorderSide(
                        color: primaryGreen,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          11,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            if (_polygonPoints.length >= 3 &&
                _calculatedAreaSqMeters != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(
                  14,
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFE8F5E9,
                  ),
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                  border: Border.all(
                    color: Colors.green.shade300,
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    const Text(
                      'Calculated Land Area',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      '${acres.toStringAsFixed(3)} Acres',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 4,
                      children: <Widget>[
                        _areaValue(
                          '${hectares.toStringAsFixed(3)} ha',
                        ),
                        _areaValue(
                          '${sqMeters.toStringAsFixed(1)} m²',
                        ),
                        _areaValue(
                          '${sqFeet.toStringAsFixed(0)} sq ft',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSavingToDatabase ? null : _saveLandToDatabase,
                  icon: _isSavingToDatabase
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(_isSavingToDatabase
                      ? 'Saving...'
                      : 'Save Land to Database'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ),
            ] else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.info_outline,
                      color: Colors.grey,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Text(
                        _polygonPoints.length < 3
                            ? 'Add at least 3 boundary points '
                                'to calculate land area.'
                            : 'Drag a boundary point '
                                'to adjust the measurement.',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
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

  Widget _areaValue(
    String value,
  ) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }
}

class _PlaceSearchResult {
  final String displayName;
  final double latitude;
  final double longitude;

  const _PlaceSearchResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  String get shortName {
    final List<String> parts = displayName
        .split(',')
        .map(
          (String part) => part.trim(),
        )
        .where(
          (String part) => part.isNotEmpty,
        )
        .toList();

    if (parts.length <= 2) {
      return displayName;
    }

    return parts.take(2).join(', ');
  }
}
