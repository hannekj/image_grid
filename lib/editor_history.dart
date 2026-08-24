import 'package:flutter/material.dart';

/// Lightweight undo stack with a fixed depth.
class EditorHistory<T> {
  EditorHistory({this.maxDepth = 30});

  final int maxDepth;
  final List<T> _stack = <T>[];

  bool get canUndo => _stack.isNotEmpty;

  void push(T snapshot) {
    _stack.add(snapshot);
    if (_stack.length > maxDepth) {
      _stack.removeAt(0);
    }
  }

  T? pop() {
    if (_stack.isEmpty) return null;
    return _stack.removeLast();
  }

  void clear() => _stack.clear();
}
