import 'package:flutter/material.dart';

class HomeCampaignData {
  const HomeCampaignData({
    required this.id,
    required this.updatedAt,
    required this.teaser,
    required this.sheet,
    required this.media,
    required this.action,
    required this.behavior,
  });

  final String id;
  final DateTime? updatedAt;
  final HomeCampaignTeaserData teaser;
  final HomeCampaignSheetData sheet;
  final HomeCampaignMediaData media;
  final HomeCampaignActionData action;
  final HomeCampaignBehaviorData behavior;

  String get storageIdentity =>
      '${id}_${updatedAt?.millisecondsSinceEpoch ?? 0}';

  factory HomeCampaignData.fromJson(Map<String, dynamic> json) {
    return HomeCampaignData(
      id: json['id']?.toString() ?? '',
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      teaser: HomeCampaignTeaserData.fromJson(_map(json['teaser'])),
      sheet: HomeCampaignSheetData.fromJson(_map(json['sheet'])),
      media: HomeCampaignMediaData.fromJson(_map(json['media'])),
      action: HomeCampaignActionData.fromJson(_map(json['action'])),
      behavior: HomeCampaignBehaviorData.fromJson(_map(json['behavior'])),
    );
  }
}

class HomeCampaignTeaserData {
  const HomeCampaignTeaserData({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.imageUrl,
  });
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final String imageUrl;

  factory HomeCampaignTeaserData.fromJson(Map<String, dynamic> json) =>
      HomeCampaignTeaserData(
        text: json['text']?.toString() ?? '',
        backgroundColor: campaignColor(
          json['background_color'],
          const Color(0xFFFF5A00),
        ),
        textColor: campaignColor(json['text_color'], Colors.white),
        imageUrl: json['image_url']?.toString() ?? '',
      );
}

class HomeCampaignSheetData {
  const HomeCampaignSheetData({
    required this.title,
    required this.description,
    required this.template,
    required this.size,
    required this.alignment,
    required this.backgroundColor,
    required this.textColor,
    required this.buttonBackgroundColor,
    required this.buttonTextColor,
  });
  final String title;
  final String description;
  final String template;
  final String size;
  final String alignment;
  final Color backgroundColor;
  final Color textColor;
  final Color buttonBackgroundColor;
  final Color buttonTextColor;

  factory HomeCampaignSheetData.fromJson(Map<String, dynamic> json) =>
      HomeCampaignSheetData(
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        template: json['template']?.toString() ?? 'hero',
        size: json['size']?.toString() ?? 'large',
        alignment: json['alignment']?.toString() ?? 'center',
        backgroundColor: campaignColor(json['background_color'], Colors.white),
        textColor: campaignColor(json['text_color'], const Color(0xFF202124)),
        buttonBackgroundColor: campaignColor(
          json['button_background_color'],
          const Color(0xFFFF5A00),
        ),
        buttonTextColor: campaignColor(json['button_text_color'], Colors.white),
      );
}

class HomeCampaignMediaData {
  const HomeCampaignMediaData({
    required this.type,
    required this.imageUrl,
    required this.videoUrl,
    required this.posterUrl,
  });
  final String type;
  final String imageUrl;
  final String videoUrl;
  final String posterUrl;
  factory HomeCampaignMediaData.fromJson(Map<String, dynamic> json) =>
      HomeCampaignMediaData(
        type: json['type']?.toString() ?? 'none',
        imageUrl: json['image_url']?.toString() ?? '',
        videoUrl: json['video_url']?.toString() ?? '',
        posterUrl: json['poster_url']?.toString() ?? '',
      );
}

class HomeCampaignActionData {
  const HomeCampaignActionData({
    required this.type,
    required this.label,
    required this.value,
    required this.target,
  });
  final String type;
  final String label;
  final String value;
  final Map<String, dynamic>? target;
  bool get hasButton => type != 'none';
  factory HomeCampaignActionData.fromJson(Map<String, dynamic> json) =>
      HomeCampaignActionData(
        type: json['type']?.toString() ?? 'none',
        label: json['label']?.toString() ?? '',
        value: json['value']?.toString() ?? '',
        target: json['target'] is Map<String, dynamic>
            ? json['target'] as Map<String, dynamic>
            : null,
      );
}

class HomeCampaignBehaviorData {
  const HomeCampaignBehaviorData({
    required this.openMode,
    required this.dismissBehavior,
  });
  final String openMode;
  final String dismissBehavior;
  factory HomeCampaignBehaviorData.fromJson(Map<String, dynamic> json) =>
      HomeCampaignBehaviorData(
        openMode: json['open_mode']?.toString() ?? 'tap_only',
        dismissBehavior:
            json['dismiss_behavior']?.toString() ?? 'collapse_only',
      );
}

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const {};

Color campaignColor(Object? value, Color fallback) {
  final raw = value?.toString().trim().replaceFirst('#', '') ?? '';
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(raw)) return fallback;
  return Color(int.parse('FF$raw', radix: 16));
}
