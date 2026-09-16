import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orcafacil_pro/main.dart';

void main() {
  testWidgets('Teste inicial do OrcaFacilPro', (WidgetTester tester) async {
    await tester.pumpWidget(const OrcaFacilProApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}