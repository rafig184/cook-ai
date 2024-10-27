import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class StatesController extends GetxController {
  RxBool isCameraButton = false.obs;
  StatesController() {}

  void cameraButtonChangeTrue() {
    isCameraButton = true.obs;
  }

  void cameraButtonChangeFalse() {
    isCameraButton = false.obs;
  }
}
