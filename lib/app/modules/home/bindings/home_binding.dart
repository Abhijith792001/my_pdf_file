import 'package:get/get.dart';
import 'package:my_pdf_files/app/controllers/file_controller.dart';
import 'package:my_pdf_files/app/modules/home/controllers/home_controller.dart';


class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    // In a real app we might put this in a global binding or initial binding
    Get.put<FileController>(FileController(), permanent: true);
  }
}
