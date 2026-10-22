import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymbar_trainer/ui/shell.dart';

void main() {
  testWidgets('karta Materiály pro vaše fitko ukáže odkaz na /fitka',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: GymKitCard()),
    ));
    expect(find.text('https://gymbar.app/fitka'), findsOneWidget);
    expect(find.byIcon(Icons.copy), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new), findsOneWidget);
  });
}
