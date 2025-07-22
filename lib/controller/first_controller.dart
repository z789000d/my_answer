import 'package:get/get.dart';
import 'package:my_answer/use_case/get_user_data_use_case.dart';
import '../db/database_service.dart';

class FirstController extends GetxController {
  var users = [].obs;

  var cardStatus = [].obs;

  final DatabaseService _dbService = DatabaseService();

  @override
  void onInit() {
    super.onInit();

    users.value = GetUserDataUseCase().execute();
    cardStatus.value = List.filled(users.length, false);

    //這裡可做資料庫操作 拿去了test 驗證了
  }
}
