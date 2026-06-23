import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../models/estimate.dart';
import '../models/currency.dart';
import '../database/database_helper.dart';
import 'add_estimate_screen.dart';
import '../services/pdf_service.dart';

class EstimateDetailsScreen extends StatelessWidget {
  final Estimate estimate;
  final VoidCallback onRefresh;

  const EstimateDetailsScreen({
    super.key,
    required this.estimate,
    required this.onRefresh,
  });

  Future<void> _exportPdf() async {
    await PdfService.generateAndShareEstimate(estimate);
  }

  Future<void> _openFile(BuildContext context, String? path) async {
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file attached')),
      );
      return;
    }

    try {
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: ${result.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = CurrencyModel.all.firstWhere(
      (c) => c.code == estimate.currency,
      orElse: () => CurrencyModel.all.first,
    );

    Map<String, dynamic> reportsMap = {};
    try {
      reportsMap = jsonDecode(estimate.reportsData) as Map<String, dynamic>;
    } catch (_) {}

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export PDF',
            onPressed: _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEstimateScreen(estimateToEdit: estimate),
                ),
              );
              if (result == true) {
                onRefresh();
                Navigator.pop(context); // Go back home or let user refresh here
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section('Business Profile', [
              _infoRow('Company', estimate.companyName),
              _infoRow('Address', estimate.address),
              _infoRow('Email', estimate.email),
              _infoRow('Type', estimate.businessType),
            ]),
            const SizedBox(height: 20),
            _section('Owner Details', [
              _infoRow('Name', estimate.ownerName),
              _infoRow('Phone', estimate.phone),
            ]),
            const SizedBox(height: 20),
            _section('Financial Summary', [
              _infoRow('Turnover', '${currency.symbol} ${NumberFormat("#,##,##0.00").format(estimate.turnover)}'),
              _infoRow('Calculated At', '${estimate.feePercentage}%'),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Estimate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    '${currency.symbol} ${NumberFormat("#,##,##0.00").format(estimate.estimatedFee)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF2563EB)),
                  ),
                ],
              ),
            ]),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _exportPdf,
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('Export PDF Report', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Reports & Attachments', 
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
            const SizedBox(height: 12),
            ...reportsMap.entries.map((e) => _reportItem(context, e.key, e.value as String?)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 0.5)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1F2937)))),
        ],
      ),
    );
  }

  Widget _reportItem(BuildContext context, String name, String? path) {
    final bool hasFile = path != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasFile ? const Color(0xFF2563EB).withOpacity(0.2) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(hasFile ? Icons.insert_drive_file_rounded : Icons.radio_button_unchecked, 
            size: 20, color: hasFile ? const Color(0xFF2563EB) : Colors.grey.shade300),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: hasFile ? const Color(0xFF1F2937) : Colors.grey)),
                if (hasFile)
                  Text(path.split('/').last, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (hasFile)
            ElevatedButton(
              onPressed: () => _openFile(context, path),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                foregroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Estimate?'),
        content: const Text('Are you sure you want to delete this estimate? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.delete(estimate.id!);
              onRefresh();
              Navigator.pop(context); // Pop dialog
              Navigator.pop(context); // Pop details screen
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
