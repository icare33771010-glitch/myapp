// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/main.dart'; // നിങ്ങളുടെ പാക്കേജ് പേര് ശരിയാണെന്ന് ഉറപ്പുവരുത്തുക

void main() {
  testWidgets('Ledger app smoke test', (WidgetTester tester) async {
    // ആപ്പ് ലോഡ് ചെയ്യുന്നു
    await tester.pumpWidget(ExpenseApp());

    // 'Accounting Ledger' എന്ന ടൈറ്റിൽ സ്ക്രീനിൽ ഉണ്ടോ എന്ന് പരിശോധിക്കുന്നു
    expect(find.text('Accounting Ledger'), findsOneWidget);

    // 'ADD TRANSACTION' ബട്ടൺ ഉണ്ടോ എന്ന് നോക്കുന്നു
    expect(find.text('ADD TRANSACTION'), findsOneWidget);

    // Floating Action Button (Add Group) ഉണ്ടോ എന്ന് നോക്കുന്നു
    expect(find.byIcon(Icons.group_add), findsOneWidget);
  });
}
