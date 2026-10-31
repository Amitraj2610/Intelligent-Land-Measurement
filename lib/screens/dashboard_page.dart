import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'agriculture_page.dart';
import 'camera_measurement.dart';
import 'civil_engineering_page.dart';
import 'field_details_page.dart';
import 'field_storage.dart';
import 'gps_measurement_page.dart';
import 'land_measurement.dart';
import 'login_page.dart';
import 'my_fields_page.dart';

class DashboardPage extends StatefulWidget {
  final String userName;

  const DashboardPage({
    super.key,
    this.userName = 'User',
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color backgroundColor = Color(0xFFF5F7F6);

  int selectedIndex = 0;
  List<FieldRecord> _recentFields = [];
  bool _isLoadingFields = false;
  bool? _isDbConnected;
  String _displayName = 'User';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadRecentFields();
    _checkDbStatus();
  }

  Future<void> _loadUserInfo() async {
    final name = await AuthService.getCurrentName();
    final email = await AuthService.getCurrentEmail();
    if (mounted) {
      setState(() {
        _displayName = name.isNotEmpty ? name : widget.userName;
        _userEmail = email;
      });
    }
  }

  Future<void> _checkDbStatus() async {
    final connected = await ApiService.checkConnection();
    if (mounted) {
      setState(() {
        _isDbConnected = connected;
      });
    }
  }

  Future<void> _loadRecentFields() async {
    if (_isLoadingFields) return;
    setState(() {
      _isLoadingFields = true;
    });

    try {
      final fields = await FieldStorage.loadFields(syncWithDb: true);
      if (mounted) {
        setState(() {
          _recentFields = fields;
          _isLoadingFields = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingFields = false;
        });
      }
    }
  }

  void openManualMeasurement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LandMeasurementPage()),
    ).then((_) => _loadRecentFields());
  }

  void openCameraMeasurement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraMeasurementPage()),
    ).then((_) => _loadRecentFields());
  }

  void openGPSMeasurement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GPSMeasurementPage()),
    ).then((_) => _loadRecentFields());
  }

  void _showDatabaseDetailsDialog() {
    final controller = TextEditingController();
    ApiService.getBaseUrl().then((val) => controller.text = val);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.storage, color: primaryGreen),
            SizedBox(width: 8),
            Text('MongoDB Connection'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_isDbConnected == true) ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (_isDbConnected == true) ? Colors.green.shade200 : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      (_isDbConnected == true) ? Icons.check_circle : Icons.error,
                      color: (_isDbConnected == true) ? primaryGreen : Colors.red,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        (_isDbConnected == true)
                            ? 'Connected to MongoDB Compass!\nDatabase: intelligent_land_measurement'
                            : 'Database Offline or Unreachable.\nStart server with start_backend.bat',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: (_isDbConnected == true) ? primaryGreen : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Backend Host URL:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '• Emulator: http://10.0.2.2:5000\n'
                '• Local PC: http://127.0.0.1:5000\n'
                '• Wi-Fi Device: http://192.168.1.4:5000\n'
                '• Cloud DB: MongoDB Atlas',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ApiService.setCustomBaseUrl(null);
              if (ctx.mounted) Navigator.pop(ctx);
              _checkDbStatus();
              _loadRecentFields();
            },
            child: const Text('Reset Auto'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ApiService.setCustomBaseUrl(controller.text);
              if (ctx.mounted) Navigator.pop(ctx);
              _checkDbStatus();
              _loadRecentFields();
            },
            child: const Text('Save & Reconnect'),
          ),
        ],
      ),
    );
  }

  Future<void> logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Intelligent Land Measurement',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        actions: [
          // Database status indicator in AppBar
          GestureDetector(
            onTap: _showDatabaseDetailsDialog,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (_isDbConnected == true) ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (_isDbConnected == true) ? Colors.green.shade300 : Colors.orange.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    (_isDbConnected == true) ? Icons.cloud_done : Icons.cloud_off,
                    size: 15,
                    color: (_isDbConnected == true) ? primaryGreen : Colors.orange.shade800,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    (_isDbConnected == true) ? 'MongoDB' : 'Offline',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: (_isDbConnected == true) ? primaryGreen : Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => _loadRecentFields(),
            tooltip: 'Refresh & Sync with MongoDB',
            icon: const Icon(Icons.sync, color: Colors.black87),
          ),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          _buildHomePage(),
          _buildToolsPage(),
          const MyFieldsPage(),
          _buildProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
          if (index == 0 || index == 2) {
            _loadRecentFields();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'Tools',
          ),
          NavigationDestination(
            icon: Icon(Icons.landscape_outlined),
            selectedIcon: Icon(Icons.landscape),
            label: 'My Fields',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return RefreshIndicator(
      onRefresh: () async {
        await _checkDbStatus();
        await _loadRecentFields();
      },
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Welcome, $_displayName 👋',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _showDatabaseDetailsDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.storage, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'MongoDB',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _userEmail.isNotEmpty ? _userEmail : 'Smart Area Surveying & Field Database',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildQuickStat(
                          '${_recentFields.length}',
                          'Saved Fields',
                          Icons.grid_view,
                        ),
                        const SizedBox(width: 12),
                        _buildQuickStat(
                          (_isDbConnected == true) ? 'Connected' : 'Offline',
                          'Database',
                          Icons.dns,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Measurement & Survey Methods Header
              const Text(
                'Survey & Measure',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // 4 Distinct Cards (GPS, Camera, Manual, Agriculture)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _FeatureCard(
                    icon: Icons.location_on_rounded,
                    title: 'GPS Survey',
                    subtitle: 'Walk or tap map boundary',
                    color: Colors.blue.shade700,
                    onTap: openGPSMeasurement,
                  ),
                  _FeatureCard(
                    icon: Icons.camera_alt_rounded,
                    title: 'Camera AR',
                    subtitle: 'Measure area from photo',
                    color: primaryGreen,
                    onTap: openCameraMeasurement,
                  ),
                  _FeatureCard(
                    icon: Icons.straighten_rounded,
                    title: 'Manual Calc',
                    subtitle: 'Length × width formulas',
                    color: Colors.orange.shade700,
                    onTap: openManualMeasurement,
                  ),
                  _FeatureCard(
                    icon: Icons.agriculture_rounded,
                    title: 'Agriculture',
                    subtitle: 'Seeds, fertilizer & water',
                    color: Colors.teal.shade700,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AgriculturePage()),
                      ).then((_) => _loadRecentFields());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Civil Engineering Banner
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CivilEngineeringPage()),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.indigo.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.engineering_rounded, color: Colors.indigo, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Civil Engineering Tools',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'RCC concrete slab material & cost calculator',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Live Recent Measurements from MongoDB
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Measurements',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_recentFields.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectedIndex = 2; // Switch to My Fields tab
                        });
                      },
                      child: Text(
                        'View All (${_recentFields.length})',
                        style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              if (_isLoadingFields)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_recentFields.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.landscape_outlined, size: 42, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      const Text(
                        'No measurements recorded yet',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Measure a field using GPS or Camera, then save it.\nIt will sync directly with MongoDB Compass.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: openGPSMeasurement,
                        icon: const Icon(Icons.add_location_alt, size: 18),
                        label: const Text('Measure with GPS'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentFields.length > 3 ? 3 : _recentFields.length,
                  itemBuilder: (context, index) {
                    final field = _recentFields[index];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: primaryGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.landscape, color: primaryGreen),
                        ),
                        title: Text(
                          field.name.isNotEmpty ? field.name : 'Field Plot',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${field.areaSqMeters.toStringAsFixed(1)} m² • ${field.acres.toStringAsFixed(2)} acres',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FieldDetailsPage(field: field),
                            ),
                          ).then((_) => _loadRecentFields());
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsPage() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Land Measurement Tools',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Select the survey method for your land project.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _LargeMeasurementCard(
            icon: Icons.location_on_rounded,
            title: 'GPS Boundary Survey',
            description: 'Walk the perimeter or tap GPS coordinates on OpenStreetMap. Real-time Shoelace geodesic area calculation.',
            color: Colors.blue.shade700,
            onTap: openGPSMeasurement,
          ),
          const SizedBox(height: 12),
          _LargeMeasurementCard(
            icon: Icons.camera_alt_rounded,
            title: 'Camera AR Measurement',
            description: 'Snap or import a plot photo, set reference scale, and compute square footage directly.',
            color: primaryGreen,
            onTap: openCameraMeasurement,
          ),
          const SizedBox(height: 12),
          _LargeMeasurementCard(
            icon: Icons.straighten_rounded,
            title: 'Manual Area Calculator',
            description: 'Enter length and width with instant unit conversion (Meters, Feet, Yards, Acres, Hectares).',
            color: Colors.orange.shade700,
            onTap: openManualMeasurement,
          ),
          const SizedBox(height: 12),
          _LargeMeasurementCard(
            icon: Icons.agriculture_rounded,
            title: 'Agricultural Farm Planner',
            description: 'Calculate crop seeds, N-P-K fertilizer recommendations, and irrigation requirements for your fields.',
            color: Colors.teal.shade700,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AgriculturePage()),
              );
            },
          ),
          const SizedBox(height: 12),
          _LargeMeasurementCard(
            icon: Icons.engineering_rounded,
            title: 'Civil RCC Slab Calculator',
            description: 'Calculate concrete volume, cement bags, sand, aggregate, and cost estimation.',
            color: Colors.indigo,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CivilEngineeringPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: primaryGreen,
            child: Icon(Icons.person, size: 42, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _displayName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          if (_userEmail.isNotEmpty)
            Center(
              child: Text(
                _userEmail,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
          const SizedBox(height: 24),

          // MongoDB Compass Information Tile
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.storage, color: primaryGreen),
                          SizedBox(width: 8),
                          Text('MongoDB Database', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (_isDbConnected == true) ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (_isDbConnected == true) ? 'Connected' : 'Offline',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: (_isDbConnected == true) ? primaryGreen : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _dbInfoRow('Database Name', 'intelligent_land_measurement'),
                  _dbInfoRow('Collections', 'users, lands'),
                  _dbInfoRow('Compass URI', 'mongodb://127.0.0.1:27017'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showDatabaseDetailsDialog,
                          icon: const Icon(Icons.settings, size: 16),
                          label: const Text('Configure IP'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _checkDbStatus();
                            await _loadRecentFields();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Synchronized with MongoDB Compass!'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.sync, size: 16),
                          label: const Text('Sync Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: const Icon(Icons.landscape, color: primaryGreen),
            title: const Text('My Saved Land Records'),
            subtitle: Text('${_recentFields.length} field plots'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              setState(() {
                selectedIndex = 2; // My Fields tab
              });
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: logout,
          ),
        ],
      ),
    );
  }

  Widget _dbInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LargeMeasurementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _LargeMeasurementCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.3),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}