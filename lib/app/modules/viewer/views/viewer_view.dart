import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfrx/pdfrx.dart';
import '../controllers/viewer_controller.dart';

class ViewerView extends GetView<ViewerController> {
  const ViewerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.filePath.split('/').last),
        actions: [
            IconButton(icon: const Icon(Icons.edit), onPressed: () {
                // Navigate to Editor
                Get.toNamed('/editor', arguments: controller.filePath);
            }),
        ],
      ),
      body: Stack(
        children: [
          PdfViewer.file(
            controller.filePath,
            controller: controller.pdfViewerController,
            params: PdfViewerParams(
              onViewerReady: (document, controller) {
                this.controller.isReady.value = true;
                this.controller.totalPages.value = document.pages.length;
              },
              onPageChanged: (page) {
                if (page != null) {
                    controller.onPageChanged(page, controller.totalPages.value);
                }
              },
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Obx(() => controller.isReady.value
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${controller.currentPage}/${controller.totalPages}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                : const SizedBox.shrink()),
          ),
        ],
      ),
    );
  }
}
