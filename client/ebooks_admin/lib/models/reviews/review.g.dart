// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Review _$ReviewFromJson(Map<String, dynamic> json) => Review(
  user: json['user'] == null
      ? null
      : User.fromJson(json['user'] as Map<String, dynamic>),
  book: json['book'] == null
      ? null
      : Book.fromJson(json['book'] as Map<String, dynamic>),
  modifiedAt: json['modifiedAt'] == null
      ? null
      : DateTime.parse(json['modifiedAt'] as String),
  rating: (json['rating'] as num?)?.toInt(),
  comment: json['comment'] as String?,
  reportedById: (json['reportedById'] as num?)?.toInt(),
);

Map<String, dynamic> _$ReviewToJson(Review instance) => <String, dynamic>{
  'user': instance.user,
  'book': instance.book,
  'modifiedAt': instance.modifiedAt?.toIso8601String(),
  'rating': instance.rating,
  'comment': instance.comment,
  'reportedById': instance.reportedById,
};
