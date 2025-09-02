import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'note.g.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  late int id;
  @HiveField(1)
  late String title;
  @HiveField(2)
  late String content;
  @HiveField(3)
  late int accent;
  @HiveField(4)
  late DateTime createdAt;
  @HiveField(5)
  late bool isPrivate;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.accent,
    required this.createdAt,
    required this.isPrivate,
  });
}
