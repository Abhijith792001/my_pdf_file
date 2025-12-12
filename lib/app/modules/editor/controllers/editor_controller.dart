import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditorController extends GetxController {
  late String filePath;
  RxList<DrawingPoint?> points = <DrawingPoint?>[].obs;
  Rx<Color> selectedColor = Colors.black.obs;
  RxDouble strokeWidth = 3.0.obs;
  
  @override
  void onInit() {
    super.onInit();
    filePath = Get.arguments as String? ?? "";
  }

  void addPoint(DrawingPoint? point) {
    points.add(point);
  }

  void clearBoard() {
    points.clear();
  }
}

class DrawingPoint {
  Offset offset;
  Paint paint;

  DrawingPoint({required this.offset, required this.paint});
}
