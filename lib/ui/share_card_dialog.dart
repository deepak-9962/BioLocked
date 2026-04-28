import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/share/share_card_service.dart';
import '../features/stats/stats_service.dart';
import 'theme/luxury_theme.dart';

/// Shows a share card preview dialog with download/share options
class ShareCardDialog extends ConsumerStatefulWidget {
  final String taskName;
  final int durationMinutes;
  final UserStats stats;

  const ShareCardDialog({
    super.key,
    required this.taskName,
    required this.durationMinutes,
    required this.stats,
  });

  static Future<void> show(
    BuildContext context, {
    required String taskName,
    required int durationMinutes,
    required UserStats stats,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ShareCardDialog(
        taskName: taskName,
        durationMinutes: durationMinutes,
        stats: stats,
      ),
    );
  }

  @override
  ConsumerState<ShareCardDialog> createState() => _ShareCardDialogState();
}

class _ShareCardDialogState extends ConsumerState<ShareCardDialog>
    with SingleTickerProviderStateMixin {
  bool _isTransparent = true;
  bool _isLoading = false;
  String? _savedPath;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          decoration: BoxDecoration(
            color: LuxuryColors.cardBackground.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: LuxuryColors.burnishedGold.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: LuxuryColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 20),

              // Title
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    LuxuryColors.burnishedGold,
                    LuxuryColors.champagneGold,
                  ],
                ).createShader(bounds),
                child: Text(
                  'SHARE YOUR ACHIEVEMENT',
                  style: LuxuryTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Card Preview
              _buildCardPreview(),

              const SizedBox(height: 24),

              // Background toggle
              _buildBackgroundToggle(),

              const SizedBox(height: 20),

              // Action buttons
              _buildActionButtons(),

              // Saved path message
              if (_savedPath != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: LuxuryColors.emerald.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: LuxuryColors.emerald.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: LuxuryColors.emerald,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Saved! Find it in your app files.',
                          style: LuxuryTextStyles.bodyMedium.copyWith(
                            color: LuxuryColors.emerald,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardPreview() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            LuxuryColors.burnishedGold.withValues(alpha: 0.5),
            LuxuryColors.platinumBlue.withValues(alpha: 0.3),
            LuxuryColors.burnishedGold.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: _isTransparent
              ? Colors.transparent
              : LuxuryColors.richBlack,
          image: _isTransparent
              ? const DecorationImage(
                  image: AssetImage('assets/images/checkerboard.png'),
                  repeat: ImageRepeat.repeat,
                  opacity: 0.1,
                )
              : null,
          gradient: _isTransparent
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    LuxuryColors.richBlack,
                    LuxuryColors.cardBackground,
                    LuxuryColors.richBlack,
                  ],
                ),
        ),
        child: Column(
          children: [
            // App branding
            Text(
              'BIO-LOCKED',
              style: LuxuryTextStyles.labelLarge.copyWith(
                color: LuxuryColors.burnishedGold,
                letterSpacing: 4,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 16),

            // Success badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LuxuryGradients.emeraldGlow,
                boxShadow: [
                  BoxShadow(
                    color: LuxuryColors.emerald.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),

            const SizedBox(height: 16),

            // Task name
            Text(
              widget.taskName.toUpperCase(),
              style: LuxuryTextStyles.titleLarge.copyWith(
                color: Colors.white,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            // Duration
            Text(
              '${widget.durationMinutes} min deep work session',
              style: LuxuryTextStyles.bodyMedium.copyWith(
                color: LuxuryColors.platinumBlue,
              ),
            ),

            const SizedBox(height: 20),

            // Stats row
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    icon: Icons.local_fire_department,
                    value: '${widget.stats.currentStreak}',
                    label: 'STREAK',
                    color: LuxuryColors.burnishedGold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStat(
                    icon: Icons.check_circle,
                    value: '${widget.stats.totalSessions}',
                    label: 'SESSIONS',
                    color: LuxuryColors.emerald,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStat(
                    icon: Icons.access_time,
                    value: '${widget.stats.totalMinutes ~/ 60}h',
                    label: 'FOCUS',
                    color: LuxuryColors.platinumBlue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Date
            Text(
              _formatDate(DateTime.now()),
              style: LuxuryTextStyles.bodyMedium.copyWith(
                color: LuxuryColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: LuxuryTextStyles.titleLarge.copyWith(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: LuxuryColors.textTertiary,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: LuxuryColors.elevatedSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isTransparent = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isTransparent
                      ? LuxuryColors.platinumBlue.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: _isTransparent
                      ? Border.all(
                          color: LuxuryColors.platinumBlue.withValues(alpha: 0.4),
                        )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.layers_clear,
                      color: _isTransparent
                          ? LuxuryColors.platinumBlue
                          : LuxuryColors.textTertiary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Transparent',
                      style: TextStyle(
                        color: _isTransparent
                            ? LuxuryColors.platinumBlue
                            : LuxuryColors.textTertiary,
                        fontWeight: _isTransparent
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isTransparent = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isTransparent
                      ? LuxuryColors.burnishedGold.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: !_isTransparent
                      ? Border.all(
                          color: LuxuryColors.burnishedGold.withValues(alpha: 0.4),
                        )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image,
                      color: !_isTransparent
                          ? LuxuryColors.burnishedGold
                          : LuxuryColors.textTertiary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'With Background',
                      style: TextStyle(
                        color: !_isTransparent
                            ? LuxuryColors.burnishedGold
                            : LuxuryColors.textTertiary,
                        fontWeight: !_isTransparent
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Download button
        Expanded(
          child: GestureDetector(
            onTap: _isLoading ? null : _handleDownload,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: LuxuryColors.platinumBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: LuxuryColors.platinumBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_rounded,
                    color: LuxuryColors.platinumBlue,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Download',
                    style: LuxuryTextStyles.labelLarge.copyWith(
                      color: LuxuryColors.platinumBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Share button
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _isLoading ? null : _handleShare,
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        LuxuryColors.burnishedGold,
                        LuxuryColors.champagneGold,
                        LuxuryColors.burnishedGold,
                      ],
                      stops: [
                        0.0,
                        _shimmerController.value,
                        1.0,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: LuxuryColors.burnishedGold.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: LuxuryColors.richBlack,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.share_rounded,
                              color: LuxuryColors.richBlack,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Share to Social',
                              style: LuxuryTextStyles.labelLarge.copyWith(
                                color: LuxuryColors.richBlack,
                              ),
                            ),
                          ],
                        ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _handleDownload() async {
    setState(() {
      _isLoading = true;
      _savedPath = null;
    });

    try {
      final path = await ShareCardService.downloadCard(
        taskName: widget.taskName,
        durationMinutes: widget.durationMinutes,
        totalSessions: widget.stats.totalSessions,
        currentStreak: widget.stats.currentStreak,
        totalHours: widget.stats.totalMinutes ~/ 60,
        withBackground: !_isTransparent,
      );

      setState(() {
        _savedPath = path;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: LuxuryColors.ruby,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleShare() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ShareCardService.shareCard(
        taskName: widget.taskName,
        durationMinutes: widget.durationMinutes,
        totalSessions: widget.stats.totalSessions,
        currentStreak: widget.stats.currentStreak,
        totalHours: widget.stats.totalMinutes ~/ 60,
        withBackground: !_isTransparent,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: LuxuryColors.ruby,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
