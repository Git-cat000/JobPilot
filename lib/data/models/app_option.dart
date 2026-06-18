class AppOption {
  const AppOption({
    required this.type,
    required this.value,
    required this.label,
  });

  final String type;
  final String value;
  final String label;

  Map<String, Object?> toMap() => {
    'type': type,
    'value': value,
    'label': label,
  };

  factory AppOption.fromMap(Map<String, Object?> map) {
    return AppOption(
      type: map['type'] as String? ?? '',
      value: map['value'] as String? ?? '',
      label: map['label'] as String? ?? '',
    );
  }
}
