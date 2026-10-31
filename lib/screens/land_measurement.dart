import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'field_storage.dart';

class LandMeasurementPage extends StatefulWidget {
  final String? imagePath;

  const LandMeasurementPage({
    super.key,
    this.imagePath,
  });

  @override
  State<LandMeasurementPage> createState() => _LandMeasurementPageState();
}

class _LandMeasurementPageState extends State<LandMeasurementPage> {
  final TextEditingController lengthController = TextEditingController();

  final TextEditingController widthController = TextEditingController();

  String selectedUnit = 'Meters';

  double? areaInMeters;

  // ------------------------------------------------------------
  // LENGTH CONVERSION CONSTANTS
  // ------------------------------------------------------------

  static const double feetToMeters = 0.3048;
  static const double yardsToMeters = 0.9144;

  // ------------------------------------------------------------
  // AREA CONVERSION CONSTANTS
  // ------------------------------------------------------------

  static const double squareMetersToFeet = 10.7639104167;
  static const double squareMetersToYards = 1.1959900463;

  @override
  void initState() {
    super.initState();

    lengthController.addListener(_clearResult);
    widthController.addListener(_clearResult);
  }

  // ------------------------------------------------------------
  // CLEAR RESULT WHEN INPUT CHANGES
  // ------------------------------------------------------------

  void _clearResult() {
    if (areaInMeters != null) {
      setState(() {
        areaInMeters = null;
      });
    }
  }

  // ------------------------------------------------------------
  // CALCULATE AREA
  // ------------------------------------------------------------

  void calculateArea() {
    final double? length = double.tryParse(
      lengthController.text.trim(),
    );

    final double? width = double.tryParse(
      widthController.text.trim(),
    );

    if (length == null || width == null) {
      showMessage(
        'Please enter valid length and width.',
      );
      return;
    }

    if (length <= 0 || width <= 0) {
      showMessage(
        'Length and width must be greater than zero.',
      );
      return;
    }

    double lengthInMeters = length;
    double widthInMeters = width;

    // Convert input values into meters first.
    if (selectedUnit == 'Feet') {
      lengthInMeters = length * feetToMeters;
      widthInMeters = width * feetToMeters;
    } else if (selectedUnit == 'Yards') {
      lengthInMeters = length * yardsToMeters;
      widthInMeters = width * yardsToMeters;
    }

    final double calculatedArea = lengthInMeters * widthInMeters;

    setState(() {
      areaInMeters = calculatedArea;
    });
  }

  // ------------------------------------------------------------
  // GET AREA IN SELECTED UNIT
  // ------------------------------------------------------------

  double getSelectedArea() {
    if (areaInMeters == null) {
      return 0;
    }

    if (selectedUnit == 'Feet') {
      return areaInMeters! * squareMetersToFeet;
    }

    if (selectedUnit == 'Yards') {
      return areaInMeters! * squareMetersToYards;
    }

    return areaInMeters!;
  }

  // ------------------------------------------------------------
  // GET SELECTED UNIT LABEL
  // ------------------------------------------------------------

  String getSelectedUnitLabel() {
    if (selectedUnit == 'Feet') {
      return 'ft²';
    }

    if (selectedUnit == 'Yards') {
      return 'yd²';
    }

    return 'm²';
  }

  // ------------------------------------------------------------
  // SHOW MESSAGE
  // ------------------------------------------------------------

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ------------------------------------------------------------
  // RESET CALCULATOR
  // ------------------------------------------------------------

  void resetCalculator() {
    lengthController.clear();
    widthController.clear();

    setState(() {
      selectedUnit = 'Meters';
      areaInMeters = null;
    });
  }

  // ------------------------------------------------------------
  // SAVE MEASUREMENT TO MONGODB DATABASE
  // ------------------------------------------------------------

  Future<void> saveMeasurement() async {
    if (areaInMeters == null) {
      showMessage(
        'Please calculate the area first.',
      );
      return;
    }

    final nameController = TextEditingController(
      text: 'Manual Plot ${DateTime.now().minute}',
    );

    final String? fieldName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Manual Measurement'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Field Name',
            hintText: 'e.g. Plot A, North Lawn',
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
        areaSqMeters: areaInMeters!,
        latitude: 0.0,
        longitude: 0.0,
        measuredAt: DateTime.now(),
        notes: 'Calculated manually: Length ${lengthController.text} $selectedUnit x Width ${widthController.text} $selectedUnit',
      );

      await FieldStorage.saveField(record, measurementType: 'Manual');
      if (!mounted) return;
      showMessage('Measurement "$fieldName" saved to MongoDB Compass!');
    } catch (_) {
      if (!mounted) return;
      showMessage('Saved locally. Database sync will retry.');
    }
  }

  // ------------------------------------------------------------
  // IMAGE PREVIEW
  // ------------------------------------------------------------

  Widget _buildSelectedImage() {
    if (widget.imagePath == null || widget.imagePath!.isEmpty) {
      return const SizedBox.shrink();
    }

    final String path = widget.imagePath!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.image,
                color: Color(0xFF2E7D32),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Selected Image',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImageWidget(path),
          ),
          const SizedBox(height: 8),
          Text(
            path,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String path) {
    // Web image preview.
    if (kIsWeb) {
      return Image.network(
        path,
        width: double.infinity,
        height: 210,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return _imageErrorWidget();
        },
      );
    }

    // Android, Windows, Linux and macOS image preview.
    return Image.file(
      File(path),
      width: double.infinity,
      height: 210,
      fit: BoxFit.cover,
      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        return _imageErrorWidget();
      },
    );
  }

  Widget _imageErrorWidget() {
    return Container(
      width: double.infinity,
      height: 150,
      color: Colors.grey.shade200,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 45,
            color: Colors.grey,
          ),
          SizedBox(height: 8),
          Text(
            'Image preview is not available',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // RESULT CARD
  // ------------------------------------------------------------

  Widget _buildResultCard() {
    if (areaInMeters == null) {
      return const SizedBox.shrink();
    }

    final double selectedArea = getSelectedArea();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.green,
          width: 1.3,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF2E7D32),
            size: 48,
          ),
          const SizedBox(height: 10),
          const Text(
            'Calculated Area',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${selectedArea.toStringAsFixed(2)} '
            '${getSelectedUnitLabel()}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          _buildAreaRow(
            title: 'Square meters',
            value: '${areaInMeters!.toStringAsFixed(2)} m²',
          ),
          const SizedBox(height: 8),
          _buildAreaRow(
            title: 'Square feet',
            value:
                '${(areaInMeters! * squareMetersToFeet).toStringAsFixed(2)} ft²',
          ),
          const SizedBox(height: 8),
          _buildAreaRow(
            title: 'Square yards',
            value:
                '${(areaInMeters! * squareMetersToYards).toStringAsFixed(2)} yd²',
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: saveMeasurement,
              icon: const Icon(Icons.save),
              label: const Text(
                'Save Measurement',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
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

  Widget _buildAreaRow({
    required String title,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // TEXT FIELD DECORATION
  // ------------------------------------------------------------

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF2E7D32),
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
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
    );
  }

  // ------------------------------------------------------------
  // DISPOSE CONTROLLERS
  // ------------------------------------------------------------

  @override
  void dispose() {
    lengthController.removeListener(_clearResult);
    widthController.removeListener(_clearResult);

    lengthController.dispose();
    widthController.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // BUILD SCREEN
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text(
          'Land Measurement',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calculate Land Area',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Enter the length and width of your land.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 22),

            // Selected camera/gallery image.
            _buildSelectedImage(),

            if (widget.imagePath != null) ...[
              const SizedBox(height: 22),
            ],

            // Length field.
            TextField(
              controller: lengthController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration(
                label: 'Length',
                hint: 'Enter land length',
                icon: Icons.straighten,
              ),
            ),

            const SizedBox(height: 18),

            // Width field.
            TextField(
              controller: widthController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration(
                label: 'Width',
                hint: 'Enter land width',
                icon: Icons.width_normal,
              ),
            ),

            const SizedBox(height: 18),

            // Unit dropdown.
            DropdownButtonFormField<String>(
              initialValue: selectedUnit,
              decoration: _inputDecoration(
                label: 'Measurement Unit',
                hint: 'Select unit',
                icon: Icons.square_foot,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Meters',
                  child: Text('Meters'),
                ),
                DropdownMenuItem(
                  value: 'Feet',
                  child: Text('Feet'),
                ),
                DropdownMenuItem(
                  value: 'Yards',
                  child: Text('Yards'),
                ),
              ],
              onChanged: (String? value) {
                if (value == null) return;

                setState(() {
                  selectedUnit = value;
                  areaInMeters = null;
                });
              },
            ),

            const SizedBox(height: 25),

            // Calculate button.
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: calculateArea,
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Reset button.
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: resetCalculator,
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'Reset',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  side: const BorderSide(
                    color: Color(0xFF2E7D32),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Result card.
            _buildResultCard(),
          ],
        ),
      ),
    );
  }
}
