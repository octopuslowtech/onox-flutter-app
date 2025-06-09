class StoreCloudPhone {
  final String id;
  final int countDevice;
  final int price;
  final String description;
  final String author;
  final String model;
  final String build;
  final String memoryInfo;
  final String storageInfo;
  final String screenInfo;
  final String cpuInfo;
  final String imagePreview;
  final bool isRooted;
  final String osVersion;
  final int location;
  final int minHours;

  StoreCloudPhone({
    required this.id,
    required this.countDevice,
    required this.price,
    required this.description,
    required this.author,
    required this.model,
    required this.build,
    required this.memoryInfo,
    required this.storageInfo,
    required this.screenInfo,
    required this.cpuInfo,
    required this.imagePreview,
    required this.isRooted,
    required this.osVersion,
    required this.location,
    required this.minHours,
  });

  factory StoreCloudPhone.fromJson(Map<String, dynamic> json) {
    return StoreCloudPhone(
      id: json['id'] ?? '',
      countDevice: json['countDevice'] ?? 0,
      price: json['price'] ?? 0,
      description: json['description'] ?? '',
      author: json['author'] ?? '',
      model: json['model'] ?? '',
      build: json['build'] ?? '',
      memoryInfo: json['memoryInfo'] ?? '',
      storageInfo: json['storageInfo'] ?? '',
      screenInfo: json['screenInfo'] ?? '',
      cpuInfo: json['cpuInfo'] ?? '',
      imagePreview: json['imagePreview'] ?? '',
      isRooted: json['isRooted'] ?? false,
      osVersion: json['osVersion'] ?? '',
      location: json['location'] ?? 0,
      minHours: json['minHours'] ?? 0,
    );
  }
}
