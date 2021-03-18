enum SearchResultKind { noTerm, empty, populated }

class SearchResult {
  final SearchResultKind kind;
  final List<SearchResultItem> items;

  SearchResult(this.kind, this.items);

  factory SearchResult.noTerm() =>
      SearchResult(SearchResultKind.noTerm, <SearchResultItem>[]);

  factory SearchResult.fromJson(List<Map<String, dynamic>> list) {
    final items = [for (final item in list) SearchResultItem.fromJson(item)];

    return SearchResult(
      items.isEmpty ? SearchResultKind.empty : SearchResultKind.populated,
      items,
    );
  }

  bool get isPopulated => kind == SearchResultKind.populated;

  bool get isEmpty => kind == SearchResultKind.empty;

  bool get isNoTerm => kind == SearchResultKind.noTerm;
}

class SearchResultItem {
  final String fullName;
  final String url;
  final String avatarUrl;

  SearchResultItem(this.fullName, this.url, this.avatarUrl);

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    return SearchResultItem(
      json['full_name'] as String,
      json['html_url'] as String,
      (json['owner'] as Map<String, dynamic>)['avatar_url'] as String,
    );
  }
}
