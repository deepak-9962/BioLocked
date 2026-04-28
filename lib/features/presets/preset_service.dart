import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A saved session preset configuration
class SessionPreset {
  final String id;
  final String name;
  final String taskName;
  final int durationMinutes;
  final bool destructionMode;
  final String lockLevel;
  final String icon;
  final DateTime createdAt;

  SessionPreset({
    required this.id,
    required this.name,
    required this.taskName,
    required this.durationMinutes,
    required this.destructionMode,
    this.lockLevel = 'standard',
    this.icon = '⚡',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'taskName': taskName,
    'durationMinutes': durationMinutes,
    'destructionMode': destructionMode,
    'lockLevel': lockLevel,
    'icon': icon,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SessionPreset.fromJson(Map<String, dynamic> json) => SessionPreset(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    taskName: json['taskName'] ?? '',
    durationMinutes: json['durationMinutes'] ?? 25,
    destructionMode: json['destructionMode'] ?? false,
    lockLevel: json['lockLevel'] ?? 'standard',
    icon: json['icon'] ?? '⚡',
    createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
  );

  SessionPreset copyWith({
    String? id,
    String? name,
    String? taskName,
    int? durationMinutes,
    bool? destructionMode,
    String? lockLevel,
    String? icon,
  }) => SessionPreset(
    id: id ?? this.id,
    name: name ?? this.name,
    taskName: taskName ?? this.taskName,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    destructionMode: destructionMode ?? this.destructionMode,
    lockLevel: lockLevel ?? this.lockLevel,
    icon: icon ?? this.icon,
    createdAt: createdAt,
  );
}

/// Service for managing session presets
class PresetService {
  static const _storage = FlutterSecureStorage();
  static const _presetsKey = 'session_presets';

  /// Get all saved presets
  Future<List<SessionPreset>> getPresets() async {
    final data = await _storage.read(key: _presetsKey);
    if (data == null) return _getDefaultPresets();
    try {
      final List<dynamic> jsonList = jsonDecode(data);
      final presets = jsonList.map((j) => SessionPreset.fromJson(j)).toList();
      return presets.isEmpty ? _getDefaultPresets() : presets;
    } catch (e) {
      return _getDefaultPresets();
    }
  }

  /// Get default presets
  List<SessionPreset> _getDefaultPresets() {
    return [
      SessionPreset(
        id: 'default_study',
        name: 'Study Sprint',
        taskName: 'Study Session',
        durationMinutes: 45,
        destructionMode: false,
        lockLevel: 'standard',
        icon: '📚',
      ),
      SessionPreset(
        id: 'default_deep',
        name: 'Deep Work',
        taskName: 'Deep Focus',
        durationMinutes: 90,
        destructionMode: true,
        lockLevel: 'hard',
        icon: '🧠',
      ),
      SessionPreset(
        id: 'default_workout',
        name: 'Workout Lock',
        taskName: 'Workout Block',
        durationMinutes: 30,
        destructionMode: false,
        lockLevel: 'soft',
        icon: '🏋️',
      ),
      SessionPreset(
        id: 'default_sleep',
        name: 'Sleep Wind-down',
        taskName: 'No-scroll Wind-down',
        durationMinutes: 25,
        destructionMode: false,
        lockLevel: 'soft',
        icon: '🌙',
      ),
    ];
  }

  /// Save a new preset
  Future<void> savePreset(SessionPreset preset) async {
    final presets = await getPresets();
    
    // Remove default presets if they haven't been modified
    presets.removeWhere((p) => p.id.startsWith('default_') && 
        _getDefaultPresets().any((d) => d.id == p.id));
    
    // Add or update the preset
    final existingIndex = presets.indexWhere((p) => p.id == preset.id);
    if (existingIndex >= 0) {
      presets[existingIndex] = preset;
    } else {
      presets.add(preset);
    }
    
    await _storage.write(
      key: _presetsKey,
      value: jsonEncode(presets.map((p) => p.toJson()).toList()),
    );
  }

  /// Delete a preset
  Future<void> deletePreset(String id) async {
    final presets = await getPresets();
    presets.removeWhere((p) => p.id == id);
    
    await _storage.write(
      key: _presetsKey,
      value: jsonEncode(presets.map((p) => p.toJson()).toList()),
    );
  }

  /// Create a new preset from current session config
  SessionPreset createPreset({
    required String name,
    required String taskName,
    required int durationMinutes,
    required bool destructionMode,
    String lockLevel = 'standard',
    String icon = '⚡',
  }) {
    return SessionPreset(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      taskName: taskName,
      durationMinutes: durationMinutes,
      destructionMode: destructionMode,
      lockLevel: lockLevel,
      icon: icon,
    );
  }
}

final presetServiceProvider = Provider<PresetService>((ref) => PresetService());

final presetsProvider = FutureProvider<List<SessionPreset>>((ref) async {
  return ref.read(presetServiceProvider).getPresets();
});

/// Available preset icons
const presetIcons = [
  '⚡', '🍅', '🧠', '📚', '💻', '✍️', '🎨', '🎵', 
  '🏋️', '🧘', '📝', '🎯', '🚀', '💡', '🔥', '⭐',
];
