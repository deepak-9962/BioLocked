import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/share/share_card_service.dart';
import '../features/stats/stats_service.dart';
import 'theme/bio_theme.dart';

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
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          decoration: BoxDecoration(
            color: BioColors.cardBg.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: BioColors.primaryFixed.withValues(alpha: 0.2),
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
                  color: BioColors.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 20),

              // Title
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    BioColors.primaryFixed,
                    BioColors.green500,
                  ],
                ).createShader(bounds),
                child: Text(
                  'SHARE YOUR ACHIEVEMENT',
                  style: BioTextStyles.labelCaps.copyWith(
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
                    color: BioColors.green500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: BioColors.green500.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: BioColors.green500,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Saved! Find it in your app files.',
                          style: BioTextStyles.bodyMd.copyWith(
                            color: BioColors.green500,
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
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            BioColors.primaryFixed.withValues(alpha: 0.5),
            BioColors.blue400.withValues(alpha: 0.3),
            BioColors.primaryFixed.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: _isTransparent
              ? Colors.transparent
              : BioColors.background,
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
                    BioColors.background,
                    BioColors.cardBg,
                    BioColors.background,
                  ],
                ),
        ),
        child: Column(
          children: [
            // App branding
            Text(
              'BIO-LOCKED',
              style: BioTextStyles.labelCaps.copyWith(
                color: BioColors.primaryFixed,
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
                color: BioColors.green500,
                boxShadow: [
                  BoxShadow(
                    color: BioColors.green500.withValues(alpha: 0.4),
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
              style: BioTextStyles.headlineLg.copyWith(
                color: Colors.white,
                letterSpacing: 2,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            // Duration
            Text(
              '${widget.durationMinutes} min deep work session',
              style: BioTextStyles.bodyMd.copyWith(
                color: BioColors.blue400,
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
                    color: BioColors.orange500,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStat(
                    icon: Icons.check_circle,
                    value: '${widget.stats.totalSessions}',
                    label: 'SESSIONS',
                    color: BioColors.green500,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStat(
                    icon: Icons.access_time,
                    value: '${widget.stats.totalMinutes ~/ 60}h',
                    label: 'FOCUS',
                    color: BioColors.blue400,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Date
            Text(
              _formatDate(DateTime.now()),
              style: BioTextStyles.bodyMd.copyWith(
                color: BioColors.onSurfaceVariant.withValues(alpha: 0.7),
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
        borderRadius: BorderRadius.circular(8),
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
            style: BioTextStyles.headlineLg.copyWith(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: BioColors.onSurfaceVariant.withValues(alpha: 0.7),
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
        color: BioColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
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
                      ? BioColors.blue400.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: _isTransparent
                      ? Border.all(
                          color: BioColors.blue400.withValues(alpha: 0.4),
                        )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.layers_clear,
                      color: _isTransparent
                          ? BioColors.blue400
                          : BioColors.onSurfaceVariant,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Transparent',
                      style: TextStyle(
                        color: _isTransparent
                            ? BioColors.blue400
                            : BioColors.onSurfaceVariant,
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
                      ? BioColors.primaryFixed.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: !_isTransparent
                      ? Border.all(
                          color: BioColors.primaryFixed.withValues(alpha: 0.4),
                        )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image,
                      color: !_isTransparent
                          ? BioColors.primaryFixed
                          : BioColors.onSurfaceVariant,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'With Background',
                      style: TextStyle(
                        color: !_isTransparent
                            ? BioColors.primaryFixed
                            : BioColors.onSurfaceVariant,
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
                color: BioColors.blue400.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: BioColors.blue400.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.download_rounded,
                    color: BioColors.blue400,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Download',
                    style: BioTextStyles.labelCaps.copyWith(
                      color: BioColors.blue400,
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
                        BioColors.primaryFixed,
                        BioColors.green500,
                        BioColors.primaryFixed,
                      ],
                      stops: [
                        0.0,
                        _shimmerController.value,
                        1.0,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: BioColors.primaryFixed.withValues(alpha: 0.3),
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
                              color: BioColors.onPrimaryFixed,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.share_rounded,
                              color: BioColors.onPrimaryFixed,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Share to Social',
                              style: BioTextStyles.labelCaps.copyWith(
                                color: BioColors.onPrimaryFixed,
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
            backgroundColor: BioColors.red500,
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
            backgroundColor: BioColors.red500,
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
