import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';

import 'package:snaptask_reminder/main.dart';
import 'package:snaptask_reminder/models/task.dart';

void main() {
  setUp(() async {
    await setUpTestHive();
    Hive.registerAdapter(TaskAdapter());
    await Hive.openBox<Task>('tasks');
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  testWidgets('Shows empty task list state', (WidgetTester tester) async {
    await tester.pumpWidget(const SnapTaskApp());
    await tester.pumpAndSettle();

    expect(find.text('SnapTask Reminder'), findsOneWidget);
    expect(find.textContaining('No tasks yet'), findsOneWidget);
  });
}
