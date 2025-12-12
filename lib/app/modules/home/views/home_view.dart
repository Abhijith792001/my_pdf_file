import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_pdf_files/app/controllers/file_controller.dart';
import '../controllers/home_controller.dart';

import '../../files/views/files_view.dart';
import '../../tools/views/tools_view.dart';

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
        Text("Recent Files", style: Get.textTheme.titleLarge),
        const SizedBox(height: 10),
        if (fileController.recentFiles.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text("No PDFs found"),
            ),
          ),

        ...fileController.recentFiles
            .take(5)
            .map(
              (file) => ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(file.path.split('/').last),
                subtitle: Text(file.path),
                onTap: () {
                  Get.toNamed('/viewer', arguments: file.path);
                },
              ),
            )
            ,
      ],
    );
  }
}
