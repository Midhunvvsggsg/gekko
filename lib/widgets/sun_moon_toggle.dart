import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

class SunMoonToggle extends ConsumerWidget {
  const SunMoonToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Tooltip(
      message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      child: InkWell(
        onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: 58,
          height: 30,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
            border: Border.all(
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFFCBD5E1),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? const Color(0xFF38BDF8).withValues(alpha: 0.25)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.25),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background details (stars in dark mode, light rays in light mode)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: isDark ? 6 : 30,
                top: 4,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: isDark ? 0.9 : 0.4,
                  child: Icon(
                    isDark ? Icons.star_rate_rounded : Icons.wb_sunny_outlined,
                    size: 14,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                  ),
                ),
              ),

              // Sliding Sun / Moon Knob
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF38BDF8), const Color(0xFF0284C7)]
                          : [const Color(0xFFFBBF24), const Color(0xFFF59E0B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black45 : Colors.black12,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedCrossFade(
                      duration: const Duration(milliseconds: 250),
                      crossFadeState: isDark
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: const Icon(
                        Icons.wb_sunny_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      secondChild: const Icon(
                        Icons.nightlight_round,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
