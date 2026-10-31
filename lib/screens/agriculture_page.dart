import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'field_storage.dart';
import '../services/api_service.dart'; // Ensure this matches your project path

class CropData {
  final String id;
  final String name;
  final String hindiName;
  final String season; // Kharif, Rabi, Zaid, Annual
  final String category; // Cereal, Pulses, Oilseeds, Cash, Vegetable
  final double seedRatePerAcre; // kg/acre
  final String seedUnit; // kg, packets, quintal
  final double seedPricePerUnit; // in currency units (₹ or $)
  final double ureaBagsPerAcre; // 50kg bags
  final double dapBagsPerAcre; // 50kg bags
  final double mopBagsPerAcre; // 50kg bags
  final double fymTonsPerAcre; // Farm yard manure tons
  final double waterReqMm; // mm across season
  final int durationDays;
  final String expectedYieldPerAcre;
  final List<String> suitableSoils;
  final String waterNeeds; // Low, Moderate, High
  final String icon;

  const CropData({
    required this.id,
    required this.name,
    required this.hindiName,
    required this.season,
    required this.category,
    required this.seedRatePerAcre,
    this.seedUnit = 'kg',
    required this.seedPricePerUnit,
    required this.ureaBagsPerAcre,
    required this.dapBagsPerAcre,
    required this.mopBagsPerAcre,
    required this.fymTonsPerAcre,
    required this.waterReqMm,
    required this.durationDays,
    required this.expectedYieldPerAcre,
    required this.suitableSoils,
    required this.waterNeeds,
    this.icon = '🌾',
  });
}

const List<CropData> kAllCrops = [
  CropData(
    id: 'wheat',
    name: 'Wheat',
    hindiName: 'गेहूँ',
    season: 'Rabi',
    category: 'Cereal',
    seedRatePerAcre: 40.0,
    seedPricePerUnit: 45.0,
    ureaBagsPerAcre: 2.0,
    dapBagsPerAcre: 1.0,
    mopBagsPerAcre: 0.5,
    fymTonsPerAcre: 3.5,
    waterReqMm: 450,
    durationDays: 130,
    expectedYieldPerAcre: '18 - 22 Quintals',
    suitableSoils: ['Alluvial / Loam', 'Clayey', 'Black Cotton'],
    waterNeeds: 'Moderate',
    icon: '🌾',
  ),
  CropData(
    id: 'rice',
    name: 'Rice / Paddy',
    hindiName: 'धान',
    season: 'Kharif',
    category: 'Cereal',
    seedRatePerAcre: 15.0,
    seedPricePerUnit: 60.0,
    ureaBagsPerAcre: 2.5,
    dapBagsPerAcre: 1.2,
    mopBagsPerAcre: 0.8,
    fymTonsPerAcre: 4.0,
    waterReqMm: 1200,
    durationDays: 140,
    expectedYieldPerAcre: '22 - 28 Quintals',
    suitableSoils: ['Clayey', 'Alluvial / Loam'],
    waterNeeds: 'High',
    icon: '🍚',
  ),
  CropData(
    id: 'maize',
    name: 'Maize / Corn',
    hindiName: 'मक्का',
    season: 'Kharif',
    category: 'Cereal',
    seedRatePerAcre: 8.0,
    seedPricePerUnit: 220.0,
    ureaBagsPerAcre: 2.2,
    dapBagsPerAcre: 1.0,
    mopBagsPerAcre: 0.6,
    fymTonsPerAcre: 3.0,
    waterReqMm: 500,
    durationDays: 105,
    expectedYieldPerAcre: '24 - 30 Quintals',
    suitableSoils: ['Alluvial / Loam', 'Sandy / Red Soil'],
    waterNeeds: 'Moderate',
    icon: '🌽',
  ),
  CropData(
    id: 'cotton',
    name: 'Cotton',
    hindiName: 'कपास',
    season: 'Kharif',
    category: 'Cash',
    seedRatePerAcre: 2.0,
    seedUnit: 'pkts',
    seedPricePerUnit: 850.0,
    ureaBagsPerAcre: 2.4,
    dapBagsPerAcre: 1.2,
    mopBagsPerAcre: 0.8,
    fymTonsPerAcre: 4.5,
    waterReqMm: 700,
    durationDays: 165,
    expectedYieldPerAcre: '10 - 14 Quintals',
    suitableSoils: ['Black Cotton', 'Alluvial / Loam'],
    waterNeeds: 'Moderate',
    icon: '☁️',
  ),
  CropData(
    id: 'soybean',
    name: 'Soybean',
    hindiName: 'सोयाबीन',
    season: 'Kharif',
    category: 'Oilseeds',
    seedRatePerAcre: 30.0,
    seedPricePerUnit: 80.0,
    ureaBagsPerAcre: 0.6,
    dapBagsPerAcre: 1.5,
    mopBagsPerAcre: 0.5,
    fymTonsPerAcre: 3.0,
    waterReqMm: 450,
    durationDays: 100,
    expectedYieldPerAcre: '10 - 13 Quintals',
    suitableSoils: ['Black Cotton', 'Alluvial / Loam'],
    waterNeeds: 'Moderate',
    icon: '🌱',
  ),
  CropData(
    id: 'sugarcane',
    name: 'Sugarcane',
    hindiName: 'गन्ना',
    season: 'Annual',
    category: 'Cash',
    seedRatePerAcre: 3000.0,
    seedPricePerUnit: 3.5,
    ureaBagsPerAcre: 4.0,
    dapBagsPerAcre: 2.0,
    mopBagsPerAcre: 1.5,
    fymTonsPerAcre: 6.0,
    waterReqMm: 1800,
    durationDays: 350,
    expectedYieldPerAcre: '350 - 450 Quintals',
    suitableSoils: ['Alluvial / Loam', 'Clayey', 'Black Cotton'],
    waterNeeds: 'High',
    icon: '🎋',
  ),
  CropData(
    id: 'mustard',
    name: 'Mustard',
    hindiName: 'सरसों',
    season: 'Rabi',
    category: 'Oilseeds',
    seedRatePerAcre: 2.0,
    seedPricePerUnit: 120.0,
    ureaBagsPerAcre: 1.4,
    dapBagsPerAcre: 0.8,
    mopBagsPerAcre: 0.4,
    fymTonsPerAcre: 2.5,
    waterReqMm: 260,
    durationDays: 110,
    expectedYieldPerAcre: '7 - 10 Quintals',
    suitableSoils: ['Alluvial / Loam', 'Sandy / Red Soil'],
    waterNeeds: 'Low',
    icon: '🌼',
  ),
  CropData(
    id: 'gram',
    name: 'Gram / Chickpea',
    hindiName: 'चना',
    season: 'Rabi',
    category: 'Pulses',
    seedRatePerAcre: 32.0,
    seedPricePerUnit: 90.0,
    ureaBagsPerAcre: 0.4,
    dapBagsPerAcre: 1.2,
    mopBagsPerAcre: 0.4,
    fymTonsPerAcre: 2.5,
    waterReqMm: 250,
    durationDays: 105,
    expectedYieldPerAcre: '8 - 11 Quintals',
    suitableSoils: ['Alluvial / Loam', 'Black Cotton'],
    waterNeeds: 'Low',
    icon: '🫘',
  ),
  CropData(
    id: 'potato',
    name: 'Potato',
    hindiName: 'आलू',
    season: 'Rabi',
    category: 'Vegetable',
    seedRatePerAcre: 750.0,
    seedPricePerUnit: 25.0,
    ureaBagsPerAcre: 2.6,
    dapBagsPerAcre: 2.0,
    mopBagsPerAcre: 1.2,
    fymTonsPerAcre: 5.0,
    waterReqMm: 500,
    durationDays: 100,
    expectedYieldPerAcre: '90 - 130 Quintals',
    suitableSoils: ['Alluvial / Loam', 'Sandy / Red Soil'],
    waterNeeds: 'Moderate',
    icon: '🥔',
  ),
  CropData(
    id: 'tomato',
    name: 'Tomato',
    hindiName: 'टमाटर',
    season: 'Zaid',
    category: 'Vegetable',
    seedRatePerAcre: 0.15,
    seedPricePerUnit: 5000.0,
    ureaBagsPerAcre: 2.0,
    dapBagsPerAcre: 1.5,
    mopBagsPerAcre: 1.0,
    fymTonsPerAcre: 4.5,
    waterReqMm: 600,
    durationDays: 120,
    expectedYieldPerAcre: '130 - 190 Quintals',
    suitableSoils: ['Alluvial / Loam', 'Sandy / Red Soil'],
    waterNeeds: 'Moderate',
    icon: '🍅',
  ),
];

class AgriculturePage extends StatefulWidget {
  final FieldRecord? preselectedField;

  const AgriculturePage({
    super.key,
    this.preselectedField,
  });

  @override
  State<AgriculturePage> createState() => _AgriculturePageState();
}

class _AgriculturePageState extends State<AgriculturePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<FieldRecord> _savedFields = [];
  FieldRecord? _selectedField;

  double _areaValue = 2.5;
  String _selectedUnit = 'Acres';
  final TextEditingController _areaController = TextEditingController();

  late CropData _selectedCrop;

  String _selectedSoil = 'Alluvial / Loam';
  String _irrigationType = 'Drip Irrigation';

  final double _ureaBagPrice = 270.0;
  final double _dapBagPrice = 1350.0;
  final double _mopBagPrice = 1700.0;
  final double _fymTonPrice = 600.0;

  String _advisorySeason = 'All';
  String _advisorySoil = 'All';
  String _advisoryWater = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedCrop = kAllCrops.first;

    if (widget.preselectedField != null) {
      _applyField(widget.preselectedField!);
    } else {
      _areaController.text = _areaValue.toStringAsFixed(2);
    }

    _loadSavedFields();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedFields() async {
    try {
      final fields = await FieldStorage.loadFields();
      if (mounted) {
        setState(() {
          _savedFields = fields;
          if (widget.preselectedField != null) {
            final match =
                fields.where((f) => f.id == widget.preselectedField!.id);
            if (match.isNotEmpty) {
              _selectedField = match.first;
            }
          }
        });
      }
    } catch (_) {}
  }

  void _applyField(FieldRecord field) {
    _selectedField = field;
    _areaValue = field.acres;
    _selectedUnit = 'Acres';
    _areaController.text = _areaValue.toStringAsFixed(2);

    if (field.crop.isNotEmpty) {
      final foundCrop = kAllCrops.where(
        (c) => c.name.toLowerCase().contains(field.crop.toLowerCase()),
      );
      if (foundCrop.isNotEmpty) {
        _selectedCrop = foundCrop.first;
      }
    }

    if (field.soilType.isNotEmpty) {
      _selectedSoil = field.soilType;
    }

    if (field.irrigation.isNotEmpty) {
      _irrigationType = field.irrigation;
    }

    setState(() {});
  }

  double get _areaInAcres {
    switch (_selectedUnit) {
      case 'Hectares':
        return _areaValue * 2.47105;
      case 'Sq. Meters':
        return _areaValue / 4046.86;
      case 'Bigha':
        return _areaValue / 1.61;
      case 'Guntha':
        return _areaValue / 40.0;
      case 'Acres':
      default:
        return _areaValue;
    }
  }

  double get _areaInHectares => _areaInAcres * 0.404686;
  double get _areaInSqMeters => _areaInAcres * 4046.86;

  void _onAreaChanged(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed >= 0) {
      setState(() {
        _areaValue = parsed;
      });
    }
  }

  double get _totalSeedsKg => _selectedCrop.seedRatePerAcre * _areaInAcres;
  double get _seedCost => _totalSeedsKg * _selectedCrop.seedPricePerUnit;

  double get _totalUreaBags => _selectedCrop.ureaBagsPerAcre * _areaInAcres;
  double get _ureaCost => _totalUreaBags * _ureaBagPrice;

  double get _totalDapBags => _selectedCrop.dapBagsPerAcre * _areaInAcres;
  double get _dapCost => _totalDapBags * _dapBagPrice;

  double get _totalMopBags => _selectedCrop.mopBagsPerAcre * _areaInAcres;
  double get _mopCost => _totalMopBags * _mopBagPrice;

  double get _totalFymTons => _selectedCrop.fymTonsPerAcre * _areaInAcres;
  double get _fymCost => _totalFymTons * _fymTonPrice;

  double get _totalFertilizerCost => _ureaCost + _dapCost + _mopCost + _fymCost;
  double get _totalEstimatedBudget => _seedCost + _totalFertilizerCost;

  double get _totalWaterM3 =>
      (_selectedCrop.waterReqMm * 4.04686) * _areaInAcres;

  double get _irrigationEfficiencyFactor {
    switch (_irrigationType) {
      case 'Drip Irrigation':
        return 0.55;
      case 'Sprinkler Irrigation':
        return 0.75;
      case 'Flood / Surface':
      default:
        return 1.0;
    }
  }

  double get _actualWaterUsedM3 => _totalWaterM3 * _irrigationEfficiencyFactor;

  // -------------------------------------------------------------
  // FIXED & TYPE-SAFE: SAVE PLAN TO FIELD & SYNC WITH MONGODB BACKEND
  // -------------------------------------------------------------
  Future<void> _savePlanToField() async {
    TextEditingController fieldNameController = TextEditingController(
      text: _selectedField?.name ?? 'Field Plot',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.landscape_rounded, color: Color(0xFF2E7D32)),
            SizedBox(width: 8),
            Expanded(child: Text('Save to My Farmland')),
          ],
        ),
        content: TextField(
          controller: fieldNameController,
          decoration: const InputDecoration(
            labelText: 'Field Name',
            hintText: 'Enter Field Name (e.g., North Field)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final saveData = {
                "id": _selectedField?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                "userEmail": "user@example.com", // Safe fallback string
                "fieldName": fieldNameController.text.trim().isNotEmpty
                    ? fieldNameController.text.trim()
                    : "Field Plot",
                "areaSize": "${_areaInAcres.toStringAsFixed(2)} Acres",
                "areaSqMeters": _areaInSqMeters,
                "measurementType": "Estimator",
                "crop": _selectedCrop.name,
                "season": _selectedCrop.season,
                "irrigation": _irrigationType,
                "soilType": _selectedSoil,
                "totalBudget": _totalEstimatedBudget,
                "seedsCost": _seedCost,
                "fertilizerCost": _totalFertilizerCost,
                "seedRequirements": {
                  "quantityKg": _totalSeedsKg,
                  "ratePerKg": _selectedCrop.seedPricePerUnit
                },
                "fertilizerBreakdown": {
                  "ureaBags": _totalUreaBags,
                  "dapBags": _totalDapBags,
                  "mopBags": _totalMopBags,
                  "manureTons": _totalFymTons
                },
                "notes": "Generated from Agricultural Input Estimator"
              };

              // Send to Backend API and handle response safely
              final response = await ApiService.saveLand(saveData);

              // Safely evaluate success whether saveLand returns a bool or a Map
              bool success = false;
              success = response['success'] == true ||
                  response['status'] == 200 ||
                  response['statusCode'] == 200 ||
                  response.containsKey('_id');
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Field saved successfully! View in "My Farmland" tab.'),
                    backgroundColor: Color(0xFF2E7D32),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                _loadSavedFields();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Failed to save field to server. Please try again.'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _shareReport() {
    final report = '''
========================================
🌾 INTELLIGENT LAND MEASUREMENT - FARM REPORT
========================================
Field Name: ${_selectedField?.name ?? 'Custom Land Plot'}
Measured Area: ${_areaInAcres.toStringAsFixed(2)} Acres (${_areaInHectares.toStringAsFixed(2)} ha / ${_areaInSqMeters.toStringAsFixed(1)} m²)
Soil Type: $_selectedSoil
Irrigation Method: $_irrigationType

CROP DETAILS:
- Crop: ${_selectedCrop.name} (${_selectedCrop.hindiName})
- Season: ${_selectedCrop.season} | Category: ${_selectedCrop.category}
- Duration: ${_selectedCrop.durationDays} Days
- Expected Yield: ${_selectedCrop.expectedYieldPerAcre} / Acre

SEED REQUIREMENTS:
- Total Seeds Needed: ${_totalSeedsKg.toStringAsFixed(1)} ${_selectedCrop.seedUnit}
- Est. Seed Cost: ₹${_seedCost.toStringAsFixed(0)}

FERTILIZER SCHEDULE (NPK):
- Urea (46% N): ${_totalUreaBags.toStringAsFixed(1)} bags (₹${_ureaCost.toStringAsFixed(0)})
- DAP (18-46-0): ${_totalDapBags.toStringAsFixed(1)} bags (₹${_dapCost.toStringAsFixed(0)})
- MOP / Potash: ${_totalMopBags.toStringAsFixed(1)} bags (₹${_mopCost.toStringAsFixed(0)})
- Organic Compost: ${_totalFymTons.toStringAsFixed(1)} Tons (₹${_fymCost.toStringAsFixed(0)})
- Total Fertilizer Budget: ₹${_totalFertilizerCost.toStringAsFixed(0)}

IRRIGATION BUDGET:
- Total Water Consumption: ${_actualWaterUsedM3.toStringAsFixed(0)} m³ (${(_actualWaterUsedM3 / 1000).toStringAsFixed(1)} Lakh Liters)
- Water Saving Method: $_irrigationType

TOTAL ESTIMATED INPUT BUDGET: ₹${_totalEstimatedBudget.toStringAsFixed(0)}
========================================
Generated by Intelligent Land Measurement App
''';

    Clipboard.setData(ClipboardData(text: report));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
            SizedBox(width: 8),
            Text('Farm Plan Report'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              report,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copy to Clipboard'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: report));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report copied to clipboard!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text(
          'Agriculture & Farm Tools',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B1B1B),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Share / View Report',
            icon: const Icon(Icons.receipt_long_rounded, color: primaryColor),
            onPressed: _shareReport,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: primaryColor,
          indicatorWeight: 3,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.calculate_outlined), text: 'Input Estimator'),
            Tab(icon: Icon(Icons.water_drop_outlined), text: 'Irrigation'),
            Tab(icon: Icon(Icons.eco_outlined), text: 'Crop Advisory'),
            Tab(icon: Icon(Icons.map_outlined), text: 'My Farmland'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInputEstimatorTab(),
          _buildIrrigationTab(),
          _buildCropAdvisoryTab(),
          _buildFarmlandTab(),
        ],
      ),
    );
  }

  Widget _buildInputEstimatorTab() {
    const primaryColor = Color(0xFF2E7D32);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLandAreaSelectorCard(),
          const SizedBox(height: 16),
          _buildCropSelectorCard(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Estimated Budget',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_areaInAcres.toStringAsFixed(2)} Acres',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '₹ ${_totalEstimatedBudget.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Seeds Cost',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text('₹ ${_seedCost.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fertilizers Cost',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text('₹ ${_totalFertilizerCost.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Est. Yield',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(
                            '${_selectedCrop.expectedYieldPerAcre.split(' ').first} Q/ac',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Seed Requirements', Icons.grass_rounded),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8E4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(_selectedCrop.icon,
                        style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_selectedCrop.name} (${_selectedCrop.hindiName}) Seeds',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seed Rate: ${_selectedCrop.seedRatePerAcre} ${_selectedCrop.seedUnit}/acre • ₹${_selectedCrop.seedPricePerUnit}/${_selectedCrop.seedUnit}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_totalSeedsKg.toStringAsFixed(1)} ${_selectedCrop.seedUnit}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor),
                    ),
                    Text('₹${_seedCost.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(
              'Fertilizer Requirements (NPK & Organic)', Icons.science_rounded),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8E4)),
            ),
            child: Column(
              children: [
                _fertilizerItem(
                  title: 'Urea (Nitrogen 46% N)',
                  subtitle: 'Basal & top dressing for foliage growth',
                  bagsText: '${_totalUreaBags.toStringAsFixed(1)} Bags (50kg)',
                  costText: '₹${_ureaCost.toStringAsFixed(0)}',
                  badgeColor: Colors.blue.shade100,
                  badgeTextColor: Colors.blue.shade900,
                  tag: 'N',
                ),
                const Divider(height: 20),
                _fertilizerItem(
                  title: 'D.A.P (Phosphorus 18:46:0)',
                  subtitle: 'Root development & early vigor',
                  bagsText: '${_totalDapBags.toStringAsFixed(1)} Bags (50kg)',
                  costText: '₹${_dapCost.toStringAsFixed(0)}',
                  badgeColor: Colors.purple.shade100,
                  badgeTextColor: Colors.purple.shade900,
                  tag: 'P',
                ),
                const Divider(height: 20),
                _fertilizerItem(
                  title: 'MOP / Potash (Potassium 60% K₂O)',
                  subtitle: 'Disease resistance & grain filling',
                  bagsText: '${_totalMopBags.toStringAsFixed(1)} Bags (50kg)',
                  costText: '₹${_mopCost.toStringAsFixed(0)}',
                  badgeColor: Colors.amber.shade100,
                  badgeTextColor: Colors.amber.shade900,
                  tag: 'K',
                ),
                const Divider(height: 20),
                _fertilizerItem(
                  title: 'Farm Yard Manure / Compost',
                  subtitle: 'Organic matter to improve soil fertility',
                  bagsText: '${_totalFymTons.toStringAsFixed(1)} Tons',
                  costText: '₹${_fymCost.toStringAsFixed(0)}',
                  badgeColor: Colors.brown.shade100,
                  badgeTextColor: Colors.brown.shade900,
                  tag: 'Bio',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareReport,
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Export Report'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: const BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _savePlanToField,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save to Field'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildIrrigationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0277BD), Color(0xFF0091EA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Water Budget',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_selectedCrop.waterNeeds} Need',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_actualWaterUsedM3.toStringAsFixed(0)} m³',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Approx. ${(_actualWaterUsedM3 / 1000).toStringAsFixed(1)} Lakh Liters for ${_areaInAcres.toStringAsFixed(2)} acres',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(
              'Irrigation Method Comparison', Icons.water_drop_rounded),
          const SizedBox(height: 8),
          _irrigationMethodCard(
            title: 'Drip Irrigation (Recommended)',
            description:
                'Direct root zone watering. Saves up to 45% water & boosts yield.',
            waterUsedM3: _totalWaterM3 * 0.55,
            savingsText: '45% Water Saved',
            savingsColor: Colors.green,
            methodName: 'Drip Irrigation',
          ),
          const SizedBox(height: 10),
          _irrigationMethodCard(
            title: 'Sprinkler Irrigation',
            description:
                'Simulates natural rainfall. Excellent for wheat & undulating terrain.',
            waterUsedM3: _totalWaterM3 * 0.75,
            savingsText: '25% Water Saved',
            savingsColor: Colors.blue,
            methodName: 'Sprinkler Irrigation',
          ),
          const SizedBox(height: 10),
          _irrigationMethodCard(
            title: 'Flood / Furrow Irrigation',
            description:
                'Traditional surface flooding. Highest water loss through runoff & evaporation.',
            waterUsedM3: _totalWaterM3,
            savingsText: 'Standard Baseline',
            savingsColor: Colors.orange,
            methodName: 'Flood / Surface',
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(
              'Soil Retention & Schedule', Icons.terrain_rounded),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8E4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey('soil_$_selectedSoil'),
                  initialValue: _selectedSoil,
                  decoration: const InputDecoration(
                    labelText: 'Soil Type',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'Alluvial / Loam',
                        child: Text('Alluvial / Loam Soil (Balanced)')),
                    DropdownMenuItem(
                        value: 'Black Cotton',
                        child: Text('Black Cotton Soil (High Retention)')),
                    DropdownMenuItem(
                        value: 'Clayey', child: Text('Clayey Soil (Heavy)')),
                    DropdownMenuItem(
                        value: 'Sandy / Red Soil',
                        child: Text('Sandy / Red Soil (Fast Drainage)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSoil = val);
                  },
                ),
                const SizedBox(height: 16),
                _soilAdviceTile(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(
              'Critical Watering Stages for ${_selectedCrop.name}',
              Icons.calendar_month_rounded),
          const SizedBox(height: 8),
          _buildWateringScheduleList(),
        ],
      ),
    );
  }

  Widget _irrigationMethodCard({
    required String title,
    required String description,
    required double waterUsedM3,
    required String savingsText,
    required Color savingsColor,
    required String methodName,
  }) {
    final isSelected = _irrigationType == methodName;

    return InkWell(
      onTap: () {
        setState(() {
          _irrigationType = methodName;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF2E7D32) : const Color(0xFFE2E8E4),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF2E7D32) : Colors.grey,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isSelected
                                ? const Color(0xFF2E7D32)
                                : Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: savingsColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          savingsText,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: savingsColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(description,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 6),
                  Text(
                    'Water: ${waterUsedM3.toStringAsFixed(0)} m³ (${(waterUsedM3 / 1000).toStringAsFixed(1)} L Lakhs)',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _soilAdviceTile() {
    String advice = '';
    String frequency = '';
    switch (_selectedSoil) {
      case 'Black Cotton':
        advice =
            'High clay content retains moisture longer. Avoid waterlogging to prevent root rot.';
        frequency = 'Every 10 - 14 days';
        break;
      case 'Sandy / Red Soil':
        advice =
            'Water drains rapidly. Requires lighter, more frequent waterings. Drip is strongly advised.';
        frequency = 'Every 4 - 6 days';
        break;
      case 'Clayey':
        advice =
            'Slow infiltration. Allow sufficient interval between irrigations to maintain aeration.';
        frequency = 'Every 12 - 15 days';
        break;
      case 'Alluvial / Loam':
      default:
        advice =
            'Optimal water holding capacity and drainage. Ideal for standard irrigation schedules.';
        frequency = 'Every 7 - 10 days';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 18, color: Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Text(
                'Watering Frequency: $frequency',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                    fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(advice,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
        ],
      ),
    );
  }

  Widget _buildWateringScheduleList() {
    final stages = [
      {
        'stage': '1. Germination / Sowing',
        'time': 'Day 0 - 15',
        'need': 'Light Moisture'
      },
      {
        'stage': '2. Vegetative / Tillering',
        'time': 'Day 20 - 45',
        'need': 'Moderate Moisture'
      },
      {
        'stage': '3. Flowering / Heading',
        'time': 'Day 50 - 75',
        'need': 'CRITICAL (Do not stress)'
      },
      {
        'stage': '4. Grain / Fruit Formation',
        'time': 'Day 80 - 105',
        'need': 'Adequate Moisture'
      },
      {
        'stage': '5. Maturity / Ripening',
        'time': '10 days before harvest',
        'need': 'Stop Irrigation'
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8E4)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: stages.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final s = stages[i];
          final isCritical = s['need']!.contains('CRITICAL');
          return ListTile(
            leading: CircleAvatar(
              radius: 16,
              backgroundColor:
                  isCritical ? Colors.red.shade50 : const Color(0xFFE8F5E9),
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCritical
                      ? Colors.red.shade800
                      : const Color(0xFF2E7D32),
                ),
              ),
            ),
            title: Text(
              s['stage']!,
              style: TextStyle(
                  fontWeight: isCritical ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14),
            ),
            subtitle: Text(s['time']!, style: const TextStyle(fontSize: 12)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCritical ? Colors.red.shade100 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                s['need']!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color:
                      isCritical ? Colors.red.shade900 : Colors.blue.shade800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCropAdvisoryTab() {
    const primaryColor = Color(0xFF2E7D32);

    final filteredCrops = kAllCrops.where((c) {
      if (_advisorySeason != 'All' &&
          c.season != _advisorySeason &&
          c.season != 'Annual') {
        return false;
      }
      if (_advisorySoil != 'All' && !c.suitableSoils.contains(_advisorySoil)) {
        return false;
      }
      if (_advisoryWater != 'All' && c.waterNeeds != _advisoryWater) {
        return false;
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8E4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Find Optimal Crops for Your Land',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.4 - 24,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('season_$_advisorySeason'),
                        initialValue: _advisorySeason,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Season',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'All', child: Text('All Seasons')),
                          DropdownMenuItem(
                              value: 'Kharif', child: Text('Kharif')),
                          DropdownMenuItem(value: 'Rabi', child: Text('Rabi')),
                          DropdownMenuItem(value: 'Zaid', child: Text('Zaid')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _advisorySeason = val);
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.35 - 24,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('advisory_soil_$_advisorySoil'),
                        initialValue: _advisorySoil,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Soil Type',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'All', child: Text('All Soils')),
                          DropdownMenuItem(
                              value: 'Alluvial / Loam',
                              child: Text('Sandy/Loam')),
                          DropdownMenuItem(
                              value: 'Black Cotton', child: Text('Black')),
                          DropdownMenuItem(
                              value: 'Clayey', child: Text('Clayey')),
                          DropdownMenuItem(
                              value: 'Sandy / Red Soil',
                              child: Text('Sandy/Red')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _advisorySoil = val);
                        },
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.25 - 8,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('water_$_advisoryWater'),
                        initialValue: _advisoryWater,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Water',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('Any')),
                          DropdownMenuItem(value: 'Low', child: Text('Low')),
                          DropdownMenuItem(
                              value: 'Moderate', child: Text('Moderate')),
                          DropdownMenuItem(value: 'High', child: Text('High')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _advisoryWater = val);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Recommended Crops (${filteredCrops.length} Matches)',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (filteredCrops.isEmpty)
            Container(
              padding: const EdgeInsets.all(30),
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Column(
                children: [
                  const Icon(Icons.search_off_rounded,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('No crops match your exact filters.',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Try selecting "All Seasons" or "Any Water".',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredCrops.length,
              itemBuilder: (ctx, i) {
                final crop = filteredCrops[i];
                final isSelected = crop.id == _selectedCrop.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color:
                          isSelected ? primaryColor : const Color(0xFFE2E8E4),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                          child: Text(crop.icon,
                              style: const TextStyle(fontSize: 26))),
                    ),
                    title: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                              text: crop.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          TextSpan(
                              text: '  (${crop.hindiName})',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Season: ${crop.season} • Duration: ${crop.durationDays} Days • Yield: ${crop.expectedYieldPerAcre}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _badge(crop.season, Colors.green),
                            _badge('${crop.waterNeeds} Water', Colors.blue),
                            _badge(crop.category, Colors.orange),
                          ],
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedCrop = crop;
                        });
                        _tabController.animateTo(0);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isSelected ? primaryColor : Colors.grey.shade100,
                        foregroundColor:
                            isSelected ? Colors.white : Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(isSelected ? 'Selected' : 'Use Crop'),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFarmlandTab() {
    const primaryColor = Color(0xFF2E7D32);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Saved Fields',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${_savedFields.length} Registered Plots',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          if (_savedFields.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8E4)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.landscape_outlined,
                      size: 50, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('No saved fields found yet',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(
                    'Use GPS Measurement or Camera Measurement on the dashboard to measure and save your fields.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _savedFields.length,
              itemBuilder: (ctx, i) {
                final field = _savedFields[i];
                final isSelected = _selectedField?.id == field.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color:
                          isSelected ? primaryColor : const Color(0xFFE2E8E4),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.terrain_rounded,
                          color: primaryColor),
                    ),
                    title: Text(
                      field.name.isEmpty ? 'Field #${i + 1}' : field.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${field.acres.toStringAsFixed(2)} Acres • ${field.hectares.toStringAsFixed(2)} ha • ${field.areaSqMeters.toStringAsFixed(0)} m²',
                          style: TextStyle(
                              color: Colors.grey.shade700, fontSize: 12),
                        ),
                        if (field.crop.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Active Crop: ${field.crop} • Soil: ${field.soilType.isEmpty ? 'Standard' : field.soilType}',
                            style: const TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        _applyField(field);
                        _tabController.animateTo(0);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isSelected ? primaryColor : Colors.grey.shade100,
                        foregroundColor:
                            isSelected ? Colors.white : Colors.black87,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(isSelected ? 'Active' : 'Load Area'),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLandAreaSelectorCard() {
    const primaryColor = Color(0xFF2E7D32);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.straighten_rounded, color: primaryColor, size: 22),
                  SizedBox(width: 8),
                  Text('Field Area',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              if (_selectedField != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Linked: ${_selectedField!.name}',
                    style: const TextStyle(
                        color: primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _areaController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Enter Area',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: _onAreaChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('unit_$_selectedUnit'),
                  initialValue: _selectedUnit,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Acres', child: Text('Acres')),
                    DropdownMenuItem(
                        value: 'Hectares', child: Text('Hectares')),
                    DropdownMenuItem(value: 'Sq. Meters', child: Text('m²')),
                    DropdownMenuItem(value: 'Bigha', child: Text('Bigha')),
                    DropdownMenuItem(value: 'Guntha', child: Text('Guntha')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedUnit = val;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _unitChip('1 Acre', () => _setQuickArea(1.0, 'Acres')),
              const SizedBox(width: 6),
              _unitChip('2.5 Acres', () => _setQuickArea(2.5, 'Acres')),
              const SizedBox(width: 6),
              _unitChip('5 Acres', () => _setQuickArea(5.0, 'Acres')),
              const SizedBox(width: 6),
              _unitChip('1 Hectare', () => _setQuickArea(1.0, 'Hectares')),
            ],
          ),
        ],
      ),
    );
  }

  void _setQuickArea(double val, String unit) {
    setState(() {
      _areaValue = val;
      _selectedUnit = unit;
      _areaController.text = val.toString();
    });
  }

  Widget _unitChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4F2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
      ),
    );
  }

  Widget _buildCropSelectorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Select Crop',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                '${_selectedCrop.season} Season',
                style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<CropData>(
            key: ValueKey('crop_${_selectedCrop.id}'),
            initialValue: _selectedCrop,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: kAllCrops.map((crop) {
              return DropdownMenuItem<CropData>(
                value: crop,
                child: Row(
                  children: [
                    Text(crop.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Text('${crop.name} (${crop.hindiName})'),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedCrop = val;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B1B1B))),
      ],
    );
  }

  Widget _fertilizerItem({
    required String title,
    required String subtitle,
    required String bagsText,
    required String costText,
    required Color badgeColor,
    required Color badgeTextColor,
    required String tag,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: badgeColor, borderRadius: BorderRadius.circular(12)),
          child: Center(
            child: Text(tag,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: badgeTextColor,
                    fontSize: 14)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(bagsText,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF2E7D32))),
            const SizedBox(height: 2),
            Text(costText,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
