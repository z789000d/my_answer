import '../abstract_class/note_repository.dart';
import '../db/database_service.dart';
import '../repository/local_note_repository.dart';
import '../repository/remote_note_repository.dart';

enum RepositoryType { local, remote }

class NodeRepositoryUseCase {
  static final NodeRepositoryUseCase _instance =
      NodeRepositoryUseCase._internal();

  factory NodeRepositoryUseCase() => _instance;

  NodeRepositoryUseCase._internal();

  static RepositoryType _currentType = RepositoryType.local; // 預設使用 Local

  // 初始化所有可能的 Repository 實例
  final LocalNoteRepository _localRepo = LocalNoteRepository(DatabaseService());
  final RemoteNoteRepository _remoteRepo = RemoteNoteRepository();

  NoteRepository execute() {
    // 提供當前選定的 NoteRepository 實例
    switch (_currentType) {
      case RepositoryType.local:
        return _localRepo;
      case RepositoryType.remote:
        return _remoteRepo;
    }
  }

  // 切換 Repository 實作的方法
  void setRepositoryType(RepositoryType type) {
    _currentType = type;
    print('Repository Type Switched to: $type');
  }

  // 獲取當前類型
  RepositoryType get currentRepositoryType => _currentType;
}
