import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app/routes/app_pages.dart';
import 'app/theme/app_theme.dart';
import 'app/controllers/theme_controller.dart';
// import 'app/controllers/file_controller.dart'; 

void main() async {
  await GetStorage.init();
  Get.put(ThemeController());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return GetMaterialApp(
      title: 'PDF Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeController.theme,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    );
  }
}
