import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'field_details_page.dart';
import 'field_storage.dart';
import 'gps_measurement_page.dart';

class MyFieldsPage extends StatefulWidget {
  const MyFieldsPage({super.key});

  @override
  State<MyFieldsPage> createState() => _MyFieldsPageState();
}

class _MyFieldsPageState extends State<MyFieldsPage> {
  static const Color primaryGreen = Color(0xFF2E7D32);

  List<FieldRecord> _fields = [];
  bool _isLoading = true;
  bool? _isDbConnected;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields({bool syncWithDb = true}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbStatus = await ApiService.checkConnection();
      final fields = await FieldStorage.loadFields(syncWithDb: syncWithDb);

      if (!mounted) return;
      setState(() {
        _fields = fields;
        _isDbConnected = dbStatus;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load saved fields: $e')),
      );
    }
  }

  Future<void> _openField(FieldRecord field) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FieldDetailsPage(field: field),
      ),
    );

    // Reload in case the field was edited or deleted.
    await _loadFields(syncWithDb: false);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formatArea(FieldRecord field) {
    if (field.areaSqMeters < 10000) {
      return '${field.areaSqMeters.toStringAsFixed(1)} m²';
    }
    return '${field.hectares.toStringAsFixed(2)} ha';
  }

  List<FieldRecord> get _filteredFields {
    if (_searchQuery.trim().isEmpty) return _fields;
    return _fields
        .where((f) =>
            f.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            f.crop.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _filteredFields;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text(
          'My Saved Fields',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (_isDbConnected == true) ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (_isDbConnected == true) ? Colors.green.shade300 : Colors.orange.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  (_isDbConnected == true) ? Icons.cloud_done : Icons.cloud_off,
                  size: 14,
                  color: (_isDbConnected == true) ? primaryGreen : Colors.orange.shade800,
                ),
                const SizedBox(width: 4),
                Text(
                  (_isDbConnected == true) ? 'MongoDB' : 'Local',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: (_isDbConnected == true) ? primaryGreen : Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadFields(syncWithDb: true),
            tooltip: 'Sync with MongoDB',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GPSMeasurementPage()),
          ).then((_) => _loadFields(syncWithDb: true));
        },
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Measure Field'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadFields(syncWithDb: true),
        child: SafeArea(
          child: Column(
            children: [
              // Search Bar
              if (_fields.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search fields by name or crop...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : displayList.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: displayList.length,
                            itemBuilder: (context, index) {
                              return _buildFieldCard(displayList[index]);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.landscape_rounded,
                size: 42,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Saved Fields Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Measure a plot using GPS or Camera measurement and save it.\nAll measurements will sync directly with MongoDB Compass.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GPSMeasurementPage()),
                ).then((_) => _loadFields(syncWithDb: true));
              },
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Start GPS Measurement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldCard(FieldRecord field) {
    return InkWell(
      onTap: () => _openField(field),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
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
              child: const Icon(
                Icons.landscape,
                color: primaryGreen,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.name.isEmpty ? 'Unnamed Field' : field.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B1B1B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(field.measuredAt),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      if (field.crop.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            field.crop,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatArea(field),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                Text(
                  '${field.acres.toStringAsFixed(2)} acres',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios, size: 13, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
