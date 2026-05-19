import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/instance/instance_endpoints.dart';
import 'package:fluxer_app/core/providers/well_known_provider.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/guilds/presentation/modals/add_guild_landing_view.dart';
import 'package:fluxer_app/features/guilds/services/join_community_service.dart';
import 'package:fluxer_app/features/guilds/utils/invite_link_parser.dart';
import 'package:fluxer_app/features/ui/bottom_sheet/fluxer_bottom_sheet.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:fluxer_app/features/ui/input/fluxer_input.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum _AddGuildModalView { landing, join }

Future<void> showAddGuildModal(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.transparent,
    builder: (BuildContext dialogContext) {
      return const _AddGuildModalDialog();
    },
  );
}

class _AddGuildModalDialog extends ConsumerStatefulWidget {
  const _AddGuildModalDialog();

  @override
  ConsumerState<_AddGuildModalDialog> createState() =>
      _AddGuildModalDialogState();
}

class _AddGuildModalDialogState extends ConsumerState<_AddGuildModalDialog> {
  _AddGuildModalView _view = _AddGuildModalView.landing;
  final TextEditingController _inviteController = TextEditingController();
  String? _inviteErrorText;
  bool _isSubmitting = false;
  String _invitePlaceholder = '';
  List<String> _instanceInviteUrlBases = const <String>[];

  @override
  void initState() {
    super.initState();
    _inviteController.addListener(_onInviteInputChanged);
    unawaited(_loadInvitePlaceholder());
  }

  @override
  void dispose() {
    _inviteController
      ..removeListener(_onInviteInputChanged)
      ..dispose();
    super.dispose();
  }

  void _onInviteInputChanged() {
    setState(() {
      if (_inviteErrorText != null) {
        _inviteErrorText = null;
      }
    });
  }

  Future<void> _loadInvitePlaceholder() async {
    final String randomCode = _randomInviteCode();
    try {
      await ref.read(wellKnownProvider.future);
      final String inviteBase = ref.read(instanceInviteBaseUrlProvider);
      if (!mounted) {
        return;
      }
      setState(() {
        _instanceInviteUrlBases = <String>[inviteBase];
        _invitePlaceholder = '$inviteBase/$randomCode';
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _invitePlaceholder = '${InstanceEndpoints.defaultInvite}/$randomCode';
      });
    }
  }

  String _randomInviteCode() {
    const String chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final Random random = Random();
    final int length = random.nextInt(7) + 6;
    return List<String>.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  void _close() {
    Navigator.of(context).pop();
  }

  void _goToJoin() {
    setState(() {
      _view = _AddGuildModalView.join;
      _inviteErrorText = null;
    });
  }

  String _title(FluxerLocalizations l10n) => switch (_view) {
    _AddGuildModalView.landing => l10n.addGuildModalTitle,
    _AddGuildModalView.join => l10n.addGuildJoinTitle,
  };

  bool get _canSubmitJoin {
    if (_isSubmitting) {
      return false;
    }
    return parseInviteCode(
          _inviteController.text,
          inviteUrlBases: _instanceInviteUrlBases,
        ) !=
        null;
  }

  Future<void> _submitJoin() async {
    if (!_canSubmitJoin) {
      return;
    }
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    setState(() {
      _isSubmitting = true;
      _inviteErrorText = null;
    });
    try {
      await joinCommunityViaInvite(
        ref: ref,
        rawInput: _inviteController.text,
        l10n: l10n,
      );
      if (!mounted) {
        return;
      }
      _close();
    } on JoinCommunityException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _inviteErrorText = e.message);
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _inviteErrorText = l10n.addGuildJoinFailed);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final layout = context.layout;
    final dialogTheme = DialogTheme.of(context);
    final themeShape = dialogTheme.shape as RoundedRectangleBorder?;
    final mediaQuery = MediaQuery.of(context);
    final double keyboardInset = mediaQuery.viewInsets.bottom;
    final double maxModalHeight =
        mediaQuery.size.height - mediaQuery.viewPadding.top - layout.s2;
    final closeButton = Opacity(
      opacity: 0.7,
      child: FluxerButton.ghost(
        onPressed: _close,
        icon: PhosphorIconsBold.x,
        isSquare: true,
      ),
    );
    final Widget body = switch (_view) {
      _AddGuildModalView.landing => AddGuildLandingView(onJoinTap: _goToJoin),
      _AddGuildModalView.join => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.addGuildJoinDescription,
            style: context.textStyles.bodySmall.copyWith(
              color: context.colors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          FluxerInput(
            controller: _inviteController,
            label: l10n.addGuildInviteLinkLabel,
            hint: _invitePlaceholder.isEmpty ? null : _invitePlaceholder,
            errorText: _inviteErrorText,
            autofocus: true,
            maxLength: 100,
            enabled: !_isSubmitting,
            onSubmitted: (_) => unawaited(_submitJoin()),
          ),
        ],
      ),
    };
    final List<Widget> footerActions = switch (_view) {
      _AddGuildModalView.landing => const <Widget>[],
      _AddGuildModalView.join => <Widget>[
        FluxerButton.primary(
          onPressed: _canSubmitJoin ? () => unawaited(_submitJoin()) : null,
          isLoading: _isSubmitting,
          label: l10n.addGuildJoinSubmit,
        ),
      ],
    };
    Widget buildModalContent() {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: maxModalHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: layout.s4, bottom: layout.s4),
              child: FluxerBottomSheetHeader(
                title: _title(l10n),
                trailing: closeButton,
              ),
            ),
            Flexible(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  layout.s4,
                  0,
                  layout.s4,
                  layout.s4,
                ),
                child: SingleChildScrollView(child: body),
              ),
            ),
            if (footerActions.isNotEmpty)
              FluxerBottomSheetFooter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: footerActions,
                ),
              ),
          ],
        ),
      );
    }

    final Widget dialog = Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: layout.radiusXxl,
        side: themeShape?.side ?? BorderSide.none,
      ),
      child: buildModalContent(),
    );
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            onTap: _close,
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.35),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        AnimatedPadding(
          duration: context.motion.normal,
          curve: context.motion.curve,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: MediaQuery.removeViewInsets(
            context: context,
            removeBottom: true,
            child: keyboardInset > 0
                ? Align(
                    alignment: Alignment.bottomCenter,
                    child: dialog,
                  )
                : Center(child: dialog),
          ),
        ),
      ],
    );
  }
}
