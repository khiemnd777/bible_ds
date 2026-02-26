enum PortraitExpression {
  neutral,
  calm,
  angry,
  joyful,
  sad,
  confident,
}

extension PortraitExpressionExt on PortraitExpression {
  String get key => switch (this) {
        PortraitExpression.neutral => 'neutral',
        PortraitExpression.calm => 'calm',
        PortraitExpression.angry => 'angry',
        PortraitExpression.joyful => 'joyful',
        PortraitExpression.sad => 'sad',
        PortraitExpression.confident => 'confident',
      };

  static PortraitExpression fromString(String value) {
    for (final expression in PortraitExpression.values) {
      if (expression.key == value) return expression;
    }
    return PortraitExpression.neutral;
  }
}

class PortraitPair {
  final String leftPath;
  final String rightPath;
  final String leftName;
  final String rightName;

  const PortraitPair({
    required this.leftPath,
    required this.rightPath,
    required this.leftName,
    required this.rightName,
  });

  factory PortraitPair.empty() {
    return const PortraitPair(
      leftPath: '',
      rightPath: '',
      leftName: '',
      rightName: '',
    );
  }
}
