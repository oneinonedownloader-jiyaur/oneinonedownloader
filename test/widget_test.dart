// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:all_in_one_downloader_video/main.dart';

void main() {
  testWidgets('App starts and displays home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle(); // Wait for animations and async operations

    // Verify that the Home and Downloads tabs are present.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Downloads'), findsOneWidget);

    // Verify that the URL input field is on the screen.
    expect(find.widgetWithText(TextField, 'Paste URL here'), findsOneWidget);
  });
}
