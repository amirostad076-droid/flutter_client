import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/domain/message_translation.dart';
import 'package:fluxer_app/features/chat/utils/translation_language_name.dart';
import 'package:fluxer_app/features/ui/tappable/fluxer_gesture_detector.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:material_ui/material_ui.dart';

class MessageTranslationIndicator extends StatelessWidget {
  const MessageTranslationIndicator({
    required this.translation,
    required this.onToggleOriginal,
    super.key,
  });

  final MessageTranslation translation;
  final VoidCallback onToggleOriginal;

  @override
  Widget build(BuildContext context) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final TextStyle style = context.textStyles.smallText.copyWith(
      color: context.colors.textTertiaryMuted,
      fontSize: 12,
    );
    if (translation.showOriginal) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FluxerGestureDetector(
            onTap: onToggleOriginal,
            child: Text(l10n.chatMessageSeeTranslation, style: style),
          ),
        ),
      );
    }
    final String languageName = translationLanguageDisplayName(
      translation.sourceLanguageCode,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          if (languageName.isNotEmpty)
            Text(
              '${l10n.chatMessageTranslatedFrom(languageName)}  ·  ',
              style: style,
            ),
          FluxerGestureDetector(
            onTap: onToggleOriginal,
            child: Text(l10n.chatMessageSeeOriginal, style: style),
          ),
        ],
      ),
    );
  }
}
