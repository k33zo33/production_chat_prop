import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/app/app.dart';

void main() {
  testWidgets('app renders root router', (tester) async {
    await tester.pumpWidget(const ProductionChatPropApp());

    expect(find.text('Project List'), findsOneWidget);
  });
}
