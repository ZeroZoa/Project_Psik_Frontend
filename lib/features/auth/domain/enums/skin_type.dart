enum SkinType {
  DRY('건성'),
  OILY('지성'),
  COMBINATION('복합성'),
  SENSITIVE('민감성'),
  NORMAL('중성');

  final String displayName;
  const SkinType(this.displayName);
}