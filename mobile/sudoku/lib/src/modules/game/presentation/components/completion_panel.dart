import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:sudoku/src/modules/auth/presentation/components/account_button.dart';
import 'package:sudoku/src/modules/game/domain/model/submit_outcome.dart';
import 'package:sudoku/src/modules/game/presentation/bloc/submit_cubit.dart';
import 'package:sudoku/src/theme/app_theme.dart';

/// Replaces the number pad once the puzzle is solved: how the score was
/// saved, and a way into the next game.
class CompletionPanel extends StatelessWidget {
  final VoidCallback onNewGame;

  const CompletionPanel({super.key, required this.onNewGame});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Solved!',
            style: TextStyle(
              color: GameColors.accent,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          BlocBuilder<SubmitCubit, SubmitState>(
            builder: (context, state) => switch (state) {
              SubmitIdle() ||
              Submitting() => const _Status('Saving your score…', busy: true),
              Submitted(:final outcome) => _buildOutcome(context, outcome),
            },
          ),
          const SizedBox(height: 20),
          PlatformElevatedButton(
            onPressed: onNewGame,
            child: const Text('New game'),
          ),
        ],
      ),
    );
  }

  Widget _buildOutcome(BuildContext context, SubmitOutcome outcome) {
    switch (outcome) {
      case Scored(:final result):
        final rank = result.rank;
        return _Status(
          [
            'Score ${result.score}',
            if (rank != null) 'Rank #$rank',
            '${result.puzzlesCompleted} solved',
          ].join(' · '),
        );
      case SignInRequired():
        return Column(
          children: [
            const _Status('Sign in to save your score.'),
            PlatformTextButton(
              onPressed: () => signIn(context),
              child: const Text('Sign in'),
            ),
          ],
        );
      case Rejected(:final message):
        return _Status(message, error: true);
      case SubmitFailed(:final message):
        return Column(
          children: [
            _Status(message, error: true),
            PlatformTextButton(
              onPressed: () => context.read<SubmitCubit>().retry(),
              child: const Text('Retry'),
            ),
          ],
        );
    }
  }
}

class _Status extends StatelessWidget {
  final String text;
  final bool busy;
  final bool error;

  const _Status(this.text, {this.busy = false, this.error = false});

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: error ? GameColors.errorText : GameColors.muted,
        fontSize: 16,
      ),
    );
    if (!busy) return label;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Flexible(child: label),
      ],
    );
  }
}
