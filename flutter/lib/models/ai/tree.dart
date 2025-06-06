import 'package:collection/collection.dart';

import '../../common/utils.dart';
import '../cell.dart';
import '../constants.dart';
import '../enums.dart';
import '../member.dart';
import '../parliament.dart';
import 'evaluation.dart';

class Node {
  Node(this.parliament, this.parent) : depth = _newDepth(parent, parliament) {
    parent?.subNodes.add(this);
  }

  static int _newDepth(Node? parent, Parliament parliament) => parent?.depth
      .convert((d) => parliament.isManoeuvreCompleted ? d + 1 : d) ?? 0;

  final Parliament parliament;

  final int depth;
  final Node? parent;
  final List<Node> subNodes = [];
  Node? _bestSubNode;
  Map<Ideology, int> _evaluations = {};

  Node get bestSubNode => _bestSubNode ?? this;

  void evaluate(PartyEvaluation evaluateParty) {
    assert(subNodes.isEmpty, "evaluate should run on leaf nodes only");
    assert(parliament.isManoeuvreCompleted, "the maneuver should be completed");
    _evaluations = { for (final p in parliament.parties) p.ideology: evaluateParty(p) };
  }

  Iterable<Member> _whoCanAct() => parliament.isManoeuvreCompleted
      ? parliament.currentParty.activeMembers
      : [parliament.actor!];

  Iterable<(Member, Cell)> availableActions() sync* {
    for (final member in _whoCanAct()) {
      // as the algorithm doesn't go deep in the tree,
      // it is better to shuffle available cell to make it looks smarter.
      // if it can go deeper, then use the next line instead to improve performance
      // yield* member.cellsToAct().map((cell) => (member, cell));
      final cells = member.cellsToAct().toList()..shuffle();
      yield* cells.map((cell) => (member, cell));
    }
  }

  void calcMaxN() {
    assert(_evaluations.isEmpty, "evaluations is expected to be empty");
    assert(subNodes.isNotEmpty, "should run on NONE leaf nodes");
    var max = Constants.minInt;
    Map<Ideology, int>? evaluations;
    Node? bestSub;
    for (final subNode in subNodes) {
      final nodeValue = subNode._evaluations[parliament.currentParty.ideology]!;
      final subMax = subNode._evaluations.values.map((v) => nodeValue - v).sum;
      if (subMax > max) {
        max = subMax;
        evaluations = subNode._evaluations;
        bestSub = subNode.parliament.isManoeuvreCompleted
            ? subNode : subNode.bestSubNode;
      }
    }
    _evaluations = evaluations!;
    _bestSubNode = bestSub;
  }
}

class Tree {
  Tree(Parliament parliament, this.maxDepth) : _root = Node(parliament, null);

  final Node _root;
  final int maxDepth;
  final PartyEvaluation evaluateParty = defaultPartyEvaluation;
  final Set<String> _visitedNodes = {};
  // int _level = 0; // just used for debugging

  Node get decision => _root.bestSubNode;

  void build() {
    assert(_root.parliament.isManoeuvreCompleted, "the maneuver should be completed");
    assert(!_root.parliament.isGameFinished, "the game should be still ongoing");
    _visitedNodes.add(_root.parliament.getSign());
    _createSubNodes(_root);
  }

  void _createSubNodes(Node node) {
    assert(node.depth <= maxDepth, "exceed the maximum depth!");
    if (node.parliament.isGameFinished || node.depth == maxDepth) {
      node.evaluate(evaluateParty);
    } else {
      for (final (member, cell) in node.availableActions()) {
        _doAction(node, member, cell);
      }
      if (node.subNodes.isEmpty) {
        // all sub nodes are visited
        node.parent!.subNodes.remove(node);
      } else {
        // calc max^n
        node.calcMaxN();
      }
    }
  }

  void _doAction(Node node, Member member, Cell cell) {
    // print("${'- ' * _level}do action: $member => $cell [${member.manoeuvre.name}]");
    final copy = node.parliament.makeCopy();
    copy.act(member.id, cell);
    if (copy.isManoeuvreCompleted && !_visitedNodes.add(copy.getSign())) {
      // print("${'  ' * _level}// skip");
      return;
    }
    final subNode = Node(copy, node);
    _createSubNodes(subNode);
  }
}
