bool mobileChannelScaffoldShouldResizeForKeyboard({
  required bool isChatRoute,
  required bool isExpressionPanelOpen,
}) => !isChatRoute || !isExpressionPanelOpen;

bool mobileChannelScaffoldShouldRemoveKeyboardInset({
  required bool isChatRoute,
  required bool isExpressionPanelOpen,
}) => false;
