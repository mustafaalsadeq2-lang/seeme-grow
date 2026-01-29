class PhotoItem {
  final String id;
  final String childId;
  final int year;
  final String imagePath;

  PhotoItem({
    required this.id,
    required this.childId,
    required this.year,
    required this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'childId': childId,
        'year': year,
        'imagePath': imagePath,
      };

  factory PhotoItem.fromJson(Map<String, dynamic> json) {
    return PhotoItem(
      id: json['id'],
      childId: json['childId'],
      year: json['year'],
      imagePath: json['imagePath'],
    );
  }
}
