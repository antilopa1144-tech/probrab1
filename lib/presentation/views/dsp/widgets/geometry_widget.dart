import 'package:flutter/material.dart';
import '../project_state.dart';
import 'custom_tab_selector.dart';
import 'number_input.dart';

class GeometryWidget extends StatelessWidget {
  final ProjectState state;

  const GeometryWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTabSelector(
          labels: const ['По размерам', 'Площадь стен'],
          selectedIndex: state.mode.index,
          onSelect: (index) {
            state.mode = CalculationMode.values[index];
          },
        ),
        const SizedBox(height: 16),
        // We need a ListenableBuilder here to rebuild the widget when the mode changes
        ListenableBuilder(
          listenable: state,
          builder: (context, child) {
            if (state.mode == CalculationMode.dimensions) {
              return Row(
                children: [
                  Expanded(
                    child: NumberInput(
                      label: 'Длина (м)',
                      value: state.roomL,
                      onChanged: (v) => state.updateDimensions(l: v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NumberInput(
                      label: 'Ширина (м)',
                      value: state.roomW,
                      onChanged: (v) => state.updateDimensions(w: v),
                    ),
                  ),
                ],
              );
            } else {
              return NumberInput(
                label: 'Площадь стен (м²)',
                value: state.netArea,
                onChanged: (v) => state.updateArea(v),
              );
            }
          },
        ),
      ],
    );
  }
}
