import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yevmiye_takip/app.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const YevmiyeTakipApp());
    expect(find.text('İşçi Listesi'), findsOneWidget);
  });
}
