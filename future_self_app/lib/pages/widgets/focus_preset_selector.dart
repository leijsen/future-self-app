import 'package:flutter/material.dart';

class FocusPresetSelector extends StatelessWidget {
  const FocusPresetSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  static const _presets = [25, 45, 90];

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: [
        for (final m in _presets)
          ButtonSegment(value: m, label: Text('$m min')),
        const ButtonSegment(value: -1, label: Text('Custom')),
      ],
      selected: {_presets.contains(selected) ? selected : -1},
      onSelectionChanged: (selection) {
        final value = selection.first;
        if (value == -1) return;
        onChanged(value);
      },
    );
  }
}
