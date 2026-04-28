import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls grayscale mode — applied as a ColorFiltered overlay over the entire app.
/// When active during a session, the screen becomes desaturated and visually boring,
/// killing the dopamine loop from social media / colorful apps showing through.
class GrayscaleModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void enable() => state = true;
  void disable() => state = false;
  void toggle() => state = !state;
}

final grayscaleModeProvider =
    NotifierProvider<GrayscaleModeNotifier, bool>(GrayscaleModeNotifier.new);

/// The 3x3 grayscale color matrix for ColorFilter.matrix()
/// This desaturates all colors to grayscale using luminance weights.
const List<double> grayscaleMatrix = [
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0,      0,      0,      1, 0,
];
