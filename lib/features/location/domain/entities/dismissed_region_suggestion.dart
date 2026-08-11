class DismissedRegionSuggestion {
  const DismissedRegionSuggestion({
    required this.suggestionKey,
    required this.dismissedAt,
  });

  final String suggestionKey;
  final DateTime dismissedAt;
}
