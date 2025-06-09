class CloudPhone {
  final String id;
  final String name;
  final String serial;
  final String model;
  final String build;
  final bool isOnline;
  final DateTime lastOnline;
  final DateTime expiredDate;
  final String viewScreenURL;

  CloudPhone({
    required this.id,
    required this.name,
    required this.serial,
    required this.model,
    required this.build,
    required this.isOnline,
    required this.lastOnline,
    required this.expiredDate,
    required this.viewScreenURL,
  });

  factory CloudPhone.fromJson(Map<String, dynamic> json) {
    return CloudPhone(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      serial: json['serial'] ?? '',
      model: json['model'] ?? '',
      build: json['build'] ?? '',
      isOnline: json['isOnline'] ?? false,
      lastOnline: json['lastOnline'] != null ? DateTime.parse(json['lastOnline']) : DateTime.now(),
      expiredDate: json['expiredDate'] != null ? DateTime.parse(json['expiredDate']) : DateTime.now(),
      viewScreenURL: json['viewScreenURL'] ?? '',
    );
  }
}
