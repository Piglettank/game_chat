class LeaderboardEntry {
  final String id;
  final String name;
  final int score;

  LeaderboardEntry({
    required this.id,
    required this.name,
    required this.score,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'score': score,
    };
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      score: json['score'] as int,
    );
  }

  LeaderboardEntry copyWith({
    String? id,
    String? name,
    int? score,
  }) {
    return LeaderboardEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      score: score ?? this.score,
    );
  }
}
