import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_grid/app_theme.dart';
import 'package:image_grid/canvas_format.dart';
import 'package:image_grid/editor_tool_grid.dart';
import 'package:image_grid/film_look.dart';
import 'package:image_grid/frame_style.dart';
import 'package:image_grid/grid_layout.dart';
import 'package:image_grid/layout_strip.dart';
import 'package:image_grid/look_panel.dart';
import 'package:image_grid/more_panel.dart';
import 'package:image_grid/overlay_compose_panel.dart';

Widget _harness({required String toolId, required Widget? panel}) {
  final active = toolDefinitionById(gridToolDefinitions, toolId);
  return MaterialApp(
    theme: AppTheme.data(),
    home: Scaffold(
      backgroundColor: AppTheme.mist,
      body: Column(
        children: [
          const Expanded(child: SizedBox()),
          EditorDock(
            tools: gridToolDefinitions,
            activeTool: active,
            panel: panel,
            onClose: () {},
            onToolSelected: (_) {},
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('dock heights stay compact', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    Future<double> measure(String toolId, Widget? panel) async {
      await tester.pumpWidget(_harness(toolId: toolId, panel: panel));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      final height = tester.getSize(find.byType(EditorDock)).height;
      debugPrint('DOCK[$toolId] = ${height.toStringAsFixed(1)}');
      return height;
    }

    expect(await measure('none', null), lessThan(80));

    expect(
      await measure(
        'layout',
        LayoutStrip(
          format: canvasFormats.first,
          selectedLayoutId: gridLayouts.first.id,
          onLayoutSelected: (_) {},
        ),
      ),
      lessThan(180),
    );

    expect(
      await measure(
        'format',
        FormatChips(
          selected: canvasFormats.first,
          compact: true,
          onChanged: (_) {},
        ),
      ),
      lessThan(140),
    );

    expect(
      await measure(
        'frame',
        FramePanel(
          kind: FrameKind.stroke,
          color: strokeColors.first,
          thickness: strokeThicknesses.first,
          onKindChanged: (_) {},
          onColorChanged: (_) {},
          onThicknessChanged: (_) {},
        ),
      ),
      // Tallest state: frame on, so width and colour are both on screen.
      lessThan(190),
    );

    expect(
      await measure(
        'text',
        OverlayComposePanel(
          overlays: const [],
          selectedIndex: null,
          onSelect: (_) {},
          onAddText: () {},
          onChanged: (_) {},
          onRemove: () {},
          onEdit: (_) {},
        ),
      ),
      lessThan(180),
    );
    expect(
      await measure(
        'more',
        MorePanel(
          enabled: true,
          onSaveDraft: () {},
          onSaveToPhotos: () {},
          onAddPathText: () {},
          onAddTemplate: () {},
          filter: PhotoFilter.values.first,
          grain: false,
          onFilterChanged: (_) {},
          onGrainChanged: (_) {},
          overlays: const [],
          selectedIndex: null,
          onSelect: (_) {},
          onAddMessage: () {},
          onAddLocation: () {},
          onAddCoordinates: () {},
          onAddDate: () {},
          onAddTime: () {},
          onAddWeather: () {},
          onChanged: (_) {},
          onRemove: () {},
          onEdit: (_) {},
        ),
      ),
      lessThan(200),
    );
  });
}
