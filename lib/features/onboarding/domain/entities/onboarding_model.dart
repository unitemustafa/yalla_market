import 'package:flutter/material.dart';

class OnboardingModel {
  const OnboardingModel({
    required this.lightImagePath,
    required this.darkImagePath,
    required this.title,
    required this.description,
  });

  final String lightImagePath;
  final String darkImagePath;
  final String title;
  final String description;

  String imageFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkImagePath
        : lightImagePath;
  }
}
