import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:production_chat_prop/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('app renders root router', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Project List'), findsOneWidget);
  });

  testWidgets('create project and navigate to chat editor from project card', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    expect(find.text('No projects yet'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('New Project 1'), findsOneWidget);

    await tester.tap(find.text('Open Chat Editor'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Chat Editor'), findsOneWidget);
    expect(find.textContaining('Scene: Scene 1'), findsOneWidget);
    expect(find.textContaining('Messages (read-only)'), findsOneWidget);
  });

  testWidgets('duplicate and delete project from popup menu', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProductionChatPropApp()),
    );
    await _ensureOnProjectList(tester);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('New Project 1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicate'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('New Project 1 Copy'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('New Project 1 Copy'), findsNothing);
    expect(find.text('New Project 1'), findsOneWidget);
  });
}

Future<void> _ensureOnProjectList(WidgetTester tester) async {
  await tester.pumpAndSettle();

  if (find.text('Project List').evaluate().isNotEmpty) {
    return;
  }

  if (find.text('Back to Projects').evaluate().isNotEmpty) {
    await tester.tap(find.text('Back to Projects').first);
    await tester.pumpAndSettle();
  }
}
