import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:share_plus/share_plus.dart';

/// Accountability Partner — when you break a Hard/Standard session early,
/// a shame message is automatically shared to your chosen partner via the share sheet.
class AccountabilityService {
  static const _storage = FlutterSecureStorage();
  static const _partnerKey = 'accountability_partner';

  /// Get saved partner
  Future<AccountabilityPartner?> getPartner() async {
    final data = await _storage.read(key: _partnerKey);
    if (data == null) return null;
    try {
      return AccountabilityPartner.fromJson(jsonDecode(data));
    } catch (_) {
      return null;
    }
  }

  /// Save partner
  Future<void> savePartner(AccountabilityPartner partner) async {
    await _storage.write(
      key: _partnerKey,
      value: jsonEncode(partner.toJson()),
    );
  }

  /// Remove partner
  Future<void> removePartner() async {
    await _storage.delete(key: _partnerKey);
  }

  /// Trigger accountability message when session is broken
  Future<void> notifyPartnerOfFailure({
    required String taskName,
    required int elapsedMinutes,
    required String reason,
    required String partnerName,
  }) async {
    final message = _buildShameMessage(
      taskName: taskName,
      elapsedMinutes: elapsedMinutes,
      reason: reason,
      partnerName: partnerName,
    );

    try {
      await Share.share(message);
      debugPrint('[Accountability] Shame message shared');
    } catch (e) {
      debugPrint('[Accountability] Share failed: $e');
    }
  }

  /// Trigger a victory message when session completes
  Future<void> notifyPartnerOfSuccess({
    required String taskName,
    required int durationMinutes,
    required String partnerName,
  }) async {
    final message =
        '🏆 Hey $partnerName! I just crushed a ${durationMinutes}-minute deep work session'
        ' on "$taskName" with BioLocked! 🔒\n\n'
        'No distractions. Phone locked. Work done.\n\n'
        '—Sent from BioLocked';

    try {
      await Share.share(message);
    } catch (e) {
      debugPrint('[Accountability] Victory share failed: $e');
    }
  }

  String _buildShameMessage({
    required String taskName,
    required int elapsedMinutes,
    required String reason,
    required String partnerName,
  }) {
    final task = taskName.isNotEmpty ? '"$taskName"' : 'my focus session';
    if (elapsedMinutes < 2) {
      return '😬 $partnerName, I didn\'t even start properly. '
          'I bailed on $task immediately.\n\n'
          'Reason: $reason\n\n'
          'Hold me accountable. —BioLocked';
    }
    return '😔 $partnerName, I broke my focus session.\n\n'
        'Task: $task\n'
        'Lasted: $elapsedMinutes minute${elapsedMinutes == 1 ? '' : 's'}\n'
        'Reason: $reason\n\n'
        'I\'m going to do better. —BioLocked';
  }
}

class AccountabilityPartner {
  final String name;
  final bool notifyOnFailure;
  final bool notifyOnSuccess;

  const AccountabilityPartner({
    required this.name,
    this.notifyOnFailure = true,
    this.notifyOnSuccess = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'notifyOnFailure': notifyOnFailure,
        'notifyOnSuccess': notifyOnSuccess,
      };

  factory AccountabilityPartner.fromJson(Map<String, dynamic> json) =>
      AccountabilityPartner(
        name: json['name'] ?? '',
        notifyOnFailure: json['notifyOnFailure'] ?? true,
        notifyOnSuccess: json['notifyOnSuccess'] ?? false,
      );

  AccountabilityPartner copyWith({
    String? name,
    bool? notifyOnFailure,
    bool? notifyOnSuccess,
  }) =>
      AccountabilityPartner(
        name: name ?? this.name,
        notifyOnFailure: notifyOnFailure ?? this.notifyOnFailure,
        notifyOnSuccess: notifyOnSuccess ?? this.notifyOnSuccess,
      );
}

final accountabilityServiceProvider =
    Provider<AccountabilityService>((ref) => AccountabilityService());

final accountabilityPartnerProvider =
    FutureProvider<AccountabilityPartner?>((ref) async {
  return ref.read(accountabilityServiceProvider).getPartner();
});
