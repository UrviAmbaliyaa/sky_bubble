class ScoreModel {
  final int score;
  final int level;
  final DateTime playedAt;

  const ScoreModel({
    required this.score,
    required this.level,
    required this.playedAt,
  });

  Map<String, dynamic> toJson() => {
        'score': score,
        'level': level,
        'playedAt': playedAt.toIso8601String(),
      };

  factory ScoreModel.fromJson(Map<String, dynamic> json) => ScoreModel(
        score: (json['score'] as num).toInt(),
        level: (json['level'] as num).toInt(),
        playedAt: DateTime.parse(json['playedAt'] as String),
      );
}
