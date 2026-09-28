import 'package:shared_preferences/shared_preferences.dart';

class HomeCampaignPreferences {
  HomeCampaignPreferences._();

  static final Set<String> _openedThisSession = {};
  static final Map<String, String> _imageThisSession = {};

  static Future<String> imageForSession(
    String identity,
    List<String> urls,
  ) async {
    if (urls.isEmpty) return '';
    final cached = _imageThisSession[identity];
    if (cached != null && urls.contains(cached)) return cached;
    try {
      final preferences = await SharedPreferences.getInstance();
      final key = 'home_campaign.image_index.$identity';
      final index = ((preferences.getInt(key) ?? -1) + 1) % urls.length;
      await preferences.setInt(key, index);
      return _imageThisSession[identity] = urls[index];
    } catch (_) {
      return _imageThisSession[identity] = urls.first;
    }
  }

  static bool openedInSession(String identity) =>
      _openedThisSession.contains(identity);
  static void markOpenedInSession(String identity) =>
      _openedThisSession.add(identity);
}
