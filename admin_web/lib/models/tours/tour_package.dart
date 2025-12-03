import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:admin_web/models/tours/tour_itinerary_day.dart';
import 'package:admin_web/models/tours/tour_inclusions.dart';
import 'package:admin_web/models/tours/tour_exclusions.dart';
import 'package:admin_web/models/tours/cancellation_policy.dart';
import 'package:admin_web/models/tours/price_tier.dart';

/// Loại giá tour
enum PriceType {
  perPerson, // Theo người
  perRoom, // Theo phòng
  perGroup, // Theo nhóm
}

/// Loại tour
enum TourType {
  private, // Tour riêng
  group, // Tour nhóm
  selfGuided, // Tự túc
}

/// Trạng thái tour
enum TourStatus {
  active, // Đang hoạt động
  inactive, // Tạm dừng
  soldOut, // Hết chỗ
}

/// Model đại diện cho một tour package
class TourPackage {
  final String? id; // Document ID từ Firestore
  final String title; // Tên tour
  final String description; // Mô tả chi tiết
  final String shortDescription; // Mô tả ngắn
  final List<String> images; // Hình ảnh tour
  final String thumbnail; // Ảnh đại diện

  // Địa điểm & thời gian
  final String destination; // Địa điểm chính
  final List<String> destinations; // Danh sách điểm đến
  final int durationDays; // Số ngày
  final int durationNights; // Số đêm
  final List<DateTime> availableDates; // Các ngày khởi hành có sẵn

  // Giá cả
  final double basePrice; // Giá gốc 1 người
  final double? childPrice; // Giá trẻ em
  final double? infantPrice; // Giá em bé
  final PriceType priceType; // Loại giá
  final List<PriceTier> priceTiers; // Giá theo số người
  final String currency; // Đơn vị tiền tệ

  // Lịch trình
  final List<TourItineraryDay> itinerary; // Lịch trình từng ngày

  // Điều kiện & chính sách
  final TourInclusions inclusions; // Bao gồm
  final TourExclusions exclusions; // Không bao gồm
  final CancellationPolicy cancellationPolicy; // Chính sách hủy
  final String? termsAndConditions; // Điều khoản

  // Thông tin tour
  final TourType type; // Loại tour
  final int maxGroupSize; // Số người tối đa
  final int minGroupSize; // Số người tối thiểu
  final String? language; // Ngôn ngữ hướng dẫn
  final String? pickupLocation; // Điểm đón
  final String? dropoffLocation; // Điểm trả

  // Đánh giá & thống kê
  final double rating; // Điểm đánh giá
  final int reviewCount; // Số lượt đánh giá
  final int bookingCount; // Số lượt đặt
  final int viewCount; // Số lượt xem

  // Trạng thái
  final TourStatus status; // Trạng thái
  final bool featured; // Tour nổi bật

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final String providerId; // ID đối tác
  final String providerName; // Tên đối tác
  final String providerType; // "app" hoặc "partner"

  TourPackage({
    this.id,
    required this.title,
    required this.description,
    required this.shortDescription,
    required this.images,
    required this.thumbnail,
    required this.destination,
    required this.destinations,
    required this.durationDays,
    required this.durationNights,
    required this.availableDates,
    required this.basePrice,
    this.childPrice,
    this.infantPrice,
    required this.priceType,
    this.priceTiers = const [],
    this.currency = 'VND',
    required this.itinerary,
    required this.inclusions,
    required this.exclusions,
    required this.cancellationPolicy,
    this.termsAndConditions,
    required this.type,
    required this.maxGroupSize,
    required this.minGroupSize,
    this.language,
    this.pickupLocation,
    this.dropoffLocation,
    required this.rating,
    required this.reviewCount,
    required this.bookingCount,
    required this.viewCount,
    required this.status,
    required this.featured,
    required this.createdAt,
    required this.updatedAt,
    required this.providerId,
    required this.providerName,
    required this.providerType,
  });

  /// Convert từ Firestore DocumentSnapshot
  factory TourPackage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TourPackage.fromMap(data, id: doc.id);
  }

  /// Convert từ Map (Firestore hoặc JSON)
  factory TourPackage.fromMap(Map<String, dynamic> map, {String? id}) {
    // Parse availableDates
    final availableDatesList = <DateTime>[];
    if (map['availableDates'] != null) {
      final dates = map['availableDates'] as List<dynamic>;
      for (final date in dates) {
        if (date is Timestamp) {
          availableDatesList.add(date.toDate());
        } else if (date is String) {
          availableDatesList.add(DateTime.parse(date));
        }
      }
    }

    // Parse priceType
    PriceType priceType;
    switch (map['priceType'] as String?) {
      case 'per_person':
        priceType = PriceType.perPerson;
        break;
      case 'per_room':
        priceType = PriceType.perRoom;
        break;
      case 'per_group':
        priceType = PriceType.perGroup;
        break;
      default:
        priceType = PriceType.perPerson;
    }

    // Parse type
    TourType type;
    switch (map['type'] as String?) {
      case 'private':
        type = TourType.private;
        break;
      case 'group':
        type = TourType.group;
        break;
      case 'self_guided':
        type = TourType.selfGuided;
        break;
      default:
        type = TourType.group;
    }

    // Parse status
    TourStatus status;
    switch (map['status'] as String?) {
      case 'active':
        status = TourStatus.active;
        break;
      case 'inactive':
        status = TourStatus.inactive;
        break;
      case 'sold_out':
        status = TourStatus.soldOut;
        break;
      default:
        status = TourStatus.active;
    }

    return TourPackage(
      id: id ?? map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      shortDescription: map['shortDescription'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      thumbnail: map['thumbnail'] ?? '',
      destination: map['destination'] ?? '',
      destinations: List<String>.from(map['destinations'] ?? []),
      durationDays: map['durationDays'] ?? 0,
      durationNights: map['durationNights'] ?? 0,
      availableDates: availableDatesList,
      basePrice: (map['basePrice'] as num?)?.toDouble() ?? 0.0,
      childPrice: (map['childPrice'] as num?)?.toDouble(),
      infantPrice: (map['infantPrice'] as num?)?.toDouble(),
      priceType: priceType,
      priceTiers: (map['priceTiers'] as List<dynamic>?)
              ?.map((e) => PriceTier.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      currency: map['currency'] ?? 'VND',
      itinerary: (map['itinerary'] as List<dynamic>?)
              ?.map((e) => TourItineraryDay.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      inclusions: TourInclusions.fromMap(map['inclusions'] ?? {}),
      exclusions: TourExclusions.fromMap(map['exclusions'] ?? {}),
      cancellationPolicy: CancellationPolicy.fromMap(
        map['cancellationPolicy'] ?? {},
      ),
      termsAndConditions: map['termsAndConditions'],
      type: type,
      maxGroupSize: map['maxGroupSize'] ?? 0,
      minGroupSize: map['minGroupSize'] ?? 0,
      language: map['language'],
      pickupLocation: map['pickupLocation'],
      dropoffLocation: map['dropoffLocation'],
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: map['reviewCount'] ?? 0,
      bookingCount: map['bookingCount'] ?? 0,
      viewCount: map['viewCount'] ?? 0,
      status: status,
      featured: map['featured'] ?? false,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      providerId: map['providerId'] ?? '',
      providerName: map['providerName'] ?? '',
      providerType: map['providerType'] ?? 'app',
    );
  }

  /// Convert sang Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'shortDescription': shortDescription,
      'images': images,
      'thumbnail': thumbnail,
      'destination': destination,
      'destinations': destinations,
      'durationDays': durationDays,
      'durationNights': durationNights,
      'availableDates': availableDates.map((d) => Timestamp.fromDate(d)).toList(),
      'basePrice': basePrice,
      if (childPrice != null) 'childPrice': childPrice,
      if (infantPrice != null) 'infantPrice': infantPrice,
      'priceType': _priceTypeToString(priceType),
      'priceTiers': priceTiers.map((e) => e.toMap()).toList(),
      'currency': currency,
      'itinerary': itinerary.map((e) => e.toMap()).toList(),
      'inclusions': inclusions.toMap(),
      'exclusions': exclusions.toMap(),
      'cancellationPolicy': cancellationPolicy.toMap(),
      if (termsAndConditions != null) 'termsAndConditions': termsAndConditions,
      'type': _typeToString(type),
      'maxGroupSize': maxGroupSize,
      'minGroupSize': minGroupSize,
      if (language != null) 'language': language,
      if (pickupLocation != null) 'pickupLocation': pickupLocation,
      if (dropoffLocation != null) 'dropoffLocation': dropoffLocation,
      'rating': rating,
      'reviewCount': reviewCount,
      'bookingCount': bookingCount,
      'viewCount': viewCount,
      'status': _statusToString(status),
      'featured': featured,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'providerId': providerId,
      'providerName': providerName,
      'providerType': providerType,
    };
  }

  String _priceTypeToString(PriceType type) {
    switch (type) {
      case PriceType.perPerson:
        return 'per_person';
      case PriceType.perRoom:
        return 'per_room';
      case PriceType.perGroup:
        return 'per_group';
    }
  }

  String _typeToString(TourType type) {
    switch (type) {
      case TourType.private:
        return 'private';
      case TourType.group:
        return 'group';
      case TourType.selfGuided:
        return 'self_guided';
    }
  }

  String _statusToString(TourStatus status) {
    switch (status) {
      case TourStatus.active:
        return 'active';
      case TourStatus.inactive:
        return 'inactive';
      case TourStatus.soldOut:
        return 'sold_out';
    }
  }

  /// Tính giá cho số người cụ thể
  double calculatePrice({
    required int numberOfAdults,
    int numberOfChildren = 0,
    int numberOfInfants = 0,
  }) {
    final totalPeople = numberOfAdults + numberOfChildren + numberOfInfants;
    
    // Tìm price tier phù hợp
    double adultPrice = basePrice;
    if (priceTiers.isNotEmpty) {
      for (final tier in priceTiers) {
        if (tier.matches(totalPeople)) {
          adultPrice = tier.pricePerPerson;
          break;
        }
      }
    }

    // Tính tổng
    double total = adultPrice * numberOfAdults;
    if (numberOfChildren > 0 && childPrice != null) {
      total += childPrice! * numberOfChildren;
    }
    if (numberOfInfants > 0 && infantPrice != null) {
      total += infantPrice! * numberOfInfants;
    }

    return total;
  }
}

