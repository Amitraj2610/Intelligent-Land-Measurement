import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'field_storage.dart';

class ARMeasurementPage extends StatefulWidget {
  final String imagePath;

  const ARMeasurementPage({
    super.key,
    required this.imagePath,
  });

  @override
  State<ARMeasurementPage> createState() => _ARMeasurementPageState();
}

class _ARMeasurementPageState extends State<ARMeasurementPage> {
  final TextEditingController _referenceController = TextEditingController();

  String _selectedUnit = 'Centimeters';

  double? _estimatedArea;
  double? _referencePixelLength;
  int? _selectedPointIndex;
  bool _selectedRefHandle = false;

  // Four corners of the measurement area.
  // Values are normalized from 0.0 to 1.0.
  List<Offset> _polygonPoints = [
    const Offset(0.20, 0.20),
    const Offset(0.80, 0.20),
    const Offset(0.80, 0.80),
    const Offset(0.20, 0.80),
  ];

  // Reference line used for calibration.
  List<Offset> _referenceLine = [
    const Offset(0.35, 0.50),
    const Offset(0.65, 0.50),
  ];

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // RESET
  // ------------------------------------------------------------

  void _resetPoints() {
    setState(() {
      _polygonPoints = [
        const Offset(0.20, 0.20),
        const Offset(0.80, 0.20),
        const Offset(0.80, 0.80),
        const Offset(0.20, 0.80),
      ];

      _referenceLine = [
        const Offset(0.35, 0.50),
        const Offset(0.65, 0.50),
      ];

      _estimatedArea = null;
      _referencePixelLength = null;
      _selectedPointIndex = null;
      _selectedRefHandle = false;
    });
  }

  // ------------------------------------------------------------
  // UPDATE POLYGON POINT
  // ------------------------------------------------------------

  void _updatePoint(int index, Offset position) {
    final clamped = Offset(
      position.dx.clamp(0.0, 1.0),
      position.dy.clamp(0.0, 1.0),
    );

    setState(() {
      _polygonPoints[index] = clamped;
      _estimatedArea = null;
    });
  }

  // ------------------------------------------------------------
  // UPDATE REFERENCE LINE
  // ------------------------------------------------------------

  void _updateRefPosition(int index, Offset position) {
    final clamped = Offset(
      position.dx.clamp(0.0, 1.0),
      position.dy.clamp(0.0, 1.0),
    );

    setState(() {
      _referenceLine[index] = clamped;
      _estimatedArea = null;
    });
  }

  // ------------------------------------------------------------
  // CALCULATE AREA
  // ------------------------------------------------------------

  void _calculateArea(Size imageSize) {
    final referenceText = _referenceController.text.trim();

    if (referenceText.isEmpty) {
      _showMessage('Please enter the known reference length.');
      return;
    }

    final referenceLength = double.tryParse(referenceText);

    if (referenceLength == null || referenceLength <= 0) {
      _showMessage('Please enter a valid reference length.');
      return;
    }

    if (_polygonPoints.length < 3) {
      _showMessage('Please select at least 3 points.');
      return;
    }

    // Convert normalized reference points to actual pixels.
    final refStart = Offset(
      _referenceLine[0].dx * imageSize.width,
      _referenceLine[0].dy * imageSize.height,
    );

    final refEnd = Offset(
      _referenceLine[1].dx * imageSize.width,
      _referenceLine[1].dy * imageSize.height,
    );

    final referencePixelLength = (refEnd - refStart).distance;

    if (referencePixelLength <= 0) {
      _showMessage('Reference line is too small.');
      return;
    }

    // Convert polygon points to pixels.
    final pixelPoints = _polygonPoints.map((point) {
      return Offset(
        point.dx * imageSize.width,
        point.dy * imageSize.height,
      );
    }).toList();

    // Calculate polygon area in pixels.
    final pixelArea = _calculatePolygonArea(pixelPoints);

    if (pixelArea <= 0) {
      _showMessage('Unable to calculate the selected area.');
      return;
    }

    // Convert reference length to meters.
    final referenceMeters = _convertToMeters(
      referenceLength,
      _selectedUnit,
    );

    // Pixel -> meter scale.
    final metersPerPixel = referenceMeters / referencePixelLength;

    // Area conversion requires scale squared.
    final areaInMeters = pixelArea * metersPerPixel * metersPerPixel;

    setState(() {
      _referencePixelLength = referencePixelLength;
      _estimatedArea = areaInMeters;
    });
  }

  // ------------------------------------------------------------
  // UNIT CONVERSION
  // ------------------------------------------------------------

  double _convertToMeters(
    double value,
    String unit,
  ) {
    switch (unit) {
      case 'Centimeters':
        return value / 100.0;

      case 'Meters':
        return value;

      case 'Feet':
        return value * 0.3048;

      case 'Yards':
        return value * 0.9144;

      default:
        return value;
    }
  }

  // ------------------------------------------------------------
  // POLYGON AREA - SHOELACE FORMULA
  // ------------------------------------------------------------

  double _calculatePolygonArea(List<Offset> points) {
    if (points.length < 3) {
      return 0;
    }

    double area = 0;

    for (int i = 0; i < points.length; i++) {
      final current = points[i];
      final next = points[(i + 1) % points.length];

      area += (current.dx * next.dy) - (next.dx * current.dy);
    }

    return area.abs() / 2;
  }

  // ------------------------------------------------------------
  // SNACKBAR
  // ------------------------------------------------------------

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ------------------------------------------------------------
  // SAVE MEASUREMENT TO MONGODB DATABASE
  // ------------------------------------------------------------

  Future<void> _saveMeasurement() async {
    if (_estimatedArea == null) {
      _showMessage('Please calculate the area first.');
      return;
    }

    final nameController = TextEditingController(text: 'Photo Plot ${DateTime.now().minute}');

    final String? fieldName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Photo Measurement'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Field Name',
            hintText: 'e.g. Garden Plot, Backyard, etc.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: const Text('Save to MongoDB'),
          ),
        ],
      ),
    );

    if (fieldName == null || fieldName.isEmpty) return;

    try {
      final record = FieldRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fieldName,
        areaSqMeters: _estimatedArea!,
        latitude: 0.0,
        longitude: 0.0,
        measuredAt: DateTime.now(),
        notes: 'Measured with Camera AR Calibration (${widget.imagePath})',
      );

      await FieldStorage.saveField(record, measurementType: 'Camera');
      if (!mounted) return;
      _showMessage('Measurement "$fieldName" saved to MongoDB Compass!');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Saved locally. Database sync will retry.');
    }
  }

  // ------------------------------------------------------------
  // HELP
  // ------------------------------------------------------------

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('How to Measure'),
          content: const SingleChildScrollView(
            child: Text(
              '1. Use the yellow dots to position the reference line.\n\n'
              '2. Enter the real-world length of the reference object.\n\n'
              '3. Select the correct unit.\n\n'
              '4. Move the green corner points around the area you want to measure.\n\n'
              '5. Tap "Calculate Area".\n\n'
              'The app uses the reference length to estimate the real-world area.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // IMAGE
  // ------------------------------------------------------------

  Widget _buildImage() {
    if (kIsWeb) {
      return Image.network(
        widget.imagePath,
        fit: BoxFit.contain,
      );
    }

    return Image.file(
      File(widget.imagePath),
      fit: BoxFit.contain,
    );
  }

  // ------------------------------------------------------------
  // RESULT CARD
  // ------------------------------------------------------------

  Widget _buildResultCard() {
    if (_estimatedArea == null) {
      return const SizedBox.shrink();
    }

    final area = _estimatedArea!;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2E7D32),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Color(0xFF2E7D32),
              ),
              SizedBox(width: 8),
              Text(
                'Measurement Result',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${area.toStringAsFixed(2)} m²',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Square Centimeters: '
            '${(area * 10000).toStringAsFixed(2)} cm²',
          ),
          Text(
            'Square Feet: '
            '${(area * 10.7639104167).toStringAsFixed(2)} ft²',
          ),
          Text(
            'Square Yards: '
            '${(area * 1.1959900463).toStringAsFixed(2)} yd²',
          ),
          if (_referencePixelLength != null) ...[
            const SizedBox(height: 6),
            Text(
              'Reference Scale: ${_referencePixelLength!.toStringAsFixed(1)} px',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveMeasurement,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Save Measurement to Database'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // MAIN UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text(
          'Manual Measurement',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showHelp,
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ------------------------------------------------
              // IMAGE + MEASUREMENT OVERLAY
              // ------------------------------------------------

              LayoutBuilder(
                builder: (context, constraints) {
                  final imageWidth = constraints.maxWidth;

                  // Keep a reasonable image area.
                  final imageHeight = imageWidth * 0.75;

                  return Container(
                    width: double.infinity,
                    height: imageHeight,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // IMAGE
                        _buildImage(),

                        // DRAWING AREA
                        CustomPaint(
                          painter: MeasurementPainter(
                            polygonPoints: _polygonPoints,
                            referenceLine: _referenceLine,
                          ),
                        ),

                        // ----------------------------------------
                        // REFERENCE HANDLES
                        // ----------------------------------------

                        ...List.generate(
                          _referenceLine.length,
                          (index) {
                            final point = _referenceLine[index];

                            return Positioned(
                              left: point.dx * imageWidth - 22,
                              top: point.dy * imageHeight - 22,
                              width: 44,
                              height: 44,
                              child: GestureDetector(
                                onPanStart: (_) {
                                  setState(() {
                                    _selectedRefHandle = true;
                                    _selectedPointIndex = null;
                                  });
                                },
                                onPanUpdate: (details) {
                                  final newX =
                                      point.dx + details.delta.dx / imageWidth;

                                  final newY =
                                      point.dy + details.delta.dy / imageHeight;

                                  _updateRefPosition(
                                    index,
                                    Offset(
                                      newX,
                                      newY,
                                    ),
                                  );
                                },
                                onPanEnd: (_) {
                                  setState(() {
                                    _selectedRefHandle = false;
                                  });
                                },
                                child: Center(
                                  child: Container(
                                    width: _selectedRefHandle ? 18 : 14,
                                    height: _selectedRefHandle ? 18 : 14,
                                    decoration: BoxDecoration(
                                      color: Colors.yellow,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _selectedRefHandle
                                            ? Colors.orange
                                            : Colors.black,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // ----------------------------------------
                        // GREEN CORNER HANDLES
                        // ----------------------------------------

                        ...List.generate(
                          _polygonPoints.length,
                          (index) {
                            final point = _polygonPoints[index];

                            return Positioned(
                              left: point.dx * imageWidth - 22,
                              top: point.dy * imageHeight - 22,
                              width: 44,
                              height: 44,
                              child: GestureDetector(
                                onPanStart: (_) {
                                  setState(() {
                                    _selectedPointIndex = index;
                                    _selectedRefHandle = false;
                                  });
                                },
                                onPanUpdate: (details) {
                                  final newX =
                                      point.dx + details.delta.dx / imageWidth;

                                  final newY =
                                      point.dy + details.delta.dy / imageHeight;

                                  _updatePoint(
                                    index,
                                    Offset(
                                      newX,
                                      newY,
                                    ),
                                  );
                                },
                                onPanEnd: (_) {
                                  setState(() {
                                    _selectedPointIndex = null;
                                  });
                                },
                                child: Center(
                                  child: Container(
                                    width: _selectedPointIndex == index ? 18 : 14,
                                    height: _selectedPointIndex == index ? 18 : 14,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF2E7D32,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _selectedPointIndex == index
                                            ? Colors.amber
                                            : Colors.white,
                                        width: _selectedPointIndex == index ? 3 : 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ------------------------------------------------
              // REFERENCE LENGTH
              // ------------------------------------------------

              const Text(
                'Known Reference Length',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _referenceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Example: 30',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2E7D32),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedUnit,
                        items: const [
                          DropdownMenuItem(
                            value: 'Centimeters',
                            child: Text('cm'),
                          ),
                          DropdownMenuItem(
                            value: 'Meters',
                            child: Text('m'),
                          ),
                          DropdownMenuItem(
                            value: 'Feet',
                            child: Text('ft'),
                          ),
                          DropdownMenuItem(
                            value: 'Yards',
                            child: Text('yd'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            _selectedUnit = value;
                            _estimatedArea = null;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              const Text(
                'Use a known object in the image as your reference, '
                'such as a ruler, tile, brick, or measuring scale.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 20),

              // ------------------------------------------------
              // CALCULATE BUTTON
              // ------------------------------------------------

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Get the same image display size used above.
                    final width = MediaQuery.of(context).size.width - 32;

                    final height = width * 0.75;

                    _calculateArea(
                      Size(width, height),
                    );
                  },
                  icon: const Icon(Icons.calculate),
                  label: const Text(
                    'Calculate Area',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ------------------------------------------------
              // RESET BUTTON
              // ------------------------------------------------

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _resetPoints,
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Reset Points',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    side: const BorderSide(
                      color: Color(0xFF2E7D32),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              // ------------------------------------------------
              // RESULT
              // ------------------------------------------------

              _buildResultCard(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MEASUREMENT PAINTER
// ============================================================

class MeasurementPainter extends CustomPainter {
  final List<Offset> polygonPoints;
  final List<Offset> referenceLine;

  MeasurementPainter({
    required this.polygonPoints,
    required this.referenceLine,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    // Convert normalized points to screen coordinates.
    final polygon = polygonPoints.map((point) {
      return Offset(
        point.dx * size.width,
        point.dy * size.height,
      );
    }).toList();

    final reference = referenceLine.map((point) {
      return Offset(
        point.dx * size.width,
        point.dy * size.height,
      );
    }).toList();

    // --------------------------------------------------------
    // GREEN POLYGON
    // --------------------------------------------------------

    if (polygon.length >= 3) {
      final polygonPath = Path();

      polygonPath.moveTo(
        polygon[0].dx,
        polygon[0].dy,
      );

      for (int i = 1; i < polygon.length; i++) {
        polygonPath.lineTo(
          polygon[i].dx,
          polygon[i].dy,
        );
      }

      polygonPath.close();

      // Transparent green fill.
      final fillPaint = Paint()
        ..color = const Color(0x552E7D32)
        ..style = PaintingStyle.fill;

      canvas.drawPath(
        polygonPath,
        fillPaint,
      );

      // Green border.
      final borderPaint = Paint()
        ..color = const Color(0xFF2E7D32)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      canvas.drawPath(
        polygonPath,
        borderPaint,
      );
    }

    // --------------------------------------------------------
    // YELLOW REFERENCE LINE
    // --------------------------------------------------------

    if (reference.length >= 2) {
      final referencePaint = Paint()
        ..color = Colors.yellow
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        reference[0],
        reference[1],
        referencePaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant MeasurementPainter oldDelegate,
  ) {
    return oldDelegate.polygonPoints != polygonPoints ||
        oldDelegate.referenceLine != referenceLine;
  }
}
