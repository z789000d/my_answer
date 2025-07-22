import 'package:dart_either/dart_either.dart';

import '../data/note.dart';
import 'Failure.dart';

//note 三功能的抽象類別
abstract class NoteRepository {
  //監聽抽象
  Stream<List<Note>> watchAll(String userId);

  Future<Either<Failure, Note>> save(Note note);

  Future<Either<Failure, bool>> softDelete(String id);
}

