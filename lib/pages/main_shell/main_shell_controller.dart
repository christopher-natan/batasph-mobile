import 'package:get/get.dart';

class MainShellController extends GetxController {
  final currentTabIndex = 0.obs;
  final loadedTabIndexes = <int>{0}.obs;

  void changeTab(int index) {
    loadedTabIndexes.add(index);
    currentTabIndex.value = index;
  }

  bool isTabLoaded(int index) {
    return loadedTabIndexes.contains(index);
  }
}
