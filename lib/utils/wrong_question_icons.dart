import 'package:flutter/material.dart';

class IconOption {
  const IconOption({required this.name, required this.icon});
  final String name;
  final IconData icon;
}

class WrongQuestionIcons {
  const WrongQuestionIcons._();

  static const List<IconOption> available = [
    IconOption(name: 'folder', icon: Icons.folder),
    IconOption(name: 'book', icon: Icons.menu_book),
    IconOption(name: 'school', icon: Icons.school),
    IconOption(name: 'star', icon: Icons.star),
    IconOption(name: 'favorite', icon: Icons.favorite),
    IconOption(name: 'lightbulb', icon: Icons.lightbulb_outline),
    IconOption(name: 'science', icon: Icons.science),
    IconOption(name: 'calculate', icon: Icons.calculate),
    IconOption(name: 'history_edu', icon: Icons.history_edu),
    IconOption(name: 'language', icon: Icons.language),
    IconOption(name: 'code', icon: Icons.code),
    IconOption(name: 'brush', icon: Icons.brush),
    IconOption(name: 'music_note', icon: Icons.music_note),
    IconOption(name: 'sports_soccer', icon: Icons.sports_soccer),
    IconOption(name: 'travel_explore', icon: Icons.travel_explore),
    IconOption(name: 'workspace_premium', icon: Icons.workspace_premium),
    IconOption(name: 'emoji_events', icon: Icons.emoji_events),
    IconOption(name: 'flag', icon: Icons.flag),
    IconOption(name: 'label', icon: Icons.label),
    IconOption(name: 'bookmark', icon: Icons.bookmark),
    IconOption(name: 'collections_bookmark', icon: Icons.collections_bookmark),
    IconOption(name: 'assignment', icon: Icons.assignment),
    IconOption(name: 'quiz', icon: Icons.quiz),
    IconOption(name: 'psychology', icon: Icons.psychology),
    IconOption(name: 'auto_stories', icon: Icons.auto_stories),
    IconOption(name: 'edit_note', icon: Icons.edit_note),
    IconOption(name: 'checklist', icon: Icons.checklist),
    IconOption(name: 'toc', icon: Icons.toc),
    IconOption(name: 'description', icon: Icons.description),
    IconOption(name: 'article', icon: Icons.article),
    IconOption(name: 'analytics', icon: Icons.analytics),
    IconOption(name: 'trending_up', icon: Icons.trending_up),
    IconOption(name: 'rocket_launch', icon: Icons.rocket_launch),
    IconOption(name: 'emoji_nature', icon: Icons.emoji_nature),
    IconOption(name: 'public', icon: Icons.public),
    IconOption(name: 'balance', icon: Icons.balance),
    IconOption(name: 'architecture', icon: Icons.architecture),
    IconOption(name: 'palette', icon: Icons.palette),
    IconOption(name: 'theaters', icon: Icons.theaters),
    IconOption(name: 'camera', icon: Icons.camera),
  ];

  static IconData fromName(String name) {
    for (final option in available) {
      if (option.name == name) return option.icon;
    }
    return available.first.icon;
  }
}
