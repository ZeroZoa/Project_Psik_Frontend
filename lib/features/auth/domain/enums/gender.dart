enum Gender {
  MALE('남성'),
  FEMALE('여성'),
  OTHER('기타');

  final String displayName;
  const Gender(this.displayName);
}