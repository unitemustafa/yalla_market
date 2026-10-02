part of 'address_location_picker_view.dart';

extension _AddressLocationPickerSearch on _AddressLocationPickerViewState {
  Widget _buildSearchPage() {
    return ColoredBox(
      key: const ValueKey('map-picker-search-page'),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                CompactMapButton(
                  key: const ValueKey('map-picker-search-close'),
                  onPressed: _closeSearch,
                  icon: Icons.close_rounded,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  elevation: 0,
                  borderColor: Theme.of(context).dividerColor,
                ),
                const SizedBox(width: 10),
                Expanded(child: _buildSearchField()),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          Expanded(child: _buildSearchContent()),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return AppSearchField(
      key: const ValueKey('map-picker-search-field'),
      controller: _searchController,
      focusNode: _searchFocus,
      onChanged: _onSearchChanged,
      hintText: 'Search for a place in Egypt',
    );
  }

  Widget _buildSearchContent() {
    return AddressLocationSearchContent(
      isSearching: _isSearching,
      searchFailed: _searchFailed,
      results: _searchResults,
      failureMessage: context.tr('Place search failed.'),
      retryLabel: context.tr('Retry'),
      onRetry: _retrySearch,
      onSelected: _selectSearchResult,
    );
  }
}
