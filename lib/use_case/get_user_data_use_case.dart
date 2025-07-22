import '../data/user_data.dart';

class GetUserDataUseCase {
  var userData = [
    UserData(
      imageUrl: 'https://picsum.photos/id/237/200/200',
      title: 'User Profile 1',
      subtitle: 'Software Engineer',
      expandedContent: ['基礎程式設計', '人工智慧總整與實作', '訊號與系統'],
      subContent: ['每週二,10:00~12:00', '每週四,14:00~16:00', '每週五,10:00~12:00'],
    ),
    UserData(
      imageUrl: 'https://picsum.photos/id/238/200/200',
      title: 'User Profile 2',
      subtitle: 'Product Manager',
      expandedContent: ['基礎程式設計', '人工智慧總整與實作', '訊號與系統'],
      subContent: ['每週二,10:00~12:00', '每週四,14:00~16:00', '每週五,10:00~12:00'],
    ),
    UserData(
      imageUrl: 'https://picsum.photos/id/239/200/200',
      title: 'UI/UX Designer',
      subtitle: 'Senior Designer',
      expandedContent: ['基礎程式設計', '人工智慧總整與實作', '訊號與系統'],
      subContent: ['每週二,10:00~12:00', '每週四,14:00~16:00', '每週五,10:00~12:00'],
    ),
    UserData(
      imageUrl: 'https://picsum.photos/id/240/200/200',
      title: 'User Profile 4',
      subtitle: 'Data Scientist',
      expandedContent: ['基礎程式設計', '人工智慧總整與實作', '訊號與系統'],
      subContent: ['每週二,10:00~12:00', '每週四,14:00~16:00', '每週五,10:00~12:00'],
    ),
  ];

  List<UserData> execute() {
    return userData;
  }
}
