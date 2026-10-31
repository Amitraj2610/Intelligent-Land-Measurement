import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class FieldPoint {
  final double latitude;
  final double longitude;

  const FieldPoint({
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory FieldPoint.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return FieldPoint(
      latitude: parseDouble(json['latitude'] ?? json['lat']),
      longitude: parseDouble(json['longitude'] ?? json['lng'] ?? json['lon']),
    );
  }
}

class FieldActivity {
  final String title;
  final String description;
  final DateTime date;

  const FieldActivity({
    required this.title,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  factory FieldActivity.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date']?.toString();
    final parsedDate = rawDate != null ? DateTime.tryParse(rawDate) : null;

    return FieldActivity(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      date: parsedDate ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class FieldRecord {
  final String id;
  final String name;

  final double areaSqMeters;
  final double latitude;
  final double longitude;

  final DateTime measuredAt;

  final String crop;
  final String season;
  final String irrigation;
  final String soilType;
  final String notes;

  final List<FieldPoint> boundary;
  final List<FieldActivity> activities;

  const FieldRecord({
    required this.id,
    required this.name,
    required this.areaSqMeters,
    required this.latitude,
    required this.longitude,
    required this.measuredAt,
    this.crop = '',
    this.season = '',
    this.irrigation = '',
    this.soilType = '',
    this.notes = '',
    this.boundary = const [],
    this.activities = const [],
  });

  double get acres {
    return areaSqMeters / 4046.8564224;
  }

  double get hectares {
    return areaSqMeters / 10000.0;
  }

  double get sqFeet {
    return areaSqMeters * 10.7639104;
  }

  FieldRecord copyWith({
    String? id,
    String? name,
    double? areaSqMeters,
    double? latitude,
    double? longitude,
    DateTime? measuredAt,
    String? crop,
    String? season,
    String? irrigation,
    String? soilType,
    String? notes,
    List<FieldPoint>? boundary,
    List<FieldActivity>? activities,
  }) {
    return FieldRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      areaSqMeters: areaSqMeters ?? this.areaSqMeters,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      measuredAt: measuredAt ?? this.measuredAt,
      crop: crop ?? this.crop,
      season: season ?? this.season,
      irrigation: irrigation ?? this.irrigation,
      soilType: soilType ?? this.soilType,
      notes: notes ?? this.notes,
      boundary: boundary ?? this.boundary,
      activities: activities ?? this.activities,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'areaSqMeters': areaSqMeters,
      'latitude': latitude,
      'longitude': longitude,
      'measuredAt': measuredAt.toIso8601String(),
      'crop': crop,
      'season': season,
      'irrigation': irrigation,
      'soilType': soilType,
      'notes': notes,
      'boundary': boundary.map((point) => point.toJson()).toList(),
      'activities': activities.map((activity) => activity.toJson()).toList(),
    };
  }

  factory FieldRecord.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final rawId = json['id']?.toString() ?? json['_id']?.toString() ?? '';
    final id = rawId.trim().isNotEmpty
        ? rawId
        : DateTime.now().microsecondsSinceEpoch.toString();

    final boundaryJson = json['boundary'] ?? json['coordinates'];
    final activitiesJson = json['activities'];

    final List<FieldPoint> parsedBoundary = [];
    if (boundaryJson is List) {
      for (final item in boundaryJson) {
        if (item is Map) {
          try {
            parsedBoundary.add(
              FieldPoint.fromJson(Map<String, dynamic>.from(item)),
            );
          } catch (_) {}
        }
      }
    }

    final List<FieldActivity> parsedActivities = [];
    if (activitiesJson is List) {
      for (final item in activitiesJson) {
        if (item is Map) {
          try {
            parsedActivities.add(
              FieldActivity.fromJson(Map<String, dynamic>.from(item)),
            );
          } catch (_) {}
        }
      }
    }

    final rawMeasuredAt = json['measuredAt']?.toString() ?? json['createdAt']?.toString();
    final measuredAt = (rawMeasuredAt != null
            ? DateTime.tryParse(rawMeasuredAt)
            : null) ??
        DateTime.now();

    double area = parseDouble(json['areaSqMeters']);
    if (area <= 0 && json['areaSize'] != null) {
      final areaStr = json['areaSize'].toString();
      final numMatch = RegExp(r'([0-9]+(\.[0-9]+)?)').firstMatch(areaStr);
      if (numMatch != null) {
        area = double.tryParse(numMatch.group(1) ?? '0') ?? 0.0;
      }
    }

    return FieldRecord(
      id: id,
      name: json['name']?.toString() ?? json['fieldName']?.toString() ?? 'Field Plot',
      areaSqMeters: area,
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      measuredAt: measuredAt,
      crop: json['crop']?.toString() ?? '',
      season: json['season']?.toString() ?? '',
      irrigation: json['irrigation']?.toString() ?? '',
      soilType: json['soilType']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      boundary: parsedBoundary,
      activities: parsedActivities,
    );
  }
}

class FieldStorage {
  static const String _storageKey = 'saved_farmer_fields_v1';

  /// Load fields from local cache, and optionally sync with MongoDB Compass
  static Future<List<FieldRecord>> loadFields({bool syncWithDb = true}) async {
    List<FieldRecord> localFields = await _loadLocalFields();

    if (syncWithDb) {
      try {
        final email = await AuthService.getCurrentEmail();
        final dbLands = await ApiService.getLands(email);

        if (dbLands.isNotEmpty) {
          final Map<String, FieldRecord> mergedMap = {};
          // Put local ones first
          for (final f in localFields) {
            mergedMap[f.id] = f;
          }
          // Merge remote ones (updating or adding)
          for (final raw in dbLands) {
            final remoteRecord = FieldRecord.fromJson(raw);
            mergedMap[remoteRecord.id] = remoteRecord;
          }

          final mergedList = mergedMap.values.toList()
            ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));

          await _saveAllLocal(mergedList);
          return mergedList;
        }
      } catch (_) {
        // Fallback to local on network error
      }
    }

    return localFields;
  }

  /// Internal loader from SharedPreferences
  static Future<List<FieldRecord>> _loadLocalFields() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedData = prefs.getString(_storageKey);

      if (storedData == null || storedData.isEmpty) {
        return [];
      }

      final decoded = jsonDecode(storedData);
      if (decoded is! List) {
        return [];
      }

      final List<FieldRecord> fields = [];
      for (final item in decoded) {
        if (item is Map) {
          try {
            fields.add(
              FieldRecord.fromJson(
                Map<String, dynamic>.from(item),
              ),
            );
          } catch (_) {}
        }
      }

      fields.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
      return fields;
    } catch (_) {
      return [];
    }
  }

  /// Save field to both local storage AND MongoDB Compass
  static Future<void> saveField(FieldRecord field, {String? measurementType}) async {
    final fields = await _loadLocalFields();

    fields.removeWhere(
      (existingField) => existingField.id == field.id,
    );

    fields.insert(0, field);
    await _saveAllLocal(fields);

    // Sync to MongoDB Compass in background
    try {
      final userEmail = await AuthService.getCurrentEmail();
      await ApiService.saveLand({
        'id': field.id,
        'userEmail': userEmail,
        'fieldName': field.name,
        'areaSize': '${field.areaSqMeters.toStringAsFixed(2)} sq meters',
        'areaSqMeters': field.areaSqMeters,
        'measurementType': measurementType ?? 'GPS',
        'latitude': field.latitude,
        'longitude': field.longitude,
        'coordinates': field.boundary.map((p) => p.toJson()).toList(),
        'boundary': field.boundary.map((p) => p.toJson()).toList(),
        'crop': field.crop,
        'season': field.season,
        'irrigation': field.irrigation,
        'soilType': field.soilType,
        'notes': field.notes,
        'createdAt': field.measuredAt.toIso8601String(),
      });
    } catch (_) {
      // Local copy saved safely, network retry later
    }
  }

  /// Update an existing field record
  static Future<void> updateField(FieldRecord field) async {
    await saveField(field);
  }

  /// Delete field from both local storage AND MongoDB Compass
  static Future<void> deleteField(String id) async {
    if (id.trim().isEmpty) return;

    final fields = await _loadLocalFields();
    fields.removeWhere((field) => field.id == id);
    await _saveAllLocal(fields);

    try {
      await ApiService.deleteLand(id);
    } catch (_) {}
  }

  /// Clear all fields locally
  static Future<void> clearAllFields() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  static Future<void> _saveAllLocal(List<FieldRecord> fields) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      fields.map((field) => field.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }
}
