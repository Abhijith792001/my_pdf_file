import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_pdf_files/app/controllers/file_controller.dart';

class ManageFilesView extends GetView<FileController> {
  const ManageFilesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: AppBar(title: const Text("Manage Files")),

        // No Paste FAB here because we are viewing a list of all files,
        // usually you paste INTO a folder. But we can allow pasting into the App Directory?
        // Or just hide it. The user said "manage file", typically this implies source.
        // If we move/copy FROM here, we go TO a folder to paste.
        // So no FAB logic needed here unless we want to allow pasting to root.
        // Let's omit FAB for now as this is a "Source" view.
        body: controller.recentFiles.isEmpty
            ? const Center(child: Text("No documents found."))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.recentFiles.length,
                itemBuilder: (context, index) {
                  final entity = controller.recentFiles[index];
                  if (entity is File) {
                    return ListTile(
                      leading: const Icon(
                        Icons.insert_drive_file,
                        color: Colors.blue,
                      ),
                      title: Text(entity.path.split('/').last),
                      subtitle: Text(
                        entity.path,
                      ), // Show full path so user knows where it is
                      trailing: _buildPopupMenu(controller, entity),
                      onTap: () => controller.openFile(entity),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
      ),
    );
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
