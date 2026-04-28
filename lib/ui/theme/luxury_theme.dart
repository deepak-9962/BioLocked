import 'dart:ui';
import 'package:flutter/material.dart';

/// Bio-Locked Luxury Theme System
/// Premium dark theme with gold, emerald, and platinum accents

class LuxuryColors {
  // Primary Backgrounds
  static const Color richBlack = Color(0xFF0A0A0F);
  static const Color elevatedSurface = Color(0xFF12121A);
  static const Color cardBackground = Color(0xFF1A1A24);
  static const Color subtleBorder = Color(0xFF2A2A3A);
  
  // Energy Colors - Low (Platinum Blue)
  static const Color platinumBlueLight = Color(0xFFA8D4E6);
  static const Color platinumBlue = Color(0xFF7EC8E3);
  static const Color platinumBlueDark = Color(0xFF5BA3C0);
  
  // Energy Colors - Medium (Burnished Gold)
  static const Color champagne = Color(0xFFF7E7CE);
  static const Color burnishedGold = Color(0xFFD4AF37);
  static const Color darkGold = Color(0xFFC9A227);
  static const Color champagneGold = Color(0xFFF7E7CE);
  
  // Energy Colors - High (Deep Rose)
  static const Color roseLight = Color(0xFFE85A71);
  static const Color deepRose = Color(0xFFC41E3A);
  static const Color crimson = Color(0xFF9B111E);
  
  // Success (Emerald/Jade)
  static const Color emeraldLight = Color(0xFF50C878);
  static const Color emerald = Color(0xFF2E8B57);
  static const Color jade = Color(0xFF00A86B);
  
  // Premium Accent (Amethyst)
  static const Color amethystLight = Color(0xFF9966CC);
  static const Color amethyst = Color(0xFF7851A9);
  static const Color deepPurple = Color(0xFF4B0082);
  
  // Danger/Alarm (Ruby)
  static const Color rubyLight = Color(0xFFE0115F);
  static const Color rubyRed = Color(0xFF9B111E);
  static const Color ruby = Color(0xFF9B111E);
  static const Color rubyDark = Color(0xFF722F37);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFE0E0E0);
  static const Color textTertiary = Color(0xFF8A8A9A);
  static const Color textGold = Color(0xFFD4AF37);
  static const Color textSuccess = Color(0xFF50C878);
  static const Color textWarning = Color(0xFFE85A71);
}

class LuxuryGradients {
  // Background gradients
  static const LinearGradient richBlackGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0A0A0F),
      Color(0xFF1A1025),
      Color(0xFF0A0A0F),
    ],
  );
  
  static const LinearGradient darkBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0A0A0F),
      Color(0xFF12121A),
      Color(0xFF0A0A0F),
    ],
  );
  
  static const LinearGradient premiumDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A0A0F),
      Color(0xFF151520),
      Color(0xFF0A0A0F),
    ],
  );
  
  // Frosted glass effect
  static const LinearGradient frostedGlass = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x15FFFFFF),
      Color(0x08FFFFFF),
    ],
  );
  
  // Energy gradients
  static const LinearGradient platinumBlueGradient = LinearGradient(
    colors: [Color(0xFFA8D4E6), Color(0xFF7EC8E3)],
  );
  
  static const LinearGradient platinumGold = LinearGradient(
    colors: [Color(0xFF7EC8E3), Color(0xFFD4AF37)],
  );
  
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF7E7CE), Color(0xFFD4AF37)],
  );
  
  static const LinearGradient goldShimmer = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4AF37), Color(0xFFF7E7CE), Color(0xFFD4AF37)],
  );
  
  static const LinearGradient roseGradient = LinearGradient(
    colors: [Color(0xFFE85A71), Color(0xFFC41E3A)],
  );
  
  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF50C878), Color(0xFF2E8B57)],
  );
  
  static const LinearGradient emeraldGlow = LinearGradient(
    colors: [Color(0xFF50C878), Color(0xFF2E8B57)],
  );
  
  static const LinearGradient amethystGradient = LinearGradient(
    colors: [Color(0xFF9966CC), Color(0xFF7851A9)],
  );
  
  static const LinearGradient rubyGradient = LinearGradient(
    colors: [Color(0xFFE0115F), Color(0xFF9B111E)],
  );
  
  static const LinearGradient rubyGlow = LinearGradient(
    colors: [Color(0xFFE0115F), Color(0xFF9B111E)],
  );
  
  // Recovery mode gradient
  static const LinearGradient recoveryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0A0A0F),
      Color(0xFF0A1929),
      Color(0xFF0A0A0F),
    ],
  );

  static LinearGradient getEnergyGradient(int level) {
    if (level < 40) {
      return platinumBlueGradient;
    } else if (level < 70) {
      return goldGradient;
    } else {
      return roseGradient;
    }
  }
}

class LuxuryTextStyles {
  // Display styles
  static const TextStyle displayLarge = TextStyle(
    color: LuxuryColors.textPrimary,
    fontSize: 36,
    fontWeight: FontWeight.bold,
    letterSpacing: 4,
  );
  
  static const TextStyle headlineLarge = TextStyle(
    color: LuxuryColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: 2,
  );
  
  static const TextStyle titleLarge = TextStyle(
    color: LuxuryColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 1,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    color: LuxuryColors.textSecondary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    color: LuxuryColors.textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static const TextStyle labelLarge = TextStyle(
    color: LuxuryColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 1,
  );

  static const TextStyle heroTitle = TextStyle(
    color: LuxuryColors.textPrimary,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 4,
  );

  static const TextStyle screenTitle = TextStyle(
    color: LuxuryColors.textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 2,
  );

  static const TextStyle subtitle = TextStyle(
    color: LuxuryColors.textSecondary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyText = TextStyle(
    color: LuxuryColors.textSecondary,
    fontSize: 14,
    height: 1.5,
  );

  static const TextStyle hint = TextStyle(
    color: LuxuryColors.textTertiary,
    fontSize: 12,
  );

  static const TextStyle timerLarge = TextStyle(
    color: LuxuryColors.textPrimary,
    fontSize: 72,
    fontWeight: FontWeight.w200,
    letterSpacing: 8,
    fontFamily: 'monospace',
  );

  static const TextStyle goldAccent = TextStyle(
    color: LuxuryColors.textGold,
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 1,
  );

  static const TextStyle buttonText = TextStyle(
    color: LuxuryColors.richBlack,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 1,
  );
}

class LuxuryDecorations {
  /// Frosted glass card decoration
  static BoxDecoration frostedCard({
    double opacity = 0.05,
    double borderOpacity = 0.1,
    double borderRadius = 16,
    Color? glowColor,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withValues(alpha: borderOpacity),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 20,
          spreadRadius: -5,
        ),
        if (glowColor != null)
          BoxShadow(
            color: glowColor.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
      ],
    );
  }

  /// Premium button decoration
  static BoxDecoration premiumButton({
    required Color color,
    double borderRadius = 12,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color,
          color.withValues(alpha: 0.8),
        ],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.4),
          blurRadius: 15,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Achievement card with gold glow
  static BoxDecoration achievementCard() {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color(0x4DD4AF37),
          Color(0x33C9A227),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: LuxuryColors.burnishedGold.withValues(alpha: 0.5),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: LuxuryColors.burnishedGold.withValues(alpha: 0.3),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }

  /// Stats card decoration
  static BoxDecoration statsCard(Color accentColor) {
    return BoxDecoration(
      color: accentColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: accentColor.withValues(alpha: 0.2),
        width: 1,
      ),
    );
  }

  /// Danger/alarm card
  static BoxDecoration dangerCard() {
    return BoxDecoration(
      color: LuxuryColors.ruby.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: LuxuryColors.ruby.withValues(alpha: 0.5),
        width: 1,
      ),
    );
  }
}

/// Helper function to get energy color based on level
Color getLuxuryEnergyColor(int level) {
  if (level < 40) {
    return LuxuryColors.platinumBlue;
  } else if (level < 70) {
    return LuxuryColors.burnishedGold;
  } else {
    return LuxuryColors.roseLight;
  }
}

/// Helper function to get energy gradient based on level
LinearGradient getLuxuryEnergyGradient(int level) {
  if (level < 40) {
    return LuxuryGradients.platinumBlueGradient;
  } else if (level < 70) {
    return LuxuryGradients.goldGradient;
  } else {
    return LuxuryGradients.roseGradient;
  }
}

/// Frosted glass widget wrapper
class FrostedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double opacity;
  final double borderRadius;
  final Color? glowColor;

  const FrostedCard({
    super.key,
    required this.child,
    this.padding,
    this.opacity = 0.05,
    this.borderRadius = 16,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: LuxuryDecorations.frostedCard(
        opacity: opacity,
        borderRadius: borderRadius,
        glowColor: glowColor,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Premium button widget
class LuxuryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final IconData? icon;
  final bool isLoading;

  const LuxuryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = LuxuryColors.burnishedGold,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: LuxuryDecorations.premiumButton(color: color),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: LuxuryColors.richBlack,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: LuxuryColors.richBlack, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(text, style: LuxuryTextStyles.buttonText),
                ],
              ),
      ),
    );
  }
}

/// Circular progress indicator with luxury styling
class LuxuryCircularProgress extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color color;
  final double size;
  final double strokeWidth;
  final Widget? child;

  const LuxuryCircularProgress({
    super.key,
    required this.progress,
    this.color = LuxuryColors.burnishedGold,
    this.size = 200,
    this.strokeWidth = 8,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background track
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: strokeWidth,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          // Progress
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: strokeWidth,
              color: color,
              strokeCap: StrokeCap.round,
            ),
          ),
          // Glow effect
          Container(
            width: size - strokeWidth * 2,
            height: size - strokeWidth * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

/// Stats badge widget
class StatsBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const StatsBadge({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: LuxuryDecorations.statsCard(color),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: LuxuryTextStyles.hint,
          ),
        ],
      ),
    );
  }
}
