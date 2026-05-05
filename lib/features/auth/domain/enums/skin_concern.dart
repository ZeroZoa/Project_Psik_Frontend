enum SkinConcern {
  ACNE("여드름"),
  SCAR("흉터"),
  RECOVERY("피부회복"),
  AGING("노화"),
  WRINKLE("주름"),
  SPOT("잡티/기미/주근깨"),
  WHITENING("미백"),
  BLACKHEAD("블랙헤드"),
  WHITEHEAD("좁쌀/화이트헤드"),
  SUN_CARE("자외선차단"),
  KERATIN("각질/피부결");
  // PORE("모공"),
  // MOISTURIZING("보습/건조"),
  // SENSITIVITY("민감성/홍조"),
  // OILINESS("과다 피지/유분"),
  // DULLNESS("칙칙함/다크서클");

  final String displayName;
  const SkinConcern(this.displayName);
}