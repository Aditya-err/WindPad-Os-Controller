import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GesturesGuide extends StatelessWidget {
  const GesturesGuide({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> gestures = [
      {"id": "singleTap", "label": "Single Tap", "action": "Left Click", "icon": "☝🏻", "fingers": "1F", "color": AppTheme.primary, "chip": AppTheme.primaryContainer},
      {"id": "twoTap", "label": "Two-Finger Tap", "action": "Right Click", "icon": "✌🏻", "fingers": "2F", "color": AppTheme.tertiary, "chip": AppTheme.tertiaryContainer},
      {"id": "drag", "label": "1-Finger Drag", "action": "Move Cursor", "icon": "👆🏻", "fingers": "1F", "color": AppTheme.primary, "chip": AppTheme.primaryContainer},
      {"id": "scroll", "label": "2-Finger Drag", "action": "Scroll ↑↓ ←→", "icon": "🤞🏻", "fingers": "2F", "color": AppTheme.secondary, "chip": AppTheme.secondaryContainer},
      {"id": "pinch", "label": "Pinch / Spread", "action": "Zoom In / Out", "icon": "🤏🏻", "fingers": "2F", "color": AppTheme.tertiary, "chip": AppTheme.tertiaryContainer},
      {"id": "threeSwipe", "label": "3-Finger Swipe", "action": "App Switch", "icon": "🖖🏻", "fingers": "3F", "color": const Color(0xFF386A20), "chip": const Color(0xFFC3EFAD)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "Supported Gestures",
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.elevation(0),
          ),
          child: Column(
            children: gestures.asMap().entries.map((entry) {
              final int idx = entry.key;
              final Map<String, dynamic> g = entry.value;
              final bool isLast = idx == gestures.length - 1;
              return _buildM3ListItem(g, isLast);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildM3ListItem(Map<String, dynamic> g, bool isLast) {
    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.22))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: g["chip"] as Color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(g["icon"] as String, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  g["fingers"] as String,
                  style: TextStyle(
                    color: g["color"] as Color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  g["label"] as String,
                  style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  g["action"] as String,
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
