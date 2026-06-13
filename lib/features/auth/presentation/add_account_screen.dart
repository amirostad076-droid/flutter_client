import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/auth/presentation/widgets/login_form.dart';
import 'package:fluxer_app/features/auth/providers/login_view_model.dart';
import 'package:fluxer_app/features/shell/presentation/responsive_layout.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AddAccountScreen extends ConsumerStatefulWidget {
  const AddAccountScreen({this.prefillEmail, super.key});

  final String? prefillEmail;

  @override
  ConsumerState<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends ConsumerState<AddAccountScreen> {
  String? _initialUserId;

  @override
  void initState() {
    super.initState();
    _initialUserId = ref.read(currentUserIdProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final LoginViewModel notifier = ref.read(loginViewModelProvider.notifier);
      notifier.hideAccountSelector();
      if (widget.prefillEmail != null) {
        notifier.updateEmail(widget.prefillEmail!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(currentUserIdProvider, (
      String? previous,
      String? next,
    ) {
      if (next != null && next != _initialUserId && mounted) {
        Navigator.of(context).pop();
      }
    });

    final layout = context.layout;
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.backgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: PhosphorIcon(
            PhosphorIconsRegular.x,
            color: context.colors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isMobileLayout(context) ? double.infinity : 420),
            child: Padding(
              padding: EdgeInsets.all(layout.s5),
              child: LoginForm(
                showBrowserLogin: false,
                heading: l10n.accountAdd,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
