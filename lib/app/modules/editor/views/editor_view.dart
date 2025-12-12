import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfrx/pdfrx.dart';
import '../controllers/editor_controller.dart' hide DrawingPoint;
import '../controllers/editor_controller.dart' as ec show DrawingPoint;

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
          PopupMenuButton<String>(
            icon: const Icon(Icons.save),
            onSelected: (value) {
              if (value == 'save') {
                controller.saveFile();
              } else if (value == 'save_as') {
                controller.saveAsFile();
              } else if (value == 'convert_word') {
                controller.convertToWord();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'save', child: Text('Save')),
              const PopupMenuItem<String>(
                value: 'save_as',
                child: Text('Save As...'),
              ),
              const PopupMenuItem<String>(
                value: 'convert_word',
                child: Text('Convert to Word'),
              ),
            ],
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
          // Drawing Layer (Only active if Pen tool selected)
          Obx(
            () => IgnorePointer(
              ignoring: controller.selectedTool.value != 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  controller.addPoint(
                    ec.DrawingPoint(
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
                    ec.DrawingPoint(
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
                child: CustomPaint(
                  painter: _DrawingPainter(controller.points.toList()),
                  child: SizedBox(height: Get.height, width: Get.width),
                ),
              ),
            ),
          ),

          // Text Annotations Layer (Tap to add text)
          Obx(
            () => IgnorePointer(
              ignoring: controller.selectedTool.value != 1,
              child: GestureDetector(
                behavior: HitTestBehavior
                    .translucent, // Allow clicks through if needed, but we want to catch tap
                onTapUp: (details) {
                  _showTextDialog(context, details.localPosition);
                },
                child: Stack(
                  children: [
                    ...controller.textAnnotations.map(
                      (annotation) => Positioned(
                        left: annotation.offset.dx,
                        top: annotation.offset.dy,
                        child: Text(annotation.text, style: annotation.style),
                      ),
                    ),
                    // Invisible container to catch taps
                    Container(color: Colors.transparent),
                  ],
                ),
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
      child: Column(
        children: [
          // Tool Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Obx(
                () => IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: controller.selectedTool.value == 0
                        ? Colors.blue
                        : Colors.grey,
                  ),
                  onPressed: () => controller.selectedTool.value = 0,
                ),
              ),
              Obx(
                () => IconButton(
                  icon: Icon(
                    Icons.text_fields,
                    color: controller.selectedTool.value == 1
                        ? Colors.blue
                        : Colors.grey,
                  ),
                  onPressed: () => controller.selectedTool.value = 1,
                ),
              ),
            ],
          ),
          // Color Selector
          Row(
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
        ],
      ),
    );
  }

  void _showTextDialog(BuildContext context, Offset position) {
    TextEditingController textCtrl = TextEditingController();
    Get.defaultDialog(
      title: "Add Text",
      content: TextField(
        controller: textCtrl,
        decoration: const InputDecoration(hintText: "Enter text"),
        autofocus: true,
      ),
      textConfirm: "Add",
      onConfirm: () {
        if (textCtrl.text.isNotEmpty) {
          controller.addTextAnnotation(
            TextAnnotation(
              offset: position,
              text: textCtrl.text,
              style: TextStyle(
                color: controller.selectedColor.value,
                fontSize: 20, // Default size
              ),
            ),
          );
        }
        Get.back();
      },
      textCancel: "Cancel",
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<ec.DrawingPoint?> points;
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
