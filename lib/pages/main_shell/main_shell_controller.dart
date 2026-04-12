import 'package:get/get.dart';

class MainShellController extends GetxController {
  final currentTabIndex = 0.obs;

  void changeTab(int index) {
    currentTabIndex.value = index;
  }
}
