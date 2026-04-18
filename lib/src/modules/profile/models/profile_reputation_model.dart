class TrophyModel {
  final String id;
  final String title;
  final String icon;
  final String date;

  TrophyModel({
    required this.id,
    required this.title,
    required this.icon,
    required this.date,
  });

  factory TrophyModel.fromMap(Map<String, dynamic> map) {
    return TrophyModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      icon: map['icon'] ?? '🏆',
      date: map['date'] ?? '',
    );
  }
}

class ReviewModel {
  final String id;
  final String customerName;
  final String comment;
  final double rating;
  final String date;

  ReviewModel({
    required this.id,
    required this.customerName,
    required this.comment,
    required this.rating,
    required this.date,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'] ?? '',
      customerName: map['customer_name'] ?? 'Cliente Viper',
      comment: map['comment'] ?? '',
      rating: (map['rating'] ?? 5.0).toDouble(),
      date: map['date'] ?? '',
    );
  }
}
