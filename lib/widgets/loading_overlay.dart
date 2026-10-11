import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Waits for [task], but takes at least [min] in total.
///
/// A local XAMPP server answers in ~25 ms, which is too fast to see, so
/// without this the loading overlay would flicker or not appear at all.
/// Errors from [task] are still thrown, after the same minimum wait.
Future<T> withMinDuration<T>(
  Future<T> task, {
  Duration min = const Duration(milliseconds: 700),
}) async {
  final delay = Future<void>.delayed(min);
  try {
    return await task;
  } finally {
    await delay;
  }
}

/// Covers [child] with a dimmed barrier and a spinner card while [loading] is
/// true. Nothing underneath can be tapped, and the back button does nothing,
/// until loading finishes.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.loading,
    required this.child,
    this.message = 'Loading...',
  });

  final bool loading;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !loading,
      child: Stack(
        children: [
          child,
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: loading
                  ? _LoadingBarrier(message: message)
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBarrier extends StatelessWidget {
  const _LoadingBarrier({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          // Swallows every tap so the screen underneath can't be used.
          ModalBarrier(
            dismissible: false,
            color: AppColors.textDark.withValues(alpha: 0.45),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
              child: Material(
                color: AppColors.surface,
                elevation: 8,
                shadowColor: AppColors.textDark.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(
                        dimension: 46,
                        child: CircularProgressIndicator(
                          strokeWidth: 4.5,
                          strokeCap: StrokeCap.round,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Please wait',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
