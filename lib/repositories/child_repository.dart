import '../models/child.dart';

abstract class ChildRepository {
  Future<List<Child>> getAll();
  Future<void> create(Child child);
  Future<void> update(Child child);
  Future<void> delete(String localId);
}
