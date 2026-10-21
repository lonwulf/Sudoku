import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:sudoku/src/modules/auth/presentation/bloc/auth_cubit.dart';
import 'package:sudoku/src/modules/auth/presentation/components/account_button.dart';
import 'package:sudoku/src/modules/leaderboard/domain/model/leaderboard_entry.dart';
import 'package:sudoku/src/modules/leaderboard/domain/usecase/get_leaderboard_use_case.dart';
import 'package:sudoku/src/modules/leaderboard/presentation/bloc/leaderboard_cubit.dart';
import 'package:sudoku/src/modules/leaderboard/presentation/components/status_message.dart';
import 'package:sudoku/src/theme/app_theme.dart';

/// Top players page by page, with the player's own rank pinned at the top
/// and the players around them when they are further down.
class LeaderboardScreen extends StatelessWidget {
  /// Load the next page when this close to the end of the list.
  static const _loadMoreExtent = 400.0;

  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: const Text(
          'Leaderboard',
          style: TextStyle(color: GameColors.onBackground, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<LeaderboardCubit, LeaderboardState>(
          builder: (context, state) {
            final cubit = context.read<LeaderboardCubit>();
            switch (state.status) {
              case LeaderboardStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case LeaderboardStatus.warmingUp:
                return StatusMessage(
                  state.message ?? LeaderboardCubit.warmingUpMessage,
                  busy: true,
                );
              case LeaderboardStatus.failed:
                return StatusMessage(
                  state.message ?? GetLeaderboardUseCase.failedMessage,
                  error: true,
                  actionLabel: 'Retry',
                  onAction: cubit.load,
                );
              case LeaderboardStatus.signInRequired:
                return StatusMessage(
                  'Sign in to see the leaderboard.',
                  actionLabel: 'Sign in',
                  onAction: () async {
                    await signIn(context);
                    if (context.mounted &&
                        context.read<AuthCubit>().state.signedIn) {
                      await cubit.load();
                    }
                  },
                );
              case LeaderboardStatus.ready:
                return RefreshIndicator.adaptive(
                  onRefresh: () => cubit.load(refresh: true),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.extentAfter < _loadMoreExtent) {
                        cubit.loadMore();
                      }
                      return false;
                    },
                    child: _buildBoard(context, state),
                  ),
                );
            }
          },
        ),
      ),
    );
  }

  Widget _buildBoard(BuildContext context, LeaderboardState state) {
    final myId = state.me?.userId ?? context.read<AuthCubit>().state.user?.id;
    // Rows: a String is a section header, an entry is a player, and the
    // markers are the "you" card and the paging footer.
    final rows = <Object>[
      _youCard,
      if (state.showNearby) ...['Around you', ...state.nearby],
      'Top players',
      if (state.top.isEmpty) _noScores else ...state.top,
      _footer,
    ];
    return ListView.builder(
      // pull-to-refresh needs a scrollable list even when it is short
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: rows.length,
      itemBuilder: (context, index) => switch (rows[index]) {
        final String header => _SectionHeader(header),
        final LeaderboardEntry entry => _EntryRow(
          entry,
          isMe: entry.userId == myId,
        ),
        _youCard => _YouCard(state.me),
        _noScores => const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No scores yet. Solve a puzzle to be first.',
            textAlign: TextAlign.center,
            style: TextStyle(color: GameColors.muted, fontSize: 14),
          ),
        ),
        _ => _buildFooter(context, state),
      },
    );
  }

  Widget _buildFooter(BuildContext context, LeaderboardState state) {
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.loadMoreFailed) {
      return Center(
        child: PlatformTextButton(
          onPressed: context.read<LeaderboardCubit>().loadMore,
          child: const Text("Couldn't load more. Retry"),
        ),
      );
    }
    return const SizedBox(height: 16);
  }
}

const _youCard = #youCard;
const _noScores = #noScores;
const _footer = #footer;

class _YouCard extends StatelessWidget {
  final LeaderboardEntry? me;

  const _YouCard(this.me);

  @override
  Widget build(BuildContext context) {
    final me = this.me;
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GameColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: me == null
          ? const Text(
              'Solve a puzzle while signed in to join the board.',
              textAlign: TextAlign.center,
              style: TextStyle(color: GameColors.muted, fontSize: 14),
            )
          : Semantics(
              label: 'You are ranked ${me.rank} with ${me.score} points',
              excludeSemantics: true,
              child: Row(
                children: [
                  Expanded(child: _figure('#${me.rank}', 'Your rank')),
                  Expanded(child: _figure('${me.score}', 'Points')),
                ],
              ),
            ),
    );
  }

  Widget _figure(String value, String label) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(color: GameColors.accent, fontSize: 28),
      ),
      Text(
        label,
        style: const TextStyle(color: GameColors.subtle, fontSize: 12),
      ),
    ],
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: const TextStyle(
            color: GameColors.subtle,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isMe;

  const _EntryRow(this.entry, {required this.isMe});

  @override
  Widget build(BuildContext context) {
    final color = isMe ? GameColors.accent : GameColors.onBackground;
    return Semantics(
      label:
          'Rank ${entry.rank}, ${entry.name}${isMe ? ', you' : ''}, '
          '${entry.score} points',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? GameColors.surface : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Text(
                '#${entry.rank}',
                style: TextStyle(color: color.withValues(alpha: 0.7)),
              ),
            ),
            Expanded(
              child: Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${entry.score}',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
