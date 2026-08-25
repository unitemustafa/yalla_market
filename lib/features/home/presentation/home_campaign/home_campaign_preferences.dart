import 'package:shared_preferences/shared_preferences.dart';

class HomeCampaignPreferences {
  HomeCampaignPreferences._();

  static final Set<String> _openedThisSession = {};
  static final Set<String> _hiddenThisSession = {};

  static bool hiddenInSession(String identity) =>
      _hiddenThisSession.contains(identity);
  static bool openedInSession(String identity) =>
      _openedThisSession.contains(identity);
  static void markOpenedInSession(String identity) =>
      _openedThisSession.add(identity);
  static void hideForSession(String identity) =>
      _hiddenThisSession.add(identity);

  static Future<bool> hiddenToday(String identity) async {
    final preferences = await SharedPreferences.getInstance();
    final until = preferences.getInt('home_campaign.hide_until.$identity') ?? 0;
    return until > DateTime.now().millisecondsSinceEpoch;
  }

  static Future<void> hideForDay(String identity) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(
      'home_campaign.hide_until.$identity',
      DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
    );
  }

  static Future<bool> openedToday(String identity) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString('home_campaign.open_day.$identity') ==
        _dayKey();
  }

  static Future<void> markOpenedToday(String identity) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('home_campaign.open_day.$identity', _dayKey());
  }

  static String _dayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
