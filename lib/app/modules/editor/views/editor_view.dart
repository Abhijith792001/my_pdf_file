import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfrx/pdfrx.dart';
import '../controllers/editor_controller.dart';

class EditorView extends GetView<EditorController> {
  const EditorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: controller.clearBoard,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              Get.snackbar(
                "Info",
                "Save feature implemented in File Controller",
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background PDF
          PdfViewer.file(
            controller.filePath,
            params: PdfViewerParams(
              // Disable gestures for PDF so we can draw?
              // Or we need a toggle. For now, let's assume drawing mode is overlay.
            ),
          ),
          // Drawing Layer
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              controller.addPoint(
                DrawingPoint(
                  offset: details.localPosition,
                  paint: Paint()
                    ..color = controller.selectedColor.value
                    ..isAntiAlias = true
                    ..strokeWidth = controller.strokeWidth.value
                    ..strokeCap = StrokeCap.round,
                ),
              );
            },
            onPanUpdate: (details) {
              controller.addPoint(
                DrawingPoint(
                  offset: details.localPosition,
                  paint: Paint()
                    ..color = controller.selectedColor.value
                    ..isAntiAlias = true
                    ..strokeWidth = controller.strokeWidth.value
                    ..strokeCap = StrokeCap.round,
                ),
              );
            },
            onPanEnd: (details) {
              controller.addPoint(null);
            },
            child: Obx(
              () => CustomPaint(
                painter: _DrawingPainter(controller.points.toList()),
                child: SizedBox(height: Get.height, width: Get.width),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildToolbar(),
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 80,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () => controller.selectedColor.value = Colors.red,
            icon: const Icon(Icons.circle, color: Colors.red),
          ),
          IconButton(
            onPressed: () => controller.selectedColor.value = Colors.blue,
            icon: const Icon(Icons.circle, color: Colors.blue),
          ),
          IconButton(
            onPressed: () => controller.selectedColor.value = Colors.black,
            icon: const Icon(Icons.circle, color: Colors.black),
          ),
          IconButton(
            onPressed: () => controller.selectedColor.value = Colors.yellow,
            icon: const Icon(Icons.circle, color: Colors.yellow),
          ),
        ],
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> points;
  _DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(
          points[i]!.offset,
          points[i + 1]!.offset,
          points[i]!.paint,
        );
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawPoints(ui.PointMode.points, [
          points[i]!.offset,
        ], points[i]!.paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
