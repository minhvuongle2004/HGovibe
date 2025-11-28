import 'package:flutter/material.dart';
import 'package:smart_travel_app/models/destinations/destination.dart';
import 'package:smart_travel_app/services/trips/trip_validation_service.dart';
import 'package:smart_travel_app/services/maps/mapbox_service.dart';
import 'suggested_destination_card.dart';

/// Dialog cảnh báo khoảng cách và gợi ý điểm đến
class DistanceWarningDialog extends StatelessWidget {
  final ValidationResult validationResult;
  final Destination targetDestination;
  final VoidCallback onContinue; // Callback khi user chọn "Vẫn tiếp tục"
  final VoidCallback onCancel; // Callback khi user chọn "Hủy"
  final Function(Destination)?
  onSelectSuggestion; // Callback khi user chọn điểm đề xuất

  const DistanceWarningDialog({
    super.key,
    required this.validationResult,
    required this.targetDestination,
    required this.onContinue,
    required this.onCancel,
    this.onSelectSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    final hasSuggestions =
        validationResult.suggestedDestinations != null &&
        validationResult.suggestedDestinations!.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Cảnh báo khoảng cách',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Thông báo cảnh báo
                    if (validationResult.warningMessage != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          validationResult.warningMessage!,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Thông tin khoảng cách chi tiết
                    if (validationResult.distanceResult != null) ...[
                      _buildInfoRow(
                        icon: Icons.straighten,
                        label: 'Khoảng cách',
                        value:
                            validationResult.distanceResult!.distanceFormatted,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.access_time,
                        label: 'Thời gian di chuyển',
                        value:
                            validationResult.distanceResult!.durationFormatted,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Gợi ý điểm đến
                    if (hasSuggestions) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 20,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Gợi ý điểm đến gần hơn:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...validationResult.suggestedDestinations!.map((dest) {
                        // Tính khoảng cách từ điểm đã chọn (comparedDestination) đến suggestion
                        // Nếu không có comparedDestination, tính từ targetDestination
                        final fromDestination =
                            validationResult.comparedDestination ??
                            targetDestination;

                        return FutureBuilder<double>(
                          future: _getDistanceBetweenDestinations(
                            fromDestination,
                            dest,
                          ),
                          builder: (context, snapshot) {
                            double distance = 0;
                            if (snapshot.hasData) {
                              distance = snapshot.data!;
                            } else if (validationResult.distance != null) {
                              // Fallback: ước tính 50% khoảng cách hiện tại
                              distance = validationResult.distance! * 0.5;
                            }

                            return SuggestedDestinationCard(
                              destination: dest,
                              distance: distance,
                              onTap: () {
                                Navigator.of(context).pop();
                                if (onSelectSuggestion != null) {
                                  onSelectSuggestion!(dest);
                                }
                              },
                            );
                          },
                        );
                      }),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Không tìm thấy điểm đến gần hơn trong khu vực này.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Vẫn tiếp tục'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tính khoảng cách giữa 2 destinations (async)
  Future<double> _getDistanceBetweenDestinations(
    Destination from,
    Destination to,
  ) async {
    try {
      final result = await MapBoxService.instance.calculateDistance(
        from.location.latitude,
        from.location.longitude,
        to.location.latitude,
        to.location.longitude,
      );
      return result?.distance ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Widget hiển thị một dòng thông tin
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Hiển thị dialog
  static Future<void> show(
    BuildContext context, {
    required ValidationResult validationResult,
    required Destination targetDestination,
    required VoidCallback onContinue,
    required VoidCallback onCancel,
    Function(Destination)? onSelectSuggestion,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DistanceWarningDialog(
        validationResult: validationResult,
        targetDestination: targetDestination,
        onContinue: () {
          Navigator.of(context).pop();
          onContinue();
        },
        onCancel: () {
          Navigator.of(context).pop();
          onCancel();
        },
        onSelectSuggestion: onSelectSuggestion,
      ),
    );
  }
}
