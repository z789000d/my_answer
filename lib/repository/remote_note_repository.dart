// lib/repositories/remote_note_repository.dart
import 'dart:async';
import 'dart:math';

import 'package:dart_either/dart_either.dart';
import 'package:my_answer/repository/local_note_repository.dart';

import '../abstract_class/Failure.dart';
import '../abstract_class/note_repository.dart';
import '../data/note.dart';

class RemoteNoteRepository implements NoteRepository {
  //我這邊以map json 作為遠端資料
  final Map<String, List<Note>> _mockRemoteData = {};

  final Random _random;
  int _nextNoteId = 1000;

  final StreamController<List<Note>> _streamController;

  RemoteNoteRepository({
    Random? random,
    StreamController<List<Note>>? streamController,
  }) : _random = random ?? Random(),
       _streamController = streamController ?? StreamController.broadcast();

  void _notifyListeners(String userId) {
    if (!_streamController.isClosed) {
      _streamController.add(_getNotesForUser(userId));
    }
  }

  Map<String, List<Note>> getNoteMap() {
    return _mockRemoteData;
  }

  List<Note> _getNotesForUser(String userId) {
    final notes = _mockRemoteData[userId] ?? [];
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  @override
  Stream<List<Note>> watchAll(String userId) {
    Future.delayed(Duration.zero, () {
      _notifyListeners(userId);
    });
    return _streamController.stream.map(
      (allNotes) =>
          allNotes.where((note) => note.userId == userId).toList()..sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
          ), // Sort by createdAt DESC
    );
  }

  @override
  Future<Either<Failure, Note>> save(Note note) async {
    await Future.delayed(const Duration(milliseconds: 500)); // 模擬網絡延遲

    // 我這邊製作可修改機率模擬 error
    if (_random.nextInt(100) < 0) {
      print('Remote Save Error: Simulating a 500 server error.');
      return Left(NetworkFailure('Server Error: 500 Internal Server Error'));
    }

    try {
      Note savedNote;
      _mockRemoteData.putIfAbsent(note.userId, () => []);

      if (note.id == null || note.id! >= _nextNoteId) {
        savedNote = note.copyWith(
          id: _nextNoteId++,
          createdAt:
              note.createdAt.isEmpty
                  ? DateTime.now().toIso8601String()
                  : note.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
        );
        _mockRemoteData[savedNote.userId]!.add(savedNote);
      } else {
        final index = _mockRemoteData[note.userId]!.indexWhere(
          (n) => n.id == note.id,
        );
        if (index != -1) {
          savedNote = note.copyWith(
            updatedAt: DateTime.now().toIso8601String(),
          );
          _mockRemoteData[note.userId]![index] = savedNote;
        } else {
          savedNote = note.copyWith(
            id: _nextNoteId++,
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
          );
          _mockRemoteData[savedNote.userId]!.add(savedNote);
        }
      }
      print('Remote Save Success: ${savedNote.title} (ID: ${savedNote.id})');
      _notifyListeners(savedNote.userId); // 通知 Stream 有數據更新
      return Right(savedNote);
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      print('Remote Save Unforeseen Error: $e');
      return Left(
        UnknownFailure(
          'An unexpected error occurred during remote save: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> softDelete(String id) async {
    await Future.delayed(const Duration(milliseconds: 300)); // 模擬網絡延遲

    // 我這邊製作可修改機率模擬 error
    if (_random.nextInt(100) < 0) {
      print('Remote Soft Delete Error: Simulating a network issue.');
      return Left(NetworkFailure('Network unreachable.'));
    }

    try {
      bool found = false;
      String? userIdDeleted;
      // Iterate through all users' notes to find the note by ID
      for (final userId in _mockRemoteData.keys) {
        final notes = _mockRemoteData[userId]!;

        final index = notes.indexWhere((note) => note.id.toString() == id);
        if (index != -1) {
          notes[index] = notes[index].copyWith(
            isDeleted: 1,
            updatedAt: DateTime.now().toIso8601String(),
          );
          found = true;
          userIdDeleted = userId;
          break; // Found and updated, exit the loop
        }
      }

      if (found) {
        print('Remote Soft Delete Success: Note ID $id marked as deleted.');
        if (userIdDeleted != null) {
          _notifyListeners(userIdDeleted); // 通知 Stream 有數據更新
        }
        return Right(true);
      } else {
        print('Remote Soft Delete Failed: Note ID $id not found.');

        return Left(NetworkFailure('Note with ID $id not found on remote.'));
      }
    } catch (e) {
      if (e is Failure) {
        return Left(e);
      }
      print('Remote Soft Delete Unforeseen Error: $e');
      return Left(
        UnknownFailure(
          'An unexpected error occurred during remote soft delete: ${e.toString()}',
        ),
      );
    }
  }

  // Dispose method to close the internal StreamController
  void dispose() {
    _streamController.close();
  }
}
