import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_pdf_files/app/controllers/file_controller.dart';

class FolderPickerView extends StatefulWidget {
  final String path;
  final String title;

  const FolderPickerView({super.key, required this.path, required this.title});

  @override
  State<FolderPickerView> createState() => _FolderPickerViewState();
}

class _FolderPickerViewState extends State<FolderPickerView> {
  final FileController controller = Get.find<FileController>();

  void _showCreateFolderDialog() {
    final TextEditingController textController = TextEditingController();
    Get.defaultDialog(
      title: "New Folder",
      content: TextField(
        controller: textController,
        decoration: const InputDecoration(hintText: "Folder Name"),
      ),
      textConfirm: "Create",
      textCancel: "Cancel",
      onConfirm: () {
        if (textController.text.isNotEmpty) {
          controller
              .createFolder(
                folderName: textController.text,
                parentPath: widget.path,
              )
              .then((_) {
                Get.back(); // Close dialog
                setState(() {}); // Refresh list
              });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            onPressed: _showCreateFolderDialog,
            tooltip: "Create New Folder",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Paste into CURRENT path (widget.path)
          controller.pasteItem(widget.path).then((_) {
            // Navigate back to where we started (e.g. Files tab or Home)
            // We pushed Picker, so we pop.
            // Depending on depth, we might need multiple pops or 'until'.
            // For now, let's assuming simply closing the picker is enough if we just pushed one.
            // But if we drilled down in picker?
            // We should use Get.until or similar, or just Get.back() if we replace navigation?
            // Safest: Go back to Home? Or just close the picker stack.
            // Let's implement a "Close Picker" logic in controller or just use Get.close(1)?
            // Actually, if we navigated Depth 1 -> Depth 2 -> Depth 3 in Picker,
            // we want to close ALL pickers.
            Get.until(
              (route) => !Get.currentRoute.contains('FolderPickerView'),
            );
          });
        },
        label: const Text("Paste Here"),
        icon: const Icon(Icons.paste),
      ),
      body: FutureBuilder<List<FileSystemEntity>>(
        future: controller.getDirectoryContents(widget.path),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter ONLY directories
          final entities = (snapshot.data ?? [])
              .whereType<Directory>()
              .toList();

          if (entities.isEmpty) {
            return const Center(
              child: Text(
                "No folders here.\nCreate one or Paste here.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: entities.length,
            itemBuilder: (context, index) {
              final entity = entities[index];
              return ListTile(
                leading: const Icon(Icons.folder, color: Colors.orange),
                title: Text(entity.path.split('/').last),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate deeper in picker
                  Get.to(
                    () => FolderPickerView(
                      path: entity.path,
                      title: entity.path.split('/').last,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
