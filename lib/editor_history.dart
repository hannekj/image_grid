/// Lightweight undo/redo stack with a fixed depth.
class EditorHistory<T> {
  EditorHistory({this.maxDepth = 30});

  final int maxDepth;
  final List<T> _undo = <T>[];
  final List<T> _redo = <T>[];

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void push(T snapshot) {
    _undo.add(snapshot);
    _redo.clear();
    if (_undo.length > maxDepth) {
      _undo.removeAt(0);
    }
  }

  T? undo(T current) {
    if (_undo.isEmpty) return null;
    _redo.add(current);
    if (_redo.length > maxDepth) {
      _redo.removeAt(0);
    }
    return _undo.removeLast();
  }

  T? redo(T current) {
    if (_redo.isEmpty) return null;
    _undo.add(current);
    if (_undo.length > maxDepth) {
      _undo.removeAt(0);
    }
    return _redo.removeLast();
  }

  void clear() {
    _undo.clear();
    _redo.clear();
  }
}
