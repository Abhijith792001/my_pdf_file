import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_pdf_files/app/controllers/file_controller.dart';

class FolderView extends StatelessWidget {
  final String path;
  final String folderName;

  const FolderView({super.key, required this.path, required this.folderName});

  @override
  Widget build(BuildContext context) {
    final FileController controller = Get.find<FileController>();

    return Obx(
      () => Scaffold(
        appBar: AppBar(title: Text(folderName)),
        floatingActionButton: controller.clipboardItem.value != null
            ? FloatingActionButton.extended(
                onPressed: () => controller.pasteItem(path),
                label: const Text("Paste Here"),
                icon: const Icon(Icons.paste),
              )
            : null,
        body: FutureBuilder<List<FileSystemEntity>>(
          future: controller.getDirectoryContents(path),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            final entities = snapshot.data ?? [];
            if (entities.isEmpty) {
              return const Center(child: Text("Folder is empty"));
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Folders Section
                if (entities.any((e) => e is Directory)) ...[
                  const Text(
                    "Folders",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  ...entities.whereType<Directory>().map((entity) {
                    return ListTile(
                      leading: const Icon(Icons.folder, color: Colors.orange),
                      title: Text(entity.path.split('/').last),
                      trailing: _buildPopupMenu(controller, entity),
                      onTap: () {
                        // Navigate deeper recursively using the same page
                        Get.to(
                          () => FolderView(
                            path: entity.path,
                            folderName: entity.path.split('/').last,
                          ),
                        );
                      },
                    );
                  }),
                  const SizedBox(height: 20),
                ],

                // Files Section
                if (entities.any((e) => e is File)) ...[
                  const Text(
                    "Files",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  ...entities.whereType<File>().map((entity) {
                    return ListTile(
                      leading: const Icon(
                        Icons.insert_drive_file,
                        color: Colors.blue,
                      ),
                      title: Text(entity.path.split('/').last),
                      trailing: _buildPopupMenu(controller, entity),
                      onTap: () => controller.openFile(entity),
                    );
                  }),
                ],
              ],
            );
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
            controller.copyToClipboard(entity, isMove: true, restricted: false);
            break;
          case 'copy':
            controller.copyToClipboard(
              entity,
              isMove: false,
              restricted: false,
            );
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
