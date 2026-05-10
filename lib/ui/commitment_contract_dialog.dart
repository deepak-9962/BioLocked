import 'package:flutter/material.dart';
import 'dart:ui';
import 'theme/bio_theme.dart';

/// Shows a commitment contract dialog that requires the user to type
/// a specific phrase before entering a Hard Lock session.
/// Returns true if the user committed, false if they backed out.
Future<bool> showCommitmentContract(
  BuildContext context, {
  required String taskName,
  required int durationMinutes,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.85),
    pageBuilder: (context, _, __) => _CommitmentContractPage(
      taskName: taskName,
      durationMinutes: durationMinutes,
    ),
    transitionBuilder: (context, animation, _, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
  return result ?? false;
}

class _CommitmentContractPage extends StatefulWidget {
  final String taskName;
  final int durationMinutes;

  const _CommitmentContractPage({
    required this.taskName,
    required this.durationMinutes,
  });

  @override
  State<_CommitmentContractPage> createState() => _CommitmentContractPageState();
}

class _CommitmentContractPageState extends State<_CommitmentContractPage>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late AnimationController _pulseController;
  bool _isMatch = false;
  bool _hasError = false;

  late String _requiredPhrase;

  @override
  void initState() {
    super.initState();
    final task = widget.taskName.isNotEmpty ? widget.taskName : 'deep work';
    _requiredPhrase = 'I commit to ${widget.durationMinutes} minutes of $task';
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _controller.addListener(() {
      setState(() {
        _isMatch = _controller.text.trim() == _requiredPhrase;
        _hasError = _controller.text.isNotEmpty &&
            !_requiredPhrase.startsWith(_controller.text.trim().isEmpty
                ? ' '
                : _controller.text.trim());
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),

                // Seal / crest
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: BioColors.red500.withValues(alpha: 0.1 + 0.08 * _pulseController.value),
                        border: Border.all(
                          color: BioColors.red500.withValues(alpha: 0.6 + 0.3 * _pulseController.value),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: BioColors.red500.withValues(alpha: 0.3 * _pulseController.value),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.gavel,
                        color: BioColors.red500,
                        size: 40,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                Text(
                  'COMMITMENT CONTRACT',
                  style: BioTextStyles.headlineLg.copyWith(
                    color: BioColors.red500,
                    letterSpacing: 4,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Hard Lock requires your word.',
                  style: BioTextStyles.bodyLg.copyWith(
                    color: BioColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Contract card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: BioColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: BioColors.red500.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _contractLine('I, the undersigned, hereby commit to:'),
                      const SizedBox(height: 12),
                      _contractHighlight(
                        widget.taskName.isNotEmpty ? widget.taskName : 'Deep Work',
                        BioColors.primaryFixed,
                      ),
                      const SizedBox(height: 8),
                      _contractLine('for a duration of:'),
                      const SizedBox(height: 8),
                      _contractHighlight(
                        '${widget.durationMinutes} minutes',
                        BioColors.red500,
                      ),
                      const SizedBox(height: 16),
                      _contractLine(
                        'Under Hard Lock terms:\n'
                        '• No emergency breaks permitted\n'
                        '• 5-second grace period on interruption\n'
                        '• Violations result in session termination\n'
                        '• My productivity data will be recorded',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Phrase to type
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: BioColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BioColors.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Type exactly to proceed:',
                        style: BioTextStyles.bodyMd.copyWith(
                          color: BioColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '"$_requiredPhrase"',
                        style: BioTextStyles.bodyLg.copyWith(
                          color: BioColors.primaryFixed,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Text input
                TextField(
                  controller: _controller,
                  maxLines: 2,
                  style: BioTextStyles.bodyLg.copyWith(
                    color: _isMatch
                        ? BioColors.green500
                        : _hasError
                            ? BioColors.red500.withValues(alpha: 0.8)
                            : BioColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type the commitment phrase...',
                    hintStyle: TextStyle(color: BioColors.onSurfaceVariant.withValues(alpha: 0.5)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _isMatch
                            ? BioColors.green500
                            : BioColors.outlineVariant,
                        width: _isMatch ? 2 : 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _isMatch
                            ? BioColors.green500
                            : BioColors.red500,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: BioColors.cardBg,
                    suffixIcon: _isMatch
                        ? const Icon(Icons.check_circle, color: BioColors.green500)
                        : null,
                  ),
                ),

                const SizedBox(height: 28),

                // Confirm button
                AnimatedOpacity(
                  opacity: _isMatch ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 300),
                  child: GestureDetector(
                    onTap: _isMatch ? () => Navigator.of(context).pop(true) : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: _isMatch
                            ? LinearGradient(
                                colors: [
                                  BioColors.red500,
                                  BioColors.red700,
                                ],
                              )
                            : LinearGradient(
                                colors: [
                                  BioColors.cardBg,
                                  BioColors.cardBg,
                                ],
                              ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isMatch
                              ? BioColors.red500
                              : BioColors.outlineVariant,
                        ),
                        boxShadow: _isMatch
                            ? [
                                BoxShadow(
                                  color: BioColors.red500.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock,
                            color: _isMatch
                                ? Colors.white
                                : BioColors.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'SEAL THE CONTRACT & ENTER',
                            style: BioTextStyles.labelCaps.copyWith(
                              color: _isMatch
                                  ? Colors.white
                                  : BioColors.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Back out
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'I\'m not ready yet',
                    style: TextStyle(color: BioColors.onSurfaceVariant),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contractLine(String text) {
    return Text(
      text,
      style: BioTextStyles.bodyMd.copyWith(
        color: BioColors.onSurfaceVariant,
        height: 1.6,
      ),
    );
  }

  Widget _contractHighlight(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: BioTextStyles.headlineLg.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}
