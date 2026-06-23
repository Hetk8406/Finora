import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/estimate.dart';
import '../models/currency.dart';
import '../database/database_helper.dart';
import '../screens/add_estimate_screen.dart';
import '../screens/estimate_details_screen.dart';

class EstimateCard extends StatelessWidget {
  final Estimate estimate;
  final VoidCallback onDeleted;
  final VoidCallback onEdited;

  const EstimateCard({
    super.key,
    required this.estimate,
    required this.onDeleted,
    required this.onEdited,
  });

  @override
  Widget build(BuildContext context) {
    final currency = CurrencyModel.all.firstWhere(
      (c) => c.code == estimate.currency,
      orElse: () => CurrencyModel.all.first,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EstimateDetailsScreen(estimate: estimate, onRefresh: onDeleted),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(estimate.companyName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    _statusChip(estimate.businessType),
                  ],
                ),
                const SizedBox(height: 10),
                Row(children: [
                  _infoItem(Icons.person_rounded, estimate.ownerName),
                  const SizedBox(width: 16),
                  _infoItem(Icons.calendar_today_rounded, estimate.createdAt.split(' ')[0]),
                ]),
                const Divider(height: 24, thickness: 0.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Estimated Fee', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      Text(
                        '${currency.symbol} ${NumberFormat("#,##,##0.00").format(estimate.estimatedFee)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                      ),
                    ]),
                    Row(children: [
                      _iconBtn(Icons.edit_outlined, Colors.blue, () => _editAction(context)),
                      const SizedBox(width: 8),
                      _iconBtn(Icons.delete_outline_rounded, Colors.red, () => _deleteAction(context)),
                    ]),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
    );
  }

  Widget _infoItem(IconData icon, String text) => Row(children: [
    Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
    const SizedBox(width: 4),
    Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
  ]);

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon, size: 20, color: color),
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _editAction(BuildContext context) async {
    final result = await Navigator.push(context,
        MaterialPageRoute(builder: (_) => AddEstimateScreen(estimateToEdit: estimate)));
    if (result == true) onEdited();
  }

  void _deleteAction(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Estimate?'),
        content: const Text('This record will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.delete(estimate.id!);
              Navigator.pop(context);
              onDeleted();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
