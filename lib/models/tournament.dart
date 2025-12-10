import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Represents a player in a heat
class Player {
  final String id;
  String name;

  Player({String? id, required this.name}) : id = id ?? _uuid.v4();

  Player copyWith({String? id, String? name}) {
    return Player(id: id ?? this.id, name: name ?? this.name);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(id: json['id'] as String, name: json['name'] as String);
  }
}

/// Represents a heat/round in the tournament
class Heat {
  final String id;
  String title;
  double x;
  double y;
  List<Player> players;
  bool isFinal;

  Heat({
    String? id,
    required this.title,
    this.x = 0,
    this.y = 0,
    List<Player>? players,
    this.isFinal = false,
  }) : id = id ?? _uuid.v4(),
       players = players ?? [];

  double get width => 220;
  // Height calculation based on HeatBox content:
  // - Padding: 12 top + 12 bottom = 24
  // - Header row: ~30
  // - SizedBox(12)
  // - Player cards: each ~46 (card 38 + margin 8)
  // - Add button: 32
  // - SizedBox(8)
  // - Drag bar: ~28
  // Base: 24 + 30 + 12 + 32 + 8 + 28 = 134
  double get height => 134 + (players.length * 46);

  /// Get the position of the right-side connection knob
  Offset get rightKnobPosition => Offset(x + width, y + height / 2);

  /// Get the position of the left-side connection knob
  Offset get leftKnobPosition => Offset(x, y + height / 2);

  Heat copyWith({
    String? id,
    String? title,
    double? x,
    double? y,
    List<Player>? players,
    bool? isFinal,
  }) {
    return Heat(
      id: id ?? this.id,
      title: title ?? this.title,
      x: x ?? this.x,
      y: y ?? this.y,
      players: players ?? this.players.map((p) => p.copyWith()).toList(),
      isFinal: isFinal ?? this.isFinal,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'x': x,
    'y': y,
    'players': players.map((p) => p.toJson()).toList(),
    'isFinal': isFinal,
  };

  factory Heat.fromJson(Map<String, dynamic> json) {
    return Heat(
      id: json['id'] as String,
      title: json['title'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      players: (json['players'] as List)
          .map((p) => Player.fromJson(p as Map<String, dynamic>))
          .toList(),
      isFinal: json['isFinal'] as bool? ?? false,
    );
  }
}

/// Represents a connection between two heats
class Connection {
  final String id;
  final String fromHeatId;
  final String toHeatId;

  Connection({String? id, required this.fromHeatId, required this.toHeatId})
    : id = id ?? _uuid.v4();

  Connection copyWith({String? id, String? fromHeatId, String? toHeatId}) {
    return Connection(
      id: id ?? this.id,
      fromHeatId: fromHeatId ?? this.fromHeatId,
      toHeatId: toHeatId ?? this.toHeatId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromHeatId': fromHeatId,
    'toHeatId': toHeatId,
  };

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      id: json['id'] as String,
      fromHeatId: json['fromHeatId'] as String,
      toHeatId: json['toHeatId'] as String,
    );
  }
}

/// Represents the entire tournament
class Tournament {
  String title;
  List<Heat> heats;
  List<Connection> connections;

  Tournament({
    this.title = 'New Tournament',
    List<Heat>? heats,
    List<Connection>? connections,
  }) : heats = heats ?? [],
       connections = connections ?? [];

  Heat? getHeatById(String id) {
    try {
      return heats.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  void addHeat(Heat heat) {
    heats.add(heat);
  }

  void removeHeat(String heatId) {
    heats.removeWhere((h) => h.id == heatId);
    connections.removeWhere(
      (c) => c.fromHeatId == heatId || c.toHeatId == heatId,
    );
  }

  void addConnection(Connection connection) {
    // Check if connection already exists
    final exists = connections.any(
      (c) =>
          c.fromHeatId == connection.fromHeatId &&
          c.toHeatId == connection.toHeatId,
    );
    if (!exists) {
      connections.add(connection);
    }
  }

  void removeConnection(String connectionId) {
    connections.removeWhere((c) => c.id == connectionId);
  }

  List<Connection> getConnectionsFromHeat(String heatId) {
    return connections.where((c) => c.fromHeatId == heatId).toList();
  }

  List<Connection> getConnectionsToHeat(String heatId) {
    return connections.where((c) => c.toHeatId == heatId).toList();
  }

  Tournament copyWith({
    String? title,
    List<Heat>? heats,
    List<Connection>? connections,
  }) {
    return Tournament(
      title: title ?? this.title,
      heats: heats ?? this.heats.map((h) => h.copyWith()).toList(),
      connections:
          connections ?? this.connections.map((c) => c.copyWith()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'heats': heats.map((h) => h.toJson()).toList(),
    'connections': connections.map((c) => c.toJson()).toList(),
  };

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      title: json['title'] as String? ?? 'Imported Tournament',
      heats:
          (json['heats'] as List?)
              ?.map((h) => Heat.fromJson(h as Map<String, dynamic>))
              .toList() ??
          [],
      connections:
          (json['connections'] as List?)
              ?.map((c) => Connection.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Helper class for Offset since it's not imported by default in models
class Offset {
  final double dx;
  final double dy;
  const Offset(this.dx, this.dy);
}
