// lib/services/search/jack_live_search_service.dart
//
// Real Live Web Search & Image Grounding Service for JACK Mobile Agent.
// Fetches real web summaries, authentic source links, and verified images
// from open web APIs (Wikipedia, Wikimedia Commons, DuckDuckGo) without fake data.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LiveSearchImage {
  final String imageUrl;
  final String title;
  final String sourceUrl;
  final String sourceName;

  const LiveSearchImage({
    required this.imageUrl,
    required this.title,
    required this.sourceUrl,
    required this.sourceName,
  });
}

class LiveSearchResult {
  final String query;
  final String summary;
  final List<LiveSearchImage> images;
  final List<Map<String, String>> sourceLinks;

  const LiveSearchResult({
    required this.query,
    required this.summary,
    required this.images,
    required this.sourceLinks,
  });
}

class JackLiveSearchService {
  JackLiveSearchService._();
  static final JackLiveSearchService instance = JackLiveSearchService._();

  final http.Client _client = http.Client();

  /// Performs live web search & real source image retrieval
  Future<LiveSearchResult> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return const LiveSearchResult(
        query: '',
        summary: '',
        images: [],
        sourceLinks: [],
      );
    }

    final List<LiveSearchImage> gatheredImages = [];
    final List<Map<String, String>> gatheredLinks = [];
    final StringBuffer summaryBuffer = StringBuffer();

    // 1. Query Wikipedia API for grounded knowledge and verified high-res images
    try {
      final wikiUri = Uri.parse(
        'https://en.wikipedia.org/w/api.php?action=query&format=json&generator=search'
        '&gsrsearch=${Uri.encodeComponent(cleanQuery)}&gsrlimit=3&prop=pageimages|extracts'
        '&pithumbsize=800&exintro=1&explaintext=1&exsentences=3',
      );

      final wikiResp = await _client.get(wikiUri).timeout(const Duration(seconds: 4));
      if (wikiResp.statusCode == 200) {
        final data = jsonDecode(wikiResp.body);
        final pages = data['query']?['pages'];
        if (pages is Map) {
          for (var page in pages.values) {
            final title = page['title']?.toString() ?? '';
            final extract = page['extract']?.toString() ?? '';
            final thumb = page['thumbnail']?['source']?.toString();
            final pageId = page['pageid']?.toString() ?? '';

            if (extract.isNotEmpty && summaryBuffer.length < 500) {
              summaryBuffer.writeln(extract);
            }

            if (title.isNotEmpty) {
              final pageUrl = 'https://en.wikipedia.org/?curid=$pageId';
              gatheredLinks.add({
                'title': '$title — Wikipedia',
                'url': pageUrl,
              });
            }

            if (thumb != null && thumb.startsWith('http')) {
              gatheredImages.add(LiveSearchImage(
                imageUrl: thumb,
                title: title,
                sourceUrl: 'https://en.wikipedia.org/?curid=$pageId',
                sourceName: 'Wikipedia',
              ));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Wiki search error: $e');
    }

    // 2. Query DuckDuckGo Instant Answer API for live answers & icon images
    try {
      final ddgUri = Uri.parse(
        'https://api.duckduckgo.com/?q=${Uri.encodeComponent(cleanQuery)}&format=json&no_html=1&skip_disambig=1',
      );

      final ddgResp = await _client.get(ddgUri).timeout(const Duration(seconds: 3));
      if (ddgResp.statusCode == 200) {
        final data = jsonDecode(ddgResp.body);
        final abstractText = data['AbstractText']?.toString() ?? '';
        final abstractUrl = data['AbstractURL']?.toString() ?? '';
        final ddgImage = data['Image']?.toString() ?? '';
        final heading = data['Heading']?.toString() ?? cleanQuery;

        if (abstractText.isNotEmpty && summaryBuffer.isEmpty) {
          summaryBuffer.writeln(abstractText);
        }

        if (abstractUrl.isNotEmpty) {
          gatheredLinks.add({
            'title': '$heading — Source Reference',
            'url': abstractUrl,
          });
        }

        if (ddgImage.isNotEmpty && ddgImage.startsWith('http')) {
          gatheredImages.add(LiveSearchImage(
            imageUrl: ddgImage,
            title: heading,
            sourceUrl: abstractUrl.isNotEmpty ? abstractUrl : 'https://duckduckgo.com/?q=${Uri.encodeComponent(cleanQuery)}',
            sourceName: 'DuckDuckGo',
          ));
        }

        // Check related topics for images
        final related = data['RelatedTopics'];
        if (related is List) {
          for (var item in related) {
            if (item is Map && gatheredImages.length < 4) {
              final iconUrl = item['Icon']?['URL']?.toString();
              final text = item['Text']?.toString() ?? '';
              final firstUrl = item['FirstURL']?.toString() ?? '';

              if (iconUrl != null && iconUrl.startsWith('http')) {
                gatheredImages.add(LiveSearchImage(
                  imageUrl: iconUrl,
                  title: text.length > 40 ? '${text.substring(0, 40)}...' : text,
                  sourceUrl: firstUrl.isNotEmpty ? firstUrl : 'https://duckduckgo.com',
                  sourceName: 'Web Reference',
                ));
              }

              if (firstUrl.isNotEmpty && gatheredLinks.length < 5) {
                gatheredLinks.add({
                  'title': text.length > 50 ? '${text.substring(0, 50)}...' : text,
                  'url': firstUrl,
                });
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('DDG search error: $e');
    }

    // 3. If image queries (or products / places / people) need visual grounding, query Wikimedia Commons
    if (gatheredImages.isEmpty) {
      try {
        final commonsUri = Uri.parse(
          'https://commons.wikimedia.org/w/api.php?action=query&generator=search'
          '&gsrnamespace=6&gsrsearch=${Uri.encodeComponent(cleanQuery)}&gsrlimit=3'
          '&prop=imageinfo&iiprop=url|size&format=json',
        );

        final commonsResp = await _client.get(commonsUri).timeout(const Duration(seconds: 3));
        if (commonsResp.statusCode == 200) {
          final data = jsonDecode(commonsResp.body);
          final pages = data['query']?['pages'];
          if (pages is Map) {
            for (var page in pages.values) {
              final title = page['title']?.toString().replaceFirst('File:', '') ?? cleanQuery;
              final imageInfo = page['imageinfo'];
              if (imageInfo is List && imageInfo.isNotEmpty) {
                final url = imageInfo[0]['url']?.toString();
                if (url != null &&
                    (url.endsWith('.jpg') || url.endsWith('.png') || url.endsWith('.jpeg') || url.endsWith('.webp'))) {
                  gatheredImages.add(LiveSearchImage(
                    imageUrl: url,
                    title: title,
                    sourceUrl: url,
                    sourceName: 'Wikimedia Commons',
                  ));
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Commons search error: $e');
      }
    }

    // 4. Always add direct Google Search reference link
    gatheredLinks.add({
      'title': 'Google Search: "$cleanQuery"',
      'url': 'https://www.google.com/search?q=${Uri.encodeComponent(cleanQuery)}',
    });

    return LiveSearchResult(
      query: cleanQuery,
      summary: summaryBuffer.toString().trim(),
      images: gatheredImages,
      sourceLinks: gatheredLinks,
    );
  }
}
