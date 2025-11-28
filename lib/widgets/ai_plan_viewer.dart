import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/ai_plan.dart';
import '../services/ai_plan_service.dart';

/// Widget hiển thị kế hoạch chi tiết từ AI
class AIPlanViewer extends StatefulWidget {
  final String tripId;
  final String userId;

  const AIPlanViewer({
    super.key,
    required this.tripId,
    required this.userId,
  });

  @override
  State<AIPlanViewer> createState() => _AIPlanViewerState();
}

class _AIPlanViewerState extends State<AIPlanViewer> {
  AIPlan? _currentPlan;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlan();
    // Listen to real-time updates
    _subscribeToPlan();
  }

  void _loadPlan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final plan = await AIPlanService.instance.getCurrentAIPlan(widget.userId, widget.tripId);
      if (mounted) {
        setState(() {
          _currentPlan = plan;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lỗi khi tải kế hoạch: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _subscribeToPlan() {
    AIPlanService.instance.watchCurrentAIPlan(widget.userId, widget.tripId).listen((plan) {
      if (mounted) {
        setState(() {
          _currentPlan = plan;
        });
      }
    });
  }

  // Removed: _requestAdjustment - tính năng điều chỉnh lịch trình sẽ được implement sau

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPlan,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_currentPlan == null || _currentPlan!.description.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có kế hoạch từ AI',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kế hoạch sẽ được tạo tự động khi tính toán chi phí',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header với nút điều chỉnh
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.blueGrey.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.blueGrey[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kế hoạch từ AI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Model: ${_currentPlan!.aiModel}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Nút điều chỉnh (tạm thời ẩn, chờ implement)
              // IconButton(
              //   icon: const Icon(Icons.tune),
              //   tooltip: 'Điều chỉnh',
              //   onPressed: () => _showAdjustmentMenu(context),
              // ),
            ],
          ),
        ),
        // Nội dung markdown
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: MarkdownBody(
              data: _currentPlan!.description,
              styleSheet: MarkdownStyleSheet(
                h1: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                h2: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                h3: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                strong: const TextStyle(fontWeight: FontWeight.bold),
                p: const TextStyle(fontSize: 14, height: 1.5),
                listBullet: const TextStyle(fontSize: 14),
                code: TextStyle(
                  backgroundColor: Colors.grey[200],
                  fontFamily: 'monospace',
                ),
                codeblockDecoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

