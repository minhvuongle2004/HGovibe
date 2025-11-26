import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/trip_cost_estimate.dart';
import '../models/trip.dart';
import '../providers/trip_provider.dart';
import '../providers/user_provider.dart';
import '../services/ai_plan_service.dart';
import 'ai_plan_viewer.dart';

/// Widget hiển thị breakdown chi phí với TabBarView lồng nhau
class CostBreakdownWidget extends StatefulWidget {
  final TripCostEstimate costEstimate;
  final Trip trip;
  final String tripId; // Cần tripId để gọi lại estimateCost

  const CostBreakdownWidget({
    super.key,
    required this.costEstimate,
    required this.trip,
    required this.tripId,
  });

  @override
  State<CostBreakdownWidget> createState() => _CostBreakdownWidgetState();
}

class _CostBreakdownWidgetState extends State<CostBreakdownWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasAIPlan = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAIPlan();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAIPlan() async {
    final plan = await AIPlanService.instance.getCurrentAIPlan(widget.tripId);
    if (mounted) {
      setState(() {
        _hasAIPlan = plan != null && plan.description.isNotEmpty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TabBar cho Chi phí và Kế hoạch
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chi phí'),
            Tab(text: 'Kế hoạch'),
          ],
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
        ),
        // TabBarView
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCostTab(context),
              AIPlanViewer(tripId: widget.tripId),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCostTab(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Tổng chi phí
          Card(
            color: Colors.orange.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    'Tổng chi phí ước tính',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(widget.costEstimate.total),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${currencyFormat.format(widget.costEstimate.perPerson)} / người',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Banner: Bạn có thể tham khảo kế hoạch của trợ lý AI đưa ra
          if (_hasAIPlan) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade50,
                    Colors.blue.shade100,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.shade200,
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  // Chuyển sang tab "Kế hoạch"
                  _tabController.animateTo(1);
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bạn có thể tham khảo kế hoạch của trợ lý AI đưa ra',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Xem kế hoạch chi tiết theo từng ngày',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          // Breakdown items
          const Text(
            'Tổng hợp chi phí',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildCostItem(
            context,
            'Vé tham quan',
            widget.costEstimate.entranceFees,
            widget.costEstimate.total,
            Icons.confirmation_number,
            Colors.blue,
            currencyFormat,
          ),
          _buildCostItem(
            context,
            'Ăn uống',
            widget.costEstimate.food,
            widget.costEstimate.total,
            Icons.restaurant,
            Colors.green,
            currencyFormat,
          ),
          _buildCostItem(
            context,
            'Nơi ở',
            widget.costEstimate.accommodation,
            widget.costEstimate.total,
            Icons.hotel,
            Colors.purple,
            currencyFormat,
          ),
          _buildCostItem(
            context,
            'Di chuyển',
            widget.costEstimate.transportation,
            widget.costEstimate.total,
            Icons.directions_car,
            Colors.orange,
            currencyFormat,
          ),
          _buildCostItem(
            context,
            'Mua sắm',
            widget.costEstimate.shopping,
            widget.costEstimate.total,
            Icons.shopping_bag,
            Colors.pink,
            currencyFormat,
          ),
          _buildCostItem(
            context,
            'Chi phí phát sinh',
            widget.costEstimate.miscellaneous,
            widget.costEstimate.total,
            Icons.more_horiz,
            Colors.grey,
            currencyFormat,
          ),
          const SizedBox(height: 24),
          // Budget comparison (nếu có)
          if (widget.trip.budgetLimit != null) ...[
            const Divider(),
            const SizedBox(height: 16),
            _buildBudgetComparison(
              context,
              widget.costEstimate.total,
              widget.trip.budgetLimit!,
              currencyFormat,
            ),
          ],
          const SizedBox(height: 16),
          // Nút điều chỉnh nhu cầu
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showAdjustDialog(context, -0.2); // Thấp hơn 20%
                  },
                  icon: const Icon(Icons.trending_down),
                  label: const Text('Nhu cầu thấp hơn'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showAdjustDialog(context, 0.2); // Cao hơn 20%
                  },
                  icon: const Icon(Icons.trending_up),
                  label: const Text('Nhu cầu cao hơn'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Nút tính toán lại
          Consumer<TripProvider>(
            builder: (context, tripProvider, _) {
              final isEstimating = tripProvider.isEstimatingCost;
              return SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isEstimating
                      ? null
                      : () {
                          final userProvider = context.read<UserProvider>();
                          if (userProvider.user != null) {
                            // Reset multiplier và tính lại
                            tripProvider.resetCostMultiplier();
                            tripProvider.estimateCost(
                              userProvider.user!.uid,
                              widget.tripId,
                            );
                          }
                        },
                  icon: isEstimating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(isEstimating ? 'Đang tính toán...' : 'Tính toán lại'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.orange),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // AI Model info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.costEstimate.aiModel == 'fallback'
                        ? 'Ước tính dựa trên công thức chuẩn'
                        : 'Ước tính bằng AI (${widget.costEstimate.aiModel})',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostItem(
    BuildContext context,
    String label,
    double amount,
    double total,
    IconData icon,
    Color color,
    NumberFormat currencyFormat,
  ) {
    final percentage = total > 0 ? (amount / total * 100) : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(amount),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetComparison(
    BuildContext context,
    double estimated,
    double budgetLimit,
    NumberFormat currencyFormat,
  ) {
    final difference = estimated - budgetLimit;
    final isOverBudget = difference > 0;
    final percentage = budgetLimit > 0 ? (estimated / budgetLimit * 100) : 0.0;

    return Card(
      color: isOverBudget ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOverBudget ? Icons.warning : Icons.check_circle,
                  color: isOverBudget ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  'So với budget',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isOverBudget ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget giới hạn',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      currencyFormat.format(budgetLimit),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Ước tính',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      currencyFormat.format(estimated),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isOverBudget ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage > 100 ? 1.0 : percentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget ? Colors.red : Colors.green,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isOverBudget
                  ? 'Vượt quá ${currencyFormat.format(difference.abs())} (${(percentage - 100).toStringAsFixed(1)}%)'
                  : 'Còn lại ${currencyFormat.format(difference.abs())} (${(100 - percentage).toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isOverBudget ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Removed: _buildDescriptionText - không còn dùng nữa vì đã chuyển sang tab riêng

  /// Hiển thị dialog xác nhận điều chỉnh nhu cầu
  void _showAdjustDialog(BuildContext context, double multiplierChange) {
    final tripProvider = context.read<TripProvider>();
    
    // Nếu đang estimate, không cho phép
    if (tripProvider.isEstimatingCost) {
      return;
    }
    
    final isIncrease = multiplierChange > 0;
    final percentage = (multiplierChange.abs() * 100).toStringAsFixed(0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isIncrease ? 'Nhu cầu cao hơn' : 'Nhu cầu thấp hơn'),
        content: Text(
          'Bạn muốn điều chỉnh mức chi tiêu ${isIncrease ? "cao hơn" : "thấp hơn"} $percentage%?\n\n'
          'AI sẽ tính toán lại với các đề xuất ${isIncrease ? "chất lượng cao hơn" : "tiết kiệm hơn"}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Gọi lại estimateCost với multiplier mới
              final userProvider = context.read<UserProvider>();
              final tripProvider = context.read<TripProvider>();
              
              if (userProvider.user != null) {
                tripProvider.estimateCost(
                  userProvider.user!.uid,
                  widget.tripId,
                  multiplierChange: multiplierChange,
                ).then((_) {
                  // Sau khi estimate xong, kiểm tra lại AIPlan
                  _checkAIPlan();
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isIncrease ? Colors.orange : Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}

