import 'package:get/get.dart';

import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/viewer/bindings/viewer_binding.dart';
import '../modules/viewer/views/viewer_view.dart';
import '../modules/editor/bindings/editor_binding.dart';
import '../modules/editor/views/editor_view.dart';
import '../modules/tools/bindings/tools_binding.dart';
import '../modules/tools/views/tools_view.dart';
import '../modules/chat/bindings/chat_binding.dart';
import '../modules/chat/views/chat_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.VIEWER,
      page: () => const ViewerView(),
      binding: ViewerBinding(),
    ),
    GetPage(
      name: _Paths.EDITOR,
      page: () => const EditorView(),
      binding: EditorBinding(),
    ),
    GetPage(
      name: _Paths.TOOLS,
      page: () => const ToolsView(),
      binding: ToolsBinding(),
    ),
    GetPage(
      name: _Paths.CHAT,
      page: () => const ChatView(),
      binding: ChatBinding(),
    ),
  ];
}
