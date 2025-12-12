import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/tools_controller.dart';

class ToolsView extends GetView<ToolsController> {
  const ToolsView({super.key});

  @override
  Widget build(BuildContext context) {
    // If controller is not found (because we access it from HomeView's IndexedStack without binding being called purely via route),
    // we might need to put it. 
    // However, for this MVP, we will assume we navigated or injected it. 
    // BUT! Since it is inside HomeView IndexedStack, we should put it in HomeBinding or lazily put it here?
    // Let's use Get.put if not registered to be safe for this nested usage, or better yet, make HomeView use ToolsView as a widget.
    
    Get.lazyPut(()=>ToolsController()); 
    
    return GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
            _buildToolCard(
                icon: Icons.image, 
                label: "Image to PDF", 
                onTap: controller.convertImageToPdf
            ),
            _buildToolCard(
                icon: Icons.merge, 
                label: "Merge PDFs", 
                onTap: controller.mergePdfs
            ),
            _buildToolCard(
                icon: Icons.call_split, 
                label: "Split PDF", 
                onTap: controller.splitPdf
            ),
             _buildToolCard(
                icon: Icons.compress, 
                label: "Compress", 
                onTap: () {}
            ),
        ],
    );
  }

  Widget _buildToolCard({required IconData icon, required String label, required VoidCallback onTap}) {
      return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      Icon(icon, size: 48, color: Get.theme.primaryColor),
                      const SizedBox(height: 16),
                      Text(label, style: const TextStyle(fontWeight: FontWeight.bold))
                  ],
              ),
          ),
      );
  }
}
