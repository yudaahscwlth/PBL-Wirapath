import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A page the user recently visited, shown on the home "Continue Working" card.
class RecentPage {
  final String route;
  final String title;
  final String type; // 'project' | 'simulation' | 'review' | 'page'

  const RecentPage({required this.route, required this.title, required this.type});

  Map<String, dynamic> toMap() => {'route': route, 'title': title, 'type': type};

  factory RecentPage.fromMap(Map<String, dynamic> m) => RecentPage(
        route: m['route'] as String? ?? '/home',
        title: m['title'] as String? ?? '',
        type: m['type'] as String? ?? 'page',
      );
}

class RecentActivityNotifier extends Notifier<List<RecentPage>> {
  static const _prefsKey = 'recent_pages_v1';

  @override
  List<RecentPage> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => RecentPage.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      state = list;
    } catch (_) {
      // Corrupt cache — ignore and start fresh.
    }
  }

  /// Records a page visit. Most recent first, deduped by route, capped at 3.
  void record({required String route, required String title, required String type}) {
    final updated = [
      RecentPage(route: route, title: title, type: type),
      ...state.where((p) => p.route != route),
    ].take(3).toList();
    state = updated;
    _save(updated);
  }

  Future<void> _save(List<RecentPage> pages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(pages.map((p) => p.toMap()).toList()));
  }
}

final recentActivityProvider =
    NotifierProvider<RecentActivityNotifier, List<RecentPage>>(RecentActivityNotifier.new);
