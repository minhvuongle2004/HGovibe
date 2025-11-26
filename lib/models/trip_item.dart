import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'destination.dart';

/// Model đại diện cho một điểm đến trong trip
class TripItem {
  final String? id; // Document ID
  final String tripId; // ID của trip
  final String destinationId; // ID của destination
  final Destination? destination; // Cache data (optional)
  final int order; // Thứ tự trong trip (0, 1, 2...)
  final DateTime? plannedDate; // Ngày dự kiến
  final TimeOfDay? plannedTime; // Giờ dự kiến (optional)
  final int? durationHours; // Thời gian dự kiến tại điểm này
  final String? notes; // Ghi chú riêng
  final bool isCompleted; // Đã hoàn thành chưa
  final DateTime? completedAt; // Thời gian hoàn thành

  TripItem({
    this.id,
    required this.tripId,
    required this.destinationId,
    this.destination,
    required this.order,
    this.plannedDate,
    this.plannedTime,
    this.durationHours,
    this.notes,
    this.isCompleted = false,
    this.completedAt,
  });

  /// Convert từ Firestore DocumentSnapshot
  factory TripItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse plannedTime từ string "HH:mm"
    TimeOfDay? plannedTime;
    if (data['plannedTime'] != null) {
      final timeStr = data['plannedTime'] as String;
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        plannedTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }

    return TripItem(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      destinationId: data['destinationId'] ?? '',
      order: data['order'] ?? 0,
      plannedDate: data['plannedDate'] != null
          ? (data['plannedDate'] as Timestamp).toDate()
          : null,
      plannedTime: plannedTime,
      durationHours: data['durationHours'],
      notes: data['notes'],
      isCompleted: data['isCompleted'] ?? false,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert sang Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'destinationId': destinationId,
      'order': order,
      'plannedDate': plannedDate != null
          ? Timestamp.fromDate(plannedDate!)
          : null,
      'plannedTime': plannedTime != null
          ? '${plannedTime!.hour.toString().padLeft(2, '0')}:${plannedTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'durationHours': durationHours,
      'notes': notes,
      'isCompleted': isCompleted,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
    };
  }

  /// Copy với các thay đổi
  TripItem copyWith({
    String? id,
    String? tripId,
    String? destinationId,
    Destination? destination,
    int? order,
    DateTime? plannedDate,
    TimeOfDay? plannedTime,
    int? durationHours,
    String? notes,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return TripItem(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      destinationId: destinationId ?? this.destinationId,
      destination: destination ?? this.destination,
      order: order ?? this.order,
      plannedDate: plannedDate ?? this.plannedDate,
      plannedTime: plannedTime ?? this.plannedTime,
      durationHours: durationHours ?? this.durationHours,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

