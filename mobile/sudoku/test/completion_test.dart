import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/src/modules/game/domain/model/difficulty.dart';

import 'fixtures.dart';

void main() {
  Future<void> solve(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Row 1, column 1, empty'));
    await tester.tap(find.bySemanticsLabel('Enter 1'));
    await tester.pumpAndSettle();
  }

  testWidgets('solving the puzzle saves the score', (tester) async {
    final repository = FakeMainRepository();
    await tester.pumpWidget(
      testApp(
        bloc: testBloc(useCase: FakeUseCase(game: nearlySolvedGame)),
        auth: FakeAuthService(user: testUser),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    await solve(tester);

    expect(find.text('Solved!'), findsOneWidget);
    expect(find.text('Score 40 · Rank #2 · 3 solved'), findsOneWidget);
    expect(find.bySemanticsLabel('Enter 5'), findsNothing);
    expect(repository.submitted, ['nearly']);
  });

  testWidgets('a signed-out player can sign in to save the score', (
    tester,
  ) async {
    final auth = FakeAuthService();
    final repository = FakeMainRepository();
    await tester.pumpWidget(
      testApp(
        bloc: testBloc(useCase: FakeUseCase(game: nearlySolvedGame)),
        auth: auth,
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    await solve(tester);
    expect(find.text('Sign in to save your score.'), findsOneWidget);
    expect(repository.submitted, isEmpty);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(auth.signIns, 1);
    expect(repository.submitted, ['nearly']);
    expect(find.text('Score 40 · Rank #2 · 3 solved'), findsOneWidget);
  });

  testWidgets('new game asks for a difficulty', (tester) async {
    final useCase = FakeUseCase();
    await tester.pumpWidget(testApp(bloc: testBloc(useCase: useCase)));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('New game'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a difficulty.'), findsOneWidget);

    await tester.tap(find.text('Hard'));
    await tester.pumpAndSettle();

    expect(useCase.calls, 2);
    expect(useCase.lastDifficulty, Difficulty.hard);
  });

  testWidgets('new game warns before abandoning a started puzzle', (
    tester,
  ) async {
    final useCase = FakeUseCase();
    await tester.pumpWidget(testApp(bloc: testBloc(useCase: useCase)));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Row 1, column 1, empty'));
    await tester.tap(find.bySemanticsLabel('Enter 5'));
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('New game'));
    await tester.pumpAndSettle();
    expect(
      find.text('Choose a difficulty. Your current puzzle will be lost.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(useCase.calls, 1);
  });

  testWidgets('the account button signs in and out', (tester) async {
    await tester.pumpWidget(testApp(auth: FakeAuthService()));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Sign in'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Signed in as Test Player'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Signed in as Test Player'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Sign in'), findsOneWidget);
  });

  testWidgets('the solved screen fits a 320x568 screen', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      testApp(
        bloc: testBloc(useCase: FakeUseCase(game: nearlySolvedGame)),
        auth: FakeAuthService(),
      ),
    );
    await tester.pumpAndSettle();

    await solve(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('New game'), findsOneWidget);
  });
}
