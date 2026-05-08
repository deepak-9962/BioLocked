import 'package:flutter/material.dart';

class WebAppColors {
  static const background = Color(0xFF111015);
  static const surface = Color(0x0AFFFFFF);
  static const surfaceStrong = Color(0x10FFFFFF);
  static const border = Color(0x1AFFFFFF);
  static const borderStrong = Color(0x26FFFFFF);
  static const text = Color(0xFFE6E0E9);
  static const textMuted = Color(0xFFA7A0AD);
  static const textFaint = Color(0xFF7C7484);
  static const cream = Color(0xFFD6D3CC);
  static const blue = Color(0xFF7EC8E3);
  static const gold = Color(0xFFD4AF37);
  static const green = Color(0xFF50C878);
  static const red = Color(0xFFEF8686);
}

class WebAppText {
  static const brand = TextStyle(
    color: WebAppColors.cream,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 4,
  );

  static const eyebrow = TextStyle(
    color: WebAppColors.blue,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 3,
  );

  static const title = TextStyle(
    color: Colors.white,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.08,
  );

  static const sectionTitle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  static const body = TextStyle(
    color: WebAppColors.textMuted,
    fontSize: 15,
    height: 1.55,
  );

  static const label = TextStyle(
    color: WebAppColors.cream,
    fontSize: 12,
    fontWeight: FontWeight.w700,
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
      backgroundColor: WebAppColors.background,
      bottomNavigationBar: bottomNavigationBar,
      body: Container(
        decoration: const BoxDecoration(
          color: WebAppColors.background,
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
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: WebAppColors.border)),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: WebAppColors.text),
              tooltip: 'Back',
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              title ?? 'BIO-LOCKED',
              style: WebAppText.brand,
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
        color: backgroundColor ?? WebAppColors.surface,
        border: Border.all(color: borderColor ?? WebAppColors.border),
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
          backgroundColor: WebAppColors.cream,
          foregroundColor: WebAppColors.background,
          disabledBackgroundColor: WebAppColors.textFaint.withValues(alpha: 0.35),
          disabledForegroundColor: WebAppColors.textMuted,
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
          foregroundColor: WebAppColors.text,
          side: const BorderSide(color: WebAppColors.borderStrong),
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
          if (icon != null) Icon(icon, color: WebAppColors.textMuted, size: 17),
          if (icon != null) const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
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
            style: const TextStyle(
              color: WebAppColors.textMuted,
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
    this.color = WebAppColors.cream,
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
            Icon(icon, size: 15, color: selected ? WebAppColors.background : color),
            const SizedBox(width: 7),
          ],
          Text(
            label,
            style: TextStyle(
              color: selected ? WebAppColors.background : color,
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
