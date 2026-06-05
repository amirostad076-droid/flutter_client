import 'dart:async';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/media/fluxer_media_url.dart';
import 'package:fluxer_app/core/permissions/channel_effective_permissions.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/providers/gateway_connection_provider.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/presentation/widgets/channel_icon.dart';
import 'package:fluxer_app/features/channels/providers/channel_list_view_model.dart';
import 'package:fluxer_app/features/chat/data/composer_autocomplete_members.dart';
import 'package:fluxer_app/features/chat/providers/pickers/emoji_picker_provider.dart';
import 'package:fluxer_app/features/chat/service/composer_autocomplete_trigger.dart';
import 'package:fluxer_app/features/chat/service/composer_mention_controller.dart';
import 'package:fluxer_app/features/chat/utils/composer_mention_query.dart';
import 'package:fluxer_app/features/dm/domain/dm_conversation.dart';
import 'package:fluxer_app/features/dm/providers/dm_view_model.dart';
import 'package:fluxer_app/features/members/data/member_repository.dart';
import 'package:fluxer_app/features/members/domain/member.dart';
import 'package:fluxer_app/features/members/providers/member_list_view_model.dart';
import 'package:fluxer_app/features/members/providers/member_providers.dart';
import 'package:fluxer_app/features/ui/avatar/fluxer_avatar.dart';
import 'package:fluxer_app/features/ui/input/emoji_inline_token.dart';
import 'package:fluxer_app/features/ui/input/inline_token_text_editing_controller.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/shared/utils/chat_context_utils.dart';
import 'package:fluxer_app/shared/utils/emoji_registry.dart';

part 'composer_autocomplete_field_state.dart';
part 'composer_autocomplete_panel.dart';

class ComposerAutocompleteChatField extends ConsumerStatefulWidget {
  const ComposerAutocompleteChatField({
    required this.controller,
    required this.focusNode,
    required this.channelId,
    required this.decoration,
    required this.style,
    required this.minLines,
    required this.maxLines,
    required this.enabled,
    required this.menuOpenListenable,
    required this.panelHost,
    required this.panelScrollController,
    this.textAlignVertical,
    this.inputFormatters,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String channelId;
  final InputDecoration decoration;
  final TextStyle? style;
  final int minLines;
  final int? maxLines;
  final bool enabled;
  final ComposerAutocompleteMenuNotifier menuOpenListenable;
  final ComposerAutocompletePanelHost panelHost;
  final ScrollController panelScrollController;
  final TextAlignVertical? textAlignVertical;
  final List<TextInputFormatter>? inputFormatters;

  @override
  ConsumerState<ComposerAutocompleteChatField> createState() =>
      ComposerAutocompleteChatFieldState();
}
