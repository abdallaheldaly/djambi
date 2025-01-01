import 'package:meta/meta.dart';

import 'cell.dart';
import 'enums.dart';
import 'members/assassin.dart';
import 'members/chief.dart';
import 'members/diplomat.dart';
import 'members/militant.dart';
import 'members/necromobile.dart';
import 'members/reporter.dart';
import 'parliament.dart';

abstract class Member {
  final Parliament parliament;
  Ideology ideology;

  /// Unique ID across all members in the parliament
  final int id;

  Role get role;
  bool get isChief => role == Role.chief;

  Cell location = const Cell.zero();

  MemberState state = MemberState.active;
  bool get isDead => state == MemberState.dead;
  bool get isAlive => state != MemberState.dead;
  bool get isActive => state == MemberState.active;
  bool get isParalysed => state == MemberState.paralysed;

  Manoeuvre manoeuvre = Manoeuvre.none;

  int? _bodyId;
  Member? get body => _bodyId == null ? null : parliament.members[_bodyId!];

  Member(this.parliament, this.ideology, this.id);

  @override
  String toString() => "${ideology.name}:${role.name}($location)";

  factory Member.create(Parliament parliament, Role role, Ideology ideology, int id) =>
      switch (role) {
        Role.chief =>         Chief(parliament, ideology, id),
        Role.assassin =>      Assassin(parliament, ideology, id),
        Role.reporter =>      Reporter(parliament, ideology, id),
        Role.diplomat =>      Diplomat(parliament, ideology, id),
        Role.necromobile =>   Necromobile(parliament, ideology, id),
        Role.militant =>      Militant(parliament, ideology, id),
      };

  factory Member.copy(Parliament parliament, Member other) =>
      Member.create(parliament, other.role, other.ideology, other.id)
        ..copyFrom(other);

  @protected
  void copyFrom(Member other) {
    // not constant properties
    location = other.location;
    state = other.state;
    // manoeuvre properties
    manoeuvre = other.manoeuvre;
    _bodyId = other._bodyId;
  }

  /// json deserialization
  factory Member.fromJson(Parliament parliament, Map<String, dynamic> json) {
    final member = Member.create(
      parliament,
      Role.values[json["role"] as int],
      Ideology.values[json["ideology"] as int],
      json["id"] as int,
    );
    member.location = Cell.fromJson(json["location"]);
    member.state = MemberState.values[json["state"] as int];
    return member;
  }

  /// json serialization
  Map<String, dynamic> toJson() {
    assert(manoeuvre == Manoeuvre.none, "Serialization is not allowed during a manoeuvre");
    return {
      "role": role.index,
      "ideology": ideology.index,
      "id": id,
      "location": location.toJson(),
      "state": state.index,
    };
  }

  @protected
  void kill(Member member) {
    member.state = MemberState.dead;
    // take over other members if the killed member is a chief
    if (member.isChief) {
      final activeMembers = parliament.getParty(member.ideology).activeMembers;
      for (final activeMember in activeMembers) {
        activeMember.ideology = ideology;
      }
    }
  }

  /// Returns cells that a member can move to.
  ///
  /// The default implementation returns empty cells and cells occupied
  /// by an enemy member or a dead member in all 8 directions.
  Iterable<Cell> cellsToMove({required bool canKill}) sync* {
    for (final dir in Cell.allDirections) {
      for (var cell = location + dir; cell.isValid; cell += dir) {
        // check if cell is occupied
        final member = parliament.getMemberAt(cell);
        if (member != null) {
          // should `break` in all cases to stop this direction after first occupied cell
          if (!canKill) break;
          if (member.isParalysed) break;
          if (member.isActive && member.ideology == ideology) break;
          // if can kill, cell should be occupied by dead or active enemy member
          yield cell;
          break;
        }
        // empty cell
        yield cell;
      }
    }
  }

  Iterable<Cell> cellsToAct() => switch (manoeuvre) {
      Manoeuvre.none => cellsToMove(canKill: true),
      Manoeuvre.move => Cell.allCells().where(canKillOn),
      Manoeuvre.kill => cellsToMove(canKill: false),
      Manoeuvre.exit => Cell.allCells().where(canBuryOn),
      Manoeuvre.end =>  const Iterable.empty(),
    };

  bool canKillOn(Cell cell) => false;
  bool canBuryOn(Cell cell) => !cell.isMaze && parliament.isEmpty(cell);

  void act(Cell cell) {
    switch (manoeuvre) {
      case Manoeuvre.none:  onMove(cell); postMove();
      case Manoeuvre.move:  onKill(cell);
      case Manoeuvre.kill:  onExit(cell);
      case Manoeuvre.exit:  onBury(cell);
      case Manoeuvre.end:   throw AssertionError("Can't act on the `end` state!");
    }
  }

  @protected
  void onMove(Cell cell) {
    assert(cellsToMove(canKill: true).contains(cell), "Can't do an action on the selected cell");
    _bodyId = parliament.getMemberAt(cell)?.id;
    location = cell;
    manoeuvre = Manoeuvre.move;
  }

  @protected
  void postMove() => throw UnsupportedError("Unhandled state!");

  @protected
  void onKill(Cell cell) => throw UnsupportedError("Unhandled state!");

  @protected
  void onExit(Cell cell) {
    assert(cellsToMove(canKill: false).contains(cell), "Can't do an action on the selected cell");
    location = cell;
    manoeuvre = Manoeuvre.exit;
  }

  @protected
  void onBury(Cell cell) {
    assert(canBuryOn(cell), "Can't do an action on the selected cell");
    body!.location = cell;
    manoeuvre = Manoeuvre.end;
  }
}
