import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_companion/app.dart';

void main() {
  testWidgets('Workspace home renders the redesigned cards', (tester) async {
    await tester.pumpWidget(const StudyCompanionApp(loadFromDatabase: false));
    await tester.pump();
    expect(find.text('龙哥公考学习工作台'), findsOneWidget);
    expect(find.text('考试倒计时'), findsOneWidget);
    expect(find.text('番茄钟'), findsOneWidget);
  });

  testWidgets('Editing daily summary does not rebuild the dialog per keystroke', (
    tester,
  ) async {
    await tester.pumpWidget(const StudyCompanionApp(loadFromDatabase: false));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.insights_outlined));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('复查 / 编辑'),
      500,
      scrollable: find.byType(Scrollable, skipOffstage: false).last,
    );
    await tester.tap(find.text('复查 / 编辑'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '今日完成数量关系练习');
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('今日完成数量关系练习'), findsOneWidget);
  });

  testWidgets('Adding a wrong question can be cancelled or saved safely', (
    tester,
  ) async {
    await tester.pumpWidget(const StudyCompanionApp(loadFromDatabase: false));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.insights_outlined));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('新增错题'),
      700,
      scrollable: find.byType(Scrollable, skipOffstage: false).last,
    );

    await tester.tap(find.text('新增错题'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('新增错题'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '数量关系错题记录');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('数量关系错题记录'), findsOneWidget);
  });
}
