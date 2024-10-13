import 'dart:ui';

import 'package:stack/stack.dart';

import '../models/cell.dart';
import '../models/common.dart';
import '../models/member.dart';
import '../models/parliament.dart';
import '../models/ai/tree.dart';

class GameState {
  final _undoStack = Stack<Parliament>();
  final _redoStack = Stack<Parliament>();
  Parliament parliament;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  final VoidCallback? onManoeuvreCompleted;

  GameState(
      Ideology startIdeology, TurnDirection turnDirection, [this.onManoeuvreCompleted])
    : parliament = Parliament(startIdeology, turnDirection);

  void undo() {
    if (canUndo) {
      _redoStack.push(parliament);
      parliament = _undoStack.pop();
    }
  }

  void redo() {
    if (canRedo) {
      _undoStack.push(parliament);
      parliament = _redoStack.pop();
    }
  }

  void doAction(Member member, Cell cell) {
    final newParliament = parliament.makeCopy();
    newParliament.act(member.id, cell);
    _redoStack.clear();
    _undoStack.push(parliament);
    parliament = newParliament;
    if (parliament.isManoeuvreCompleted) {
      onManoeuvreCompleted?.call();
    }
  }

  void aiAct(int maxDepth) {
    if (!parliament.isManoeuvreCompleted) return;
    if (parliament.isGameFinished) return;
    final tree = Tree(parliament, maxDepth);
    tree.build();
    parliament = tree.decision.parliament;
    if (parliament.isManoeuvreCompleted) {
      onManoeuvreCompleted?.call();
    }
  }

  Iterable<Cell> lastMovementCells() sync* {
    if (_undoStack.isEmpty) return;
    final lastParliament = _undoStack.top();
    for (final member in parliament.members) {
      final lastMember = lastParliament.members[member.id];
      if (member.location != lastMember.location) {
        yield member.location;
        yield lastMember.location;
      } else if (member.state != lastMember.state) {
        yield member.location;
      }
    }
  }
}
