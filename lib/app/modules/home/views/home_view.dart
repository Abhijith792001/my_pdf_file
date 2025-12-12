import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_pdf_files/app/controllers/file_controller.dart';
import '../controllers/home_controller.dart';

import '../../files/views/files_view.dart';
import '../../tools/views/tools_view.dart';
import 'folder_view.dart';
import 'manage_files_view.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final FileController fileController = Get.find<FileController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Manager'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
        ],
      ),
      body: Obx(() {
        if (fileController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!fileController.hasPermission.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Storage Permission Required"),
                ElevatedButton(
                  onPressed: fileController.requestPermission,
                  child: const Text("Grant Permission"),
                ),
              ],
            ),
          );
        }

        return IndexedStack(
          index: controller.tabIndex.value,
          children: [
            _buildDashboard(fileController),
            const FilesView(),
            const ToolsView(),
          ],
        );
      }),

      bottomNavigationBar: Obx(
        () => NavigationBar(
          selectedIndex: controller.tabIndex.value,
          onDestinationSelected: controller.changeTabIndex,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_open),
              selectedIcon: Icon(Icons.folder),
              label: 'Files',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Tools',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(FileController fileController) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Quick Actions Section
        Text("Quick Actions", style: Get.textTheme.titleMedium),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 2,
                child: InkWell(
                  onTap: () => _showCreateFolderDialog(fileController),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: const [
                        Icon(
                          Icons.create_new_folder,
                          size: 40,
                          color: Colors.blue,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Create Folder",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Card(
                elevation: 2,
                child: InkWell(
                  onTap: () {
                    Get.find<HomeController>().changeTabIndex(2);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: const [
                        Icon(Icons.build, size: 40, color: Colors.orange),
                        SizedBox(height: 10),
                        Text(
                          "PDF Tools",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Card(
                elevation: 2,
                child: InkWell(
                  onTap: () {
                    // Open Manage Files Page
                    Get.to(() => const ManageFilesView());
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: const [
                        Icon(Icons.folder_copy, size: 40, color: Colors.green),
                        SizedBox(height: 10),
                        Text(
                          "Manage Files",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Recent Files Section
        Text("Recent Files", style: Get.textTheme.titleMedium),
        const SizedBox(height: 10),
        if (fileController.recentFiles.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text("No recent files found."),
          )
        else
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: fileController.recentFiles.length > 5
                  ? 5
                  : fileController.recentFiles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final file = fileController.recentFiles[index];
                return GestureDetector(
                  onTap: () => fileController.openFile(file),
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.description,
                          size: 40,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          file.path.split('/').last,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 20),

        Text("My PDFs (PDFManager)", style: Get.textTheme.titleLarge),
        const SizedBox(height: 10),

        // PDFManager Files & Folders
        if (fileController.appFiles.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text("No files or folders in PDFManager."),
          )
        else ...[
          // Folders Section
          if (fileController.appFiles.any((e) => e is Directory)) ...[
            const Text(
              "Folders",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            LimitedBox(
              maxHeight:
                  120, // Reduced height for folders if we want horizontal, but grid is fine too. Let's keep Grid for consistency or change to horizontal? User said "separate pages" but we clarified sections. Let's keep Grid or List.
              // Use Grid for folders as before
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemCount: fileController.appFiles
                    .whereType<Directory>()
                    .length,
                itemBuilder: (context, index) {
                  final entity = fileController.appFiles
                      .whereType<Directory>()
                      .elementAt(index);
                  return GestureDetector(
                    onTap: () {
                      Get.to(
                        () => FolderView(
                          path: entity.path,
                          folderName: entity.path.split('/').last,
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade100),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.folder,
                            size: 40,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entity.path.split('/').last,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Files Section
          if (fileController.appFiles.any((e) => e is File)) ...[
            const Text(
              "Files",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            LimitedBox(
              maxHeight: 300,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemCount: fileController.appFiles.whereType<File>().length,
                itemBuilder: (context, index) {
                  final entity = fileController.appFiles
                      .whereType<File>()
                      .elementAt(index);
                  return GestureDetector(
                    onTap: () => fileController.openFile(entity),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.insert_drive_file,
                            size: 40,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entity.path.split('/').last,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ],
    );
  }

  void _showCreateFolderDialog(FileController fileController) {
    final TextEditingController nameController = TextEditingController();
    Get.defaultDialog(
      title: "Create New Folder",
      content: Column(
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: "Folder Name",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      textConfirm: "Create",
      textCancel: "Cancel",
      onConfirm: () {
        if (nameController.text.isNotEmpty) {
          Get.back(); // Close dialog
          fileController.createFolder(nameController.text);
        }
      },
    );
  }
}
