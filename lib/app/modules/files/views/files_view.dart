import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_pdf_files/app/controllers/file_controller.dart';

class FilesView extends GetView<FileController> {
  const FilesView({super.key});

  @override
  Widget build(BuildContext context) {
    // FileController is permanent, so we can find it.
    final controller = Get.find<FileController>();

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return ListView.builder(
        itemCount: controller.allFiles.length,
        itemBuilder: (context, index) {
          final file = controller.allFiles[index];
          return ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.blue),
            title: Text(file.path.split('/').last),
            subtitle: Text(file.path),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Show options: Rename, Delete, Share
              },
            ),
            onTap: () {
              Get.toNamed('/viewer', arguments: file.path);
            },
          );
        },
      );
    });
  }
}
