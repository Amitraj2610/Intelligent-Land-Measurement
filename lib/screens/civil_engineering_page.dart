import 'package:flutter/material.dart';

class CivilEngineeringPage extends StatefulWidget {
  const CivilEngineeringPage({super.key});

  @override
  State<CivilEngineeringPage> createState() => _CivilEngineeringPageState();
}

class _CivilEngineeringPageState extends State<CivilEngineeringPage> {
  final _formKey = GlobalKey<FormState>();

  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _thicknessController = TextEditingController(text: '0.15');
  final _rateController = TextEditingController(text: '150');

  String _unit = 'Meters';
  bool _showResult = false;

  double _areaSqM = 0;
  double _perimeterM = 0;
  double _concreteVolume = 0;
  double _cementBags = 0;
  double _sandVolume = 0;
  double _aggregateVolume = 0;
  double _estimatedCost = 0;

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _thicknessController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final length = double.parse(_lengthController.text);
    final width = double.parse(_widthController.text);
    final thickness = double.parse(_thicknessController.text);
    final rate = double.parse(_rateController.text);

    // Convert input dimensions into meters.
    final factor = _unit == 'Feet' ? 0.3048 : 1.0;
    final lengthM = length * factor;
    final widthM = width * factor;

    final area = lengthM * widthM;
    final perimeter = 2 * (lengthM + widthM);

    // Approximate RCC slab material estimation.
    final volume = area * thickness;
    final dryVolume = volume * 1.54;

    // Illustrative nominal 1:2:4 mix assumptions.
    final cementVolume = dryVolume * (1 / 7);
    final sand = dryVolume * (2 / 7);
    final aggregate = dryVolume * (4 / 7);

    // Approximate 50 kg cement bag volume = 0.0347 m3.
    final bags = cementVolume / 0.0347;

    final areaSqFt = area * 10.7639104167;

    setState(() {
      _areaSqM = area;
      _perimeterM = perimeter;
      _concreteVolume = volume;
      _cementBags = bags;
      _sandVolume = sand;
      _aggregateVolume = aggregate;
      _estimatedCost = areaSqFt * rate;
      _showResult = true;
    });
  }

  String _format(double value) => value.toStringAsFixed(2);

  Widget _resultCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Colors.teal, size: 30),
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _numberField(
    String label,
    TextEditingController controller, {
    String suffix = '',
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix.isEmpty ? null : suffix,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final number = double.tryParse(value ?? '');
        if (number == null || number <= 0) {
          return 'Enter a number greater than zero';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Civil Engineering'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.architecture,
                size: 64,
                color: Colors.teal,
              ),
              const SizedBox(height: 12),
              const Text(
                'Construction Plot Calculator',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter plot dimensions and slab thickness '
                'to estimate area, perimeter and materials.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _unit,
                decoration: const InputDecoration(
                  labelText: 'Dimension unit',
                  border: OutlineInputBorder(),
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
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _unit = value;
                      _showResult = false;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              _numberField(
                'Plot length',
                _lengthController,
                suffix: _unit == 'Feet' ? 'ft' : 'm',
              ),
              const SizedBox(height: 16),
              _numberField(
                'Plot width',
                _widthController,
                suffix: _unit == 'Feet' ? 'ft' : 'm',
              ),
              const SizedBox(height: 16),
              _numberField(
                'Slab thickness',
                _thicknessController,
                suffix: 'm',
              ),
              const SizedBox(height: 16),
              _numberField(
                'Construction rate per sq ft',
                _rateController,
                suffix: '₹',
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate),
                label: const Text('Calculate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              if (_showResult) ...[
                const SizedBox(height: 24),
                const Text(
                  'Measurement Results',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _resultCard(
                  'Area',
                  '${_format(_areaSqM)} m²',
                  Icons.crop_square,
                ),
                _resultCard(
                  'Area in square feet',
                  '${_format(_areaSqM * 10.7639104167)} ft²',
                  Icons.square_foot,
                ),
                _resultCard(
                  'Area in acres',
                  '${_format(_areaSqM / 4046.8564224)} acres',
                  Icons.landscape,
                ),
                _resultCard(
                  'Area in hectares',
                  '${_format(_areaSqM / 10000)} hectares',
                  Icons.map,
                ),
                _resultCard(
                  'Perimeter',
                  '${_format(_perimeterM)} meters',
                  Icons.straighten,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Approximate Slab Estimate',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _resultCard(
                  'Concrete volume',
                  '${_format(_concreteVolume)} m³',
                  Icons.foundation,
                ),
                _resultCard(
                  'Cement',
                  '${_format(_cementBags)} bags (50 kg)',
                  Icons.inventory_2,
                ),
                _resultCard(
                  'Sand',
                  '${_format(_sandVolume)} m³',
                  Icons.grain,
                ),
                _resultCard(
                  'Coarse aggregate',
                  '${_format(_aggregateVolume)} m³',
                  Icons.construction,
                ),
                _resultCard(
                  'Estimated plot-based cost',
                  '₹${_format(_estimatedCost)}',
                  Icons.currency_rupee,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Note: Material quantities use an illustrative '
                  '1:2:4 nominal mix and a 1.54 dry-volume '
                  'factor. Verify the mix design, structural '
                  'requirements, wastage and local prices with '
                  'a qualified civil engineer. The cost is based '
                  'only on plot area and the entered rate; it is '
                  'not a complete construction quotation.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
