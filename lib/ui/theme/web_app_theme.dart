import 'package:flutter/material.dart';
import 'bio_theme.dart';

/// Reusable compound widgets used across tunnel, in-progress, and auth screens.
/// All colors now derive from the BioColors design system.

class WebAppColors {
  static const background = BioColors.background;
  static const surface = Color(0x0AFFFFFF);
  static const surfaceStrong = Color(0x10FFFFFF);
  static const border = Color(0x1AFFFFFF);
  static const borderStrong = Color(0x26FFFFFF);
  static const text = BioColors.onSurface;
  static const textMuted = BioColors.onSurfaceVariant;
  static const textFaint = Color(0xFF7C7484);
  static const cream = BioColors.primaryFixed;
  static const blue = BioColors.blue400;
  static const gold = BioColors.primaryFixed;
  static const green = BioColors.green500;
  static const red = BioColors.red500;
}

class WebAppText {
  static TextStyle brand = BioTextStyles.labelCaps.copyWith(
    color: BioColors.primaryFixed,
    fontSize: 13,
    letterSpacing: 4,
  );

  static TextStyle eyebrow = BioTextStyles.labelCaps.copyWith(
    color: BioColors.primaryFixed,
    fontSize: 12,
    letterSpacing: 3,
  );

  static TextStyle title = BioTextStyles.headlineLg.copyWith(
    color: Colors.white,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.08,
  );

  static TextStyle sectionTitle = BioTextStyles.headlineLg.copyWith(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  static TextStyle body = BioTextStyles.bodyMd.copyWith(
    color: BioColors.onSurfaceVariant,
    fontSize: 15,
    height: 1.55,
  );

  static TextStyle label = BioTextStyles.labelCaps.copyWith(
    color: BioColors.primaryFixed,
    fontSize: 12,
    letterSpacing: 1.2,
  );
}

class WebAppScaffold extends StatelessWidget {
  final Widget child;
  final Widget? bottomNavigationBar;

  const WebAppScaffold({
    super.key,
    required this.child,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioColors.background,
      bottomNavigationBar: bottomNavigationBar,
      body: Container(
        decoration: const BoxDecoration(
          color: BioColors.background,
        ),
        child: SafeArea(child: child),
      ),
    );
  }
}

class WebTopBar extends StatelessWidget {
  final String? title;
  final Widget? trailing;
  final VoidCallback? onBack;

  const WebTopBar({
    super.key,
    this.title,
    this.trailing,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: BioColors.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BioColors.surfaceContainerHigh,
                  border: Border.all(color: BioColors.outlineVariant),
                ),
                child: const Icon(Icons.arrow_back, color: BioColors.onSurface, size: 20),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title ?? 'BIO-LOCKED',
              style: BioTextStyles.labelCaps.copyWith(
                color: BioColors.primaryFixed,
                letterSpacing: 4,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class WebCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;
  final Color? backgroundColor;

  const WebCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? BioColors.surface,
        border: Border.all(color: borderColor ?? BioColors.outlineVariant.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

class WebPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const WebPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.arrow_forward, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: BioColors.primaryFixed,
          foregroundColor: BioColors.onPrimaryFixed,
          disabledBackgroundColor: BioColors.surfaceContainerHighest,
          disabledForegroundColor: BioColors.onSurfaceVariant,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class WebSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const WebSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.arrow_forward, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: BioColors.onSurface,
          side: BorderSide(color: BioColors.outlineVariant.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class WebMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const WebMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return WebCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, color: BioColors.onSurfaceVariant, size: 17),
          if (icon != null) const SizedBox(height: 8),
          Text(
            value,
            style: BioTextStyles.headlineLg.copyWith(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BioTextStyles.bodyMd.copyWith(
              color: BioColors.onSurfaceVariant,
              fontSize: 12,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class WebChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  const WebChip({
    super.key,
    required this.label,
    this.icon,
    this.color = BioColors.primaryFixed,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? color : color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: selected ? 0 : 0.35)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: selected ? BioColors.onPrimaryFixed : color),
            const SizedBox(width: 7),
          ],
          Text(
            label,
            style: TextStyle(
              color: selected ? BioColors.onPrimaryFixed : color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }
}
