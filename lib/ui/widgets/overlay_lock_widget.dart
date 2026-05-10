import 'package:flutter/material.dart';
import '../../ui/theme/bio_theme.dart';

class OverlayLockWidget extends StatelessWidget {
  const OverlayLockWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: BioColors.background.withAlpha(240), // Dark blocking background
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock,
              color: BioColors.red500,
              size: 80,
            ),
            const SizedBox(height: 32),
            Text(
              'SESSION IN PROGRESS',
              style: BioTextStyles.headlineLg.copyWith(
                color: BioColors.red500,
                fontSize: 24,
                letterSpacing: 4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Your focus is locked.\nReturn to Bio-Locked to continue or terminate the session.',
              style: BioTextStyles.bodyLg.copyWith(
                color: BioColors.onSurfaceVariant,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
