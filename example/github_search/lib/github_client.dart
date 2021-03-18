import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'search_result.dart';

class GithubClient {
  final String baseUrl;
  final Map<String, SearchResult> cache;
  final HttpClient client;

  GithubClient({
    HttpClient? client,
    Map<String, SearchResult>? cache,
    this.baseUrl = 'https://api.github.com/search/repositories?q=',
  })  : client = client ?? HttpClient(),
        cache = cache ?? <String, SearchResult>{};

  /// Search Github for repositories using the given term
  Future<SearchResult> search(String term) async {
    if (term.isEmpty) {
      return SearchResult.noTerm();
    } else if (cache.containsKey(term)) {
      return cache[term]!;
    } else {
      final result = await _fetchResults(term);

      cache[term] = result;

      return result;
    }
  }

  Future<SearchResult> _fetchResults(String term) async {
    final request = await HttpClient().getUrl(Uri.parse('$baseUrl$term'));
    final response = await request.close();
    final results = json.decode(await response.transform(utf8.decoder).join())
        as Map<String, dynamic>;
    final items = (results['items'] as List).cast<Map<String, dynamic>>();

    return SearchResult.fromJson(items);
  }
}
