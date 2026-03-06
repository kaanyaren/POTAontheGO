import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/database/isar_helper.dart';
import 'core/theme/app_theme_controller.dart';
import 'features/home/presentation/screens/home_shell.dart';
import 'core/widgets/double_back_to_close_app.dart';
import 'features/parks/data/models/park_model.dart';
import 'features/parks/data/repositories/park_sync_repository.dart';

final appBootstrapProvider = FutureProvider<void>((ref) async {
  await IsarHelper.init();
  final count = await IsarHelper.isar.parkModels.count();

  if (count == 0) {
    await ref.read(parkSyncRepositoryProvider).syncParksFromCsv();
  }
});

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

const _brandGreen = Color(0xFF2F7F33);
const _lightBackground = Color(0xFFF7FBF7);
const _darkBackground = Color(0xFF141E15);

// Cache the text theme to avoid rebuilding on every theme build
final _cachedTextTheme = GoogleFonts.spaceGroteskTextTheme();

// Apply weight normalization once
TextTheme get _normalizedSpaceGroteskTextTheme => _cachedTextTheme.copyWith(
  displayLarge: _normalizeSpaceGroteskWeight(_cachedTextTheme.displayLarge),
  displayMedium: _normalizeSpaceGroteskWeight(_cachedTextTheme.displayMedium),
  displaySmall: _normalizeSpaceGroteskWeight(_cachedTextTheme.displaySmall),
  headlineLarge: _normalizeSpaceGroteskWeight(_cachedTextTheme.headlineLarge),
  headlineMedium: _normalizeSpaceGroteskWeight(_cachedTextTheme.headlineMedium),
  headlineSmall: _normalizeSpaceGroteskWeight(_cachedTextTheme.headlineSmall),
  titleLarge: _normalizeSpaceGroteskWeight(_cachedTextTheme.titleLarge),
  titleMedium: _normalizeSpaceGroteskWeight(_cachedTextTheme.titleMedium),
  titleSmall: _normalizeSpaceGroteskWeight(_cachedTextTheme.titleSmall),
  bodyLarge: _normalizeSpaceGroteskWeight(_cachedTextTheme.bodyLarge),
  bodyMedium: _normalizeSpaceGroteskWeight(_cachedTextTheme.bodyMedium),
  bodySmall: _normalizeSpaceGroteskWeight(_cachedTextTheme.bodySmall),
  labelLarge: _normalizeSpaceGroteskWeight(_cachedTextTheme.labelLarge),
  labelMedium: _normalizeSpaceGroteskWeight(_cachedTextTheme.labelMedium),
  labelSmall: _normalizeSpaceGroteskWeight(_cachedTextTheme.labelSmall),
);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(appThemeProvider);
    final themeMode = themeModeAsync.asData?.value ?? ThemeMode.system;

    return MaterialApp(
      title: 'POTA on the GO',
      themeMode: themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const AppBootstrapGate(),
    );
  }
}

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: _brandGreen,
        brightness: brightness,
      ).copyWith(
        primary: _brandGreen,
        surface: isDark ? const Color(0xFF18231A) : Colors.white,
        surfaceContainer: isDark
            ? const Color(0xFF1F2C20)
            : const Color(0xFFF0F6F0),
        surfaceContainerHigh: isDark
            ? const Color(0xFF273528)
            : const Color(0xFFE8F1E8),
        outline: isDark ? const Color(0xFF455444) : const Color(0xFFD5E1D5),
        shadow: Colors.black,
      );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark ? _darkBackground : _lightBackground,
    visualDensity: VisualDensity.standard,
  );

  final textTheme = _normalizedSpaceGroteskTextTheme;

  final roundedShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(24),
    side: BorderSide(color: scheme.outline.withValues(alpha: 0.55)),
  );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: roundedShape,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface.withValues(alpha: 0.94),
      hintStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      prefixIconColor: scheme.primary,
      suffixIconColor: scheme.onSurfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: scheme.primary, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark
          ? const Color(0xFF223024)
          : const Color(0xFF223A25),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outline.withValues(alpha: 0.35),
      thickness: 1,
      space: 1,
    ),
  );
}

TextStyle? _normalizeSpaceGroteskWeight(TextStyle? style) {
  if (style == null) {
    return null;
  }

  final weight = style.fontWeight ?? FontWeight.w400;
  final normalizedWeight = weight.value >= FontWeight.w600.value
      ? FontWeight.w700
      : FontWeight.w400;

  return style.copyWith(fontWeight: normalizedWeight);
}

class AppBootstrapGate extends ConsumerWidget {
  const AppBootstrapGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrapAsync = ref.watch(appBootstrapProvider);

    return bootstrapAsync.when(
      data: (_) => DoubleBackToCloseApp(child: const HomeShell()),
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Park veritabanı hazırlanıyor...'),
            ],
          ),
        ),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: 12),
                Text(
                  'Başlatma sırasında hata oluştu:\n$error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(appBootstrapProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
