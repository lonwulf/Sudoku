import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:sudoku/src/modules/auth/presentation/bloc/auth_cubit.dart';
import 'package:sudoku/src/theme/app_theme.dart';

/// App bar account icon: signs in, or shows who is signed in and signs out.
class AccountButton extends StatelessWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final user = auth.user;
    if (auth.busy) {
      return const SizedBox(
        width: 48,
        child: Center(child: PlatformCircularProgressIndicator()),
      );
    }
    return Semantics(
      button: true,
      label: user == null ? 'Sign in' : 'Signed in as ${user.name}',
      excludeSemantics: true,
      child: PlatformIconButton(
        icon: Icon(
          user == null
              ? context.platformIcon(
                  material: Icons.person_outline,
                  cupertino: CupertinoIcons.person,
                )
              : context.platformIcon(
                  material: Icons.person,
                  cupertino: CupertinoIcons.person_fill,
                ),
          color: user == null ? GameColors.onBackground : GameColors.accent,
        ),
        onPressed: () =>
            user == null ? signIn(context) : _showAccount(context, user.name),
      ),
    );
  }

  Future<void> _showAccount(BuildContext context, String name) async {
    final signOut = await showPlatformDialog<bool>(
      context: context,
      builder: (dialogContext) => PlatformAlertDialog(
        title: const Text('Account'),
        content: Text('Signed in as $name'),
        actions: [
          PlatformDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            cupertino: (_, __) =>
                CupertinoDialogActionData(isDestructiveAction: true),
            child: const Text('Sign out'),
          ),
          PlatformDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    if (signOut == true && context.mounted) {
      await context.read<AuthCubit>().signOut();
    }
  }
}

/// Opens the sign-in page, explaining if it couldn't be reached.
Future<void> signIn(BuildContext context) async {
  final error = await context.read<AuthCubit>().signIn();
  if (error == null || !context.mounted) return;
  await showPlatformDialog<void>(
    context: context,
    builder: (dialogContext) => PlatformAlertDialog(
      title: const Text('Sign in failed'),
      content: Text(error),
      actions: [
        PlatformDialogAction(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
