import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:sudoku/src/modules/auth/presentation/bloc/auth_cubit.dart';
import 'package:sudoku/src/modules/auth/presentation/components/account_button.dart';
import 'package:sudoku/src/modules/leaderboard/domain/model/player_standing.dart';
import 'package:sudoku/src/modules/leaderboard/domain/usecase/get_my_score_use_case.dart';
import 'package:sudoku/src/modules/leaderboard/presentation/bloc/my_score_cubit.dart';
import 'package:sudoku/src/modules/leaderboard/presentation/components/status_message.dart';
import 'package:sudoku/src/modules/leaderboard/presentation/leaderboard_navigation.dart';
import 'package:sudoku/src/theme/app_theme.dart';

/// The signed-in player's totals, with the way to the leaderboard and to
/// sign out.
class MyScoreScreen extends StatelessWidget {
  const MyScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: const Text(
          'My score',
          style: TextStyle(color: GameColors.onBackground, fontSize: 16),
        ),
      ),
      body: SafeArea(
        // Leave once signed out, whether by the button or an expired session.
        child: BlocListener<AuthCubit, AuthState>(
          listenWhen: (previous, current) =>
              previous.signedIn && !current.signedIn,
          listener: (context, _) => Navigator.of(context).maybePop(),
          child: BlocBuilder<MyScoreCubit, MyScoreState>(
            builder: (context, state) {
              final cubit = context.read<MyScoreCubit>();
              switch (state.status) {
                case MyScoreStatus.loading:
                  return const Center(child: CircularProgressIndicator());
                case MyScoreStatus.failed:
                  return StatusMessage(
                    state.message ?? GetMyScoreUseCase.failedMessage,
                    error: true,
                    actionLabel: 'Retry',
                    onAction: cubit.load,
                  );
                case MyScoreStatus.signInRequired:
                  return StatusMessage(
                    'Your sign-in has expired. Sign in again to see your '
                    'score.',
                    actionLabel: 'Sign in',
                    onAction: () async {
                      await signIn(context);
                      if (context.mounted &&
                          context.read<AuthCubit>().state.signedIn) {
                        await cubit.load();
                      }
                    },
                  );
                case MyScoreStatus.ready:
                  return RefreshIndicator.adaptive(
                    onRefresh: () => cubit.load(refresh: true),
                    child: _buildStanding(context, state.standing!),
                  );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStanding(BuildContext context, PlayerStanding standing) {
    final rank = standing.rank;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          standing.name,
          textAlign: TextAlign.center,
          style: const TextStyle(color: GameColors.muted, fontSize: 18),
        ),
        const SizedBox(height: 24),
        Semantics(
          label: '${standing.score} points',
          excludeSemantics: true,
          child: Column(
            children: [
              Text(
                '${standing.score}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: GameColors.accent,
                  fontSize: 56,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const Text(
                'points',
                textAlign: TextAlign.center,
                style: TextStyle(color: GameColors.subtle, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'Puzzles solved',
                value: '${standing.puzzlesCompleted}',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _Stat(
                label: 'Rank',
                value: rank == null ? '—' : '#$rank',
                semanticValue: rank == null ? 'not ranked yet' : '$rank',
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        PlatformElevatedButton(
          onPressed: () => openLeaderboard(context),
          child: const Text('Leaderboard'),
        ),
        const SizedBox(height: 8),
        PlatformTextButton(
          onPressed: () => context.read<AuthCubit>().signOut(),
          child: const Text(
            'Sign out',
            style: TextStyle(color: GameColors.errorText),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String? semanticValue;

  const _Stat({required this.label, required this.value, this.semanticValue});

  @override
  Widget build(BuildContext context) {
    // its own node, or the two tiles in a row are read as one
    return Semantics(
      container: true,
      label: '$label: ${semanticValue ?? value}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: GameColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: GameColors.onBackground,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: GameColors.subtle, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
