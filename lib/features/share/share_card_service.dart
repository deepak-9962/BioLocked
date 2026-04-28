import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Service for generating and sharing completion cards
class ShareCardService {
  /// Generate a shareable card as PNG bytes with transparent background
  static Future<Uint8List> generateCard({
    required String taskName,
    required int durationMinutes,
    required int totalSessions,
    required int currentStreak,
    required int totalHours,
    bool withBackground = false,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const cardWidth = 600.0;
    const cardHeight = 400.0;

    // Card background (transparent or with luxury gradient)
    if (withBackground) {
      final backgroundPaint = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          const Offset(cardWidth, cardHeight),
          [
            const Color(0xFF0A0A0F),
            const Color(0xFF1A1A24),
            const Color(0xFF0A0A0F),
          ],
          [0.0, 0.5, 1.0],
        );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, cardWidth, cardHeight),
          const Radius.circular(24),
        ),
        backgroundPaint,
      );

      // Border glow
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          const Offset(cardWidth, 0),
          [
            const Color(0xFFD4AF37),
            const Color(0xFF7EC8E3),
            const Color(0xFFD4AF37),
          ],
          [0.0, 0.5, 1.0],
        );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, cardWidth, cardHeight),
          const Radius.circular(24),
        ),
        borderPaint,
      );
    }

    // App branding
    _drawText(
      canvas,
      'BIO-LOCKED',
      const Offset(cardWidth / 2, 35),
      fontSize: 16,
      color: const Color(0xFFD4AF37),
      letterSpacing: 4,
    );

    // Completion badge circle
    final badgeCenter = const Offset(cardWidth / 2, 120);
    final badgePaint = Paint()
      ..shader = ui.Gradient.radial(
        badgeCenter,
        50,
        [
          const Color(0xFF50C878),
          const Color(0xFF2E8B57),
        ],
      );
    canvas.drawCircle(badgeCenter, 45, badgePaint);

    // Checkmark
    final checkPath = Path();
    checkPath.moveTo(badgeCenter.dx - 18, badgeCenter.dy);
    checkPath.lineTo(badgeCenter.dx - 5, badgeCenter.dy + 15);
    checkPath.lineTo(badgeCenter.dx + 20, badgeCenter.dy - 12);
    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(checkPath, checkPaint);

    // Task name
    _drawText(
      canvas,
      taskName.toUpperCase(),
      const Offset(cardWidth / 2, 195),
      fontSize: 22,
      color: Colors.white,
      fontWeight: FontWeight.bold,
      letterSpacing: 2,
    );

    // Duration
    final durationText = _formatDuration(durationMinutes);
    _drawText(
      canvas,
      durationText,
      const Offset(cardWidth / 2, 225),
      fontSize: 16,
      color: const Color(0xFF7EC8E3),
    );

    // Stats row
    const statsY = 290.0;
    const statsSpacing = cardWidth / 3;

    // Streak stat
    _drawStatBox(
      canvas,
      icon: '🔥',
      value: '$currentStreak',
      label: 'DAY STREAK',
      center: Offset(statsSpacing / 2, statsY),
      color: const Color(0xFFD4AF37),
    );

    // Sessions stat
    _drawStatBox(
      canvas,
      icon: '✓',
      value: '$totalSessions',
      label: 'SESSIONS',
      center: Offset(cardWidth / 2, statsY),
      color: const Color(0xFF50C878),
    );

    // Total hours stat
    _drawStatBox(
      canvas,
      icon: '⏱',
      value: '${totalHours}h',
      label: 'TOTAL FOCUS',
      center: Offset(cardWidth - statsSpacing / 2, statsY),
      color: const Color(0xFF7EC8E3),
    );

    // Date & tagline
    final now = DateTime.now();
    final dateStr = '${_monthName(now.month)} ${now.day}, ${now.year}';
    _drawText(
      canvas,
      dateStr,
      const Offset(cardWidth / 2, 360),
      fontSize: 12,
      color: const Color(0xFF8A8A9A),
    );

    // End recording and create image
    final picture = recorder.endRecording();
    final image = await picture.toImage(cardWidth.toInt(), cardHeight.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  static void _drawText(
    Canvas canvas,
    String text,
    Offset center, {
    double fontSize = 14,
    Color color = Colors.white,
    FontWeight fontWeight = FontWeight.normal,
    double letterSpacing = 0,
  }) {
    final textStyle = ui.TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );
    final paragraphStyle = ui.ParagraphStyle(
      textAlign: TextAlign.center,
    );
    final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(textStyle)
      ..addText(text);
    final paragraph = paragraphBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: 500));

    canvas.drawParagraph(
      paragraph,
      Offset(center.dx - paragraph.width / 2, center.dy - paragraph.height / 2),
    );
  }

  static void _drawStatBox(
    Canvas canvas, {
    required String icon,
    required String value,
    required String label,
    required Offset center,
    required Color color,
  }) {
    // Background box
    final boxPaint = Paint()..color = color.withValues(alpha: 0.15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 140, height: 80),
        const Radius.circular(12),
      ),
      boxPaint,
    );

    // Border
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 140, height: 80),
        const Radius.circular(12),
      ),
      borderPaint,
    );

    // Icon
    _drawText(
      canvas,
      icon,
      Offset(center.dx, center.dy - 20),
      fontSize: 18,
    );

    // Value
    _drawText(
      canvas,
      value,
      Offset(center.dx, center.dy + 5),
      fontSize: 20,
      color: color,
      fontWeight: FontWeight.bold,
    );

    // Label
    _drawText(
      canvas,
      label,
      Offset(center.dx, center.dy + 28),
      fontSize: 10,
      color: const Color(0xFF8A8A9A),
      letterSpacing: 1,
    );
  }

  static String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min deep work session';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '$hours hour deep work session';
      }
      return '$hours hr $mins min deep work session';
    }
  }

  static String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  /// Save card to temp file and return path
  static Future<String> saveCardToFile(Uint8List bytes, {bool transparent = true}) async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = transparent ? 'bio_locked_card_$timestamp.png' : 'bio_locked_card_bg_$timestamp.png';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Share the card to social media
  static Future<void> shareCard({
    required String taskName,
    required int durationMinutes,
    required int totalSessions,
    required int currentStreak,
    required int totalHours,
    bool withBackground = true,
  }) async {
    final bytes = await generateCard(
      taskName: taskName,
      durationMinutes: durationMinutes,
      totalSessions: totalSessions,
      currentStreak: currentStreak,
      totalHours: totalHours,
      withBackground: withBackground,
    );

    final filePath = await saveCardToFile(bytes, transparent: !withBackground);

    await Share.shareXFiles(
      [XFile(filePath)],
      text: '🔒 Just completed a $durationMinutes min focus session on "$taskName" with Bio-Locked!\n\n🔥 $currentStreak day streak | ✓ $totalSessions sessions | ⏱ ${totalHours}h total\n\n#BioLocked #DeepWork #Focus #Productivity',
    );
  }

  /// Download the card (save to device gallery)
  static Future<String> downloadCard({
    required String taskName,
    required int durationMinutes,
    required int totalSessions,
    required int currentStreak,
    required int totalHours,
    bool withBackground = false,
  }) async {
    final bytes = await generateCard(
      taskName: taskName,
      durationMinutes: durationMinutes,
      totalSessions: totalSessions,
      currentStreak: currentStreak,
      totalHours: totalHours,
      withBackground: withBackground,
    );

    // Save to app documents for now (user can access via file manager)
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = withBackground 
      ? 'BioLocked_${taskName}_$timestamp.png'
      : 'BioLocked_Transparent_${taskName}_$timestamp.png';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    
    return file.path;
  }
}

final shareCardServiceProvider = Provider<ShareCardService>((ref) => ShareCardService());
