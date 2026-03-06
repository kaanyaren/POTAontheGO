import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pota_on_the_go/main.dart';

void main() {
  testWidgets('shows bootstrap loading state', (WidgetTester tester) async {
    final bootstrapCompleter = Completer<void>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appBootstrapProvider.overrideWith((ref) => bootstrapCompleter.future),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pump();

    expect(find.text('Park veritabanı hazırlanıyor...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
