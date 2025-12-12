import 'dart:io';
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
      return Stack(
        children: [
          Column(
            children: [
              // Breadcrumb / Path Display (Optional, simplified)
              if (controller.currentPath.value.isNotEmpty &&
                  controller.currentPath.value != controller.appPath)
                ListTile(
                  leading: const Icon(Icons.arrow_back),
                  title: const Text(".. (Back)"),
                  onTap: controller.navigateUp,
                ),

              Expanded(
                child: ListView(
                  children: [
                    // Folders Section
                    if (controller.fileList.any((e) => e is Directory)) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Text(
                          "Folders",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ...controller.fileList.whereType<Directory>().map((
                        entity,
                      ) {
                        return ListTile(
                          leading: const Icon(
                            Icons.folder,
                            color: Colors.orange,
                          ),
                          title: Text(entity.path.split('/').last),
                          subtitle: Text(entity.path),
                          trailing: _buildPopupMenu(controller, entity),
                          onTap: () {
                            controller.navigateTo(entity.path);
                          },
                        );
                      }),
                    ],

                    // Files Section
                    if (controller.fileList.any((e) => e is File)) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Text(
                          "Files",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ...controller.fileList.whereType<File>().map((entity) {
                        return ListTile(
                          leading: const Icon(
                            Icons.insert_drive_file, // Use generic file icon
                            color: Colors.blue,
                          ),
                          title: Text(entity.path.split('/').last),
                          subtitle: Text(entity.path),
                          trailing: _buildPopupMenu(controller, entity),
                          onTap: () {
                            controller.openFile(entity);
                          },
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // Paste FAB
          if (controller.clipboardItem.value != null)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                heroTag: "files_view_paste", // Unique tag to avoid conflicts
                onPressed: () =>
                    controller.pasteItem(controller.currentPath.value),
                label: const Text("Paste Here"),
                icon: const Icon(Icons.paste),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildPopupMenu(FileController controller, FileSystemEntity entity) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'move':
            controller.copyToClipboard(entity, isMove: true);
            break;
          case 'copy':
            controller.copyToClipboard(entity, isMove: false);
            break;
          case 'delete':
            controller.deleteFile(entity);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'move',
          child: ListTile(
            leading: Icon(Icons.drive_file_move),
            title: Text('Move'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'copy',
          child: ListTile(
            leading: Icon(Icons.copy),
            title: Text('Copy'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
