
import 'package:flutter/material.dart'; // 為了使用 Color

class Tag {
  final int? id; // 資料庫自動增長 ID，可能為空
  final String name; // 標籤名稱
  final int color; // 標籤顏色 (整數，例如 Color.value)
  final String createdAt; // 建立時間 (ISO8601 字串)
  final String? updatedAt; // 更新時間 (ISO8601 字串，可為空)

  Tag({
    this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    this.updatedAt,
  });

  // 從資料庫的 Map 轉換為 Tag 物件
  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'],
      name: map['name'],
      color: map['color'],
      createdAt: map['create_at'],
      updatedAt: map['update_at'],
    );
  }

  // 將 Tag 物件轉換為 Map，以便存入資料庫
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'create_at': createdAt,
      'update_at': updatedAt,
    };
  }

  @override
  String toString() {
    return 'Tag{id: $id, name: $name, color: $color}';
  }
}