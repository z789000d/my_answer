// 假設這是你的第一個頁面 (firstPage)
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_answer/controller/first_controller.dart';

import '../data/user_data.dart';

class FirstPage extends GetView<FirstController> {
  FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => FirstController());
    return Scaffold(
      appBar: AppBar(title: const Text('講師清單')),
      body: Obx(
        () => ListView.builder(
          shrinkWrap: true,
          itemCount: controller.users.length,
          itemBuilder: (BuildContext context, int index) {
            final user = controller.users[index];
            return cardView(user, index);
          },
        ),
      ),
    );
  }

  Widget cardView(UserData userData, int index) {
    return Obx(
      () => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: BorderSide(color: Colors.black, width: 1.0),
        ),
        elevation: 2.0,
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(userData.imageUrl),
                radius: 25,
              ),
              title: Text(
                userData.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(userData.subtitle),
              trailing: IconButton(
                icon: Icon(
                  controller.cardStatus[index] ? Icons.remove : Icons.add,
                ),
                onPressed: () {
                  controller.cardStatus[index] = !controller.cardStatus[index];
                },
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
            ),
            if (controller.cardStatus[index])
              Padding(
                padding: EdgeInsets.only(
                  top: 10,
                  bottom: 10,
                  left: 16,
                  right: 16,
                ),
                child: Column(
                  children: [
                    Divider(
                      height: 2,
                      indent: 16, // 左邊縮進
                      endIndent: 16, // 右邊縮進
                      color: Colors.grey,
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 16, bottom: 16),
                      child: itemView(userData),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget itemView(UserData userData) {
    var userContentList = userData.expandedContent;
    var subContentList = userData.subContent;

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: userContentList.length,
      itemBuilder: (BuildContext context, int index) {
        return Padding(
          padding: EdgeInsets.only(top: 5, bottom: 5),
          child: Row(
            children: [
              // 左邊：圓形圖片
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Icon(Icons.accessibility),
              ),
              // 中間：標題和副標題文字 (使用 Expanded 讓文字佔據剩餘空間)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // 文字靠左對齊
                  children: [
                    Text(
                      userContentList[index],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      subContentList[index],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Icon(
                  Icons.arrow_forward_ios, // 向右的箭頭圖標
                  color: Colors.grey,
                  size: 20.0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
