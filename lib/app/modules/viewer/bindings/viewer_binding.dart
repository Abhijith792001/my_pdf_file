import 'package:get/get.dart';
import '../controllers/viewer_controller.dart';

class ViewerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ViewerController>(
      () => ViewerController(),
    );
  }
}
