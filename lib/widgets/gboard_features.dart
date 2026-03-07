import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GboardFeatures extends StatefulWidget {
  const GboardFeatures({super.key});

  @override
  State<GboardFeatures> createState() => _GboardFeaturesState();
}

class _GboardFeaturesState extends State<GboardFeatures> {
  bool _voiceTypingEnabled = true;
  String _currentTheme = "Dynamic Blue";
  String _currentFont = "Roboto";
  String _currentLanguage = "English (India) (QWERTY)";
  bool _autoCorrectEnabled = true;
  bool _spellCheckEnabled = true;
  bool _glideTypingEnabled = true;
  bool _showGestureTrail = true;
  bool _clipboardEnabled = true;

  void _showSettingsBottomSheet(BuildContext context, String title, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              content,
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.secondaryContainer,
                    foregroundColor: AppTheme.onSecondaryContainer,
                  ),
                  child: const Text("Done"),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _onFeatureTap(String label) {
    if (label == "Languages") {
      _showSettingsBottomSheet(
        context,
        "Languages",
        StatefulBuilder(builder: (context, setModalState) {
          final langs = ["English (India) (QWERTY)", "English (US) (QWERTY)", "Hindi (India) (ABC)"];
          return Column(
            children: langs.map((lang) {
              return RadioListTile<String>(
                title: Text(lang, style: const TextStyle(color: AppTheme.onSurface)),
                value: lang,
                groupValue: _currentLanguage,
                activeColor: AppTheme.primary,
                onChanged: (val) {
                  setModalState(() { _currentLanguage = val!; });
                  setState(() { _currentLanguage = val!; });
                },
              );
            }).toList(),
          );
        }),
      );
    } else if (label == "Voice typing") {
      _showSettingsBottomSheet(
        context,
        "Voice Typing Settings",
        StatefulBuilder(
          builder: (context, setModalState) {
            return SwitchListTile(
              title: const Text("Enable Voice Typing", style: TextStyle(color: AppTheme.onSurface)),
              subtitle: const Text("Use microphone to speak instead of typing", style: TextStyle(color: AppTheme.onSurfaceVariant)),
              value: _voiceTypingEnabled,
              activeColor: AppTheme.primary,
              onChanged: (val) {
                setModalState(() { _voiceTypingEnabled = val; });
                setState(() { _voiceTypingEnabled = val; });
              },
            );
          }
        ),
      );
    } else if (label == "Theme") {
      _showSettingsBottomSheet(
        context,
        "Appearance & Theme",
        StatefulBuilder(
          builder: (context, setModalState) {
            final themes = ["Dynamic Blue", "Midnight Dark", "Neon Violet", "Classic Gray"];
            return Column(
              children: themes.map((theme) {
                return RadioListTile<String>(
                  title: Text(theme, style: const TextStyle(color: AppTheme.onSurface)),
                  value: theme,
                  groupValue: _currentTheme,
                  activeColor: AppTheme.primary,
                  onChanged: (val) {
                    setModalState(() { _currentTheme = val!; });
                    setState(() { _currentTheme = val!; });
                  },
                );
              }).toList(),
            );
          }
        ),
      );
    } else if (label == "Preferences") {
      _showSettingsBottomSheet(
        context,
        "Keyboard Preferences",
        StatefulBuilder(
          builder: (context, setModalState) {
            final fonts = ["Roboto", "Google Sans", "Open Sans", "Monospace"];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Select Font Style:", style: TextStyle(color: AppTheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: fonts.map((f) {
                    return ChoiceChip(
                      label: Text(f),
                      selected: _currentFont == f,
                      selectedColor: AppTheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: _currentFont == f ? AppTheme.onPrimaryContainer : AppTheme.onSurface,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setModalState(() { _currentFont = f; });
                          setState(() { _currentFont = f; });
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            );
          }
        ),
      );
    } else if (label == "Text correction") {
      _showSettingsBottomSheet(
        context,
        "Text Correction",
        StatefulBuilder(builder: (context, setModalState) {
          return Column(
            children: [
              SwitchListTile(
                title: const Text("Auto-correct", style: TextStyle(color: AppTheme.onSurface)),
                subtitle: const Text("Correct words while typing", style: TextStyle(color: AppTheme.onSurfaceVariant)),
                value: _autoCorrectEnabled,
                activeColor: AppTheme.primary,
                onChanged: (val) {
                  setModalState(() { _autoCorrectEnabled = val; });
                  setState(() { _autoCorrectEnabled = val; });
                },
              ),
              SwitchListTile(
                title: const Text("Spell check", style: TextStyle(color: AppTheme.onSurface)),
                subtitle: const Text("Mark misspelled words with red underline", style: TextStyle(color: AppTheme.onSurfaceVariant)),
                value: _spellCheckEnabled,
                activeColor: AppTheme.primary,
                onChanged: (val) {
                  setModalState(() { _spellCheckEnabled = val; });
                  setState(() { _spellCheckEnabled = val; });
                },
              ),
            ],
          );
        }),
      );
    } else if (label == "Glide typing") {
      _showSettingsBottomSheet(
        context,
        "Glide Typing",
        StatefulBuilder(builder: (context, setModalState) {
          return Column(
            children: [
              SwitchListTile(
                title: const Text("Enable glide typing", style: TextStyle(color: AppTheme.onSurface)),
                subtitle: const Text("Input a word by sliding through the letters", style: TextStyle(color: AppTheme.onSurfaceVariant)),
                value: _glideTypingEnabled,
                activeColor: AppTheme.primary,
                onChanged: (val) {
                  setModalState(() { _glideTypingEnabled = val; });
                  setState(() { _glideTypingEnabled = val; });
                },
              ),
              SwitchListTile(
                title: const Text("Show gesture trail", style: TextStyle(color: AppTheme.onSurface)),
                value: _showGestureTrail,
                activeColor: AppTheme.primary,
                onChanged: _glideTypingEnabled ? (val) {
                  setModalState(() { _showGestureTrail = val; });
                  setState(() { _showGestureTrail = val; });
                } : null,
              ),
            ],
          );
        }),
      );
    } else if (label == "Clipboard") {
      _showSettingsBottomSheet(
        context,
        "Clipboard",
        StatefulBuilder(builder: (context, setModalState) {
          return SwitchListTile(
            title: const Text("Show recently copied text and images", style: TextStyle(color: AppTheme.onSurface)),
            subtitle: const Text("In the suggestions bar", style: TextStyle(color: AppTheme.onSurfaceVariant)),
            value: _clipboardEnabled,
            activeColor: AppTheme.primary,
            onChanged: (val) {
              setModalState(() { _clipboardEnabled = val; });
              setState(() { _clipboardEnabled = val; });
            },
          );
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> features = [
      { "icon": Icons.language, "label": "Languages", "desc": _currentLanguage },
      { "icon": Icons.settings, "label": "Preferences", "desc": "Current font: $_currentFont" },
      { "icon": Icons.palette, "label": "Theme", "desc": "Current: $_currentTheme" },
      { "icon": Icons.spellcheck, "label": "Text correction", "desc": _autoCorrectEnabled ? "Auto-correct enabled" : "Auto-correct disabled" },
      { "icon": Icons.gesture, "label": "Glide typing", "desc": _glideTypingEnabled ? "Enabled" : "Disabled" },
      { "icon": Icons.mic, "label": "Voice typing", "desc": _voiceTypingEnabled ? "Enabled" : "Disabled" },
      { "icon": Icons.content_paste, "label": "Clipboard", "desc": _clipboardEnabled ? "Enabled" : "Disabled" },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "Settings",
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
            children: features.asMap().entries.map((entry) {
              final int idx = entry.key;
              final Map<String, dynamic> f = entry.value;
              final bool isLast = idx == features.length - 1;
              return _buildM3ListItem(f["icon"] as IconData, f["label"] as String, f["desc"] as String, isLast);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildM3ListItem(IconData icon, String label, String desc, bool isLast) {
    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.22))),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onFeatureTap(label),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppTheme.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppTheme.onSecondaryContainer, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: const TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
