import 'package:flutter/material.dart';

import 'agriculture_page.dart';
import 'field_storage.dart';

class FieldDetailsPage extends StatefulWidget {
  final FieldRecord field;

  const FieldDetailsPage({
    super.key,
    required this.field,
  });

  @override
  State<FieldDetailsPage> createState() => _FieldDetailsPageState();
}

class _FieldDetailsPageState extends State<FieldDetailsPage> {
  late FieldRecord _currentField;

  @override
  void initState() {
    super.initState();
    _currentField = widget.field;
  }

  Future<void> _deleteField() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Field'),
        content: const Text('Are you sure you want to delete this field record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FieldStorage.deleteField(_currentField.id);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentField.name.isEmpty ? 'Field Details' : _currentField.name),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteField,
            tooltip: 'Delete Field',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.landscape, color: Color(0xFF2E7D32), size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _currentField.name.isEmpty ? 'Unnamed Field' : _currentField.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _infoRow('Area (m²)', '${_currentField.areaSqMeters.toStringAsFixed(2)} m²'),
                  _infoRow('Acres', '${_currentField.acres.toStringAsFixed(2)} acres'),
                  _infoRow('Hectares', '${_currentField.hectares.toStringAsFixed(2)} ha'),
                  _infoRow('Square Feet', '${_currentField.sqFeet.toStringAsFixed(2)} sq ft'),
                  _infoRow('Measured Date', _formatDate(_currentField.measuredAt)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Farming Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(height: 20),
                  _infoRow('Crop', _currentField.crop.isEmpty ? 'Not specified' : _currentField.crop),
                  _infoRow('Season', _currentField.season.isEmpty ? 'Not specified' : _currentField.season),
                  _infoRow('Irrigation', _currentField.irrigation.isEmpty ? 'Not specified' : _currentField.irrigation),
                  _infoRow('Soil Type', _currentField.soilType.isEmpty ? 'Not specified' : _currentField.soilType),
                  if (_currentField.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(_currentField.notes),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Boundary Points', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${_currentField.boundary.length} GPS boundary points stored.'),
                  const SizedBox(height: 8),
                  Text(
                    'Center Location: ${_currentField.latitude.toStringAsFixed(6)}, ${_currentField.longitude.toStringAsFixed(6)}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AgriculturePage(preselectedField: _currentField),
                ),
              );
              final fields = await FieldStorage.loadFields();
              final updated = fields.where((f) => f.id == _currentField.id);
              if (updated.isNotEmpty && mounted) {
                setState(() {
                  _currentField = updated.first;
                });
              }
            },
            icon: const Icon(Icons.agriculture_rounded),
            label: const Text('Calculate Seeds, Fertilizers & Water'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
