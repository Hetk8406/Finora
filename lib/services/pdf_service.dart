import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/estimate.dart';
import '../models/currency.dart';

class PdfService {
  static Future<void> generateAndShareEstimate(Estimate estimate) async {
    final pdf = pw.Document();

    // Load logo
    ByteData? logoData;
    try {
      logoData = await rootBundle.load('assets/logo.png');
    } catch (_) {}
    final logo = logoData != null ? pw.MemoryImage(logoData.buffer.asUint8List()) : null;

    final currency = CurrencyModel.all.firstWhere(
      (c) => c.code == estimate.currency,
      orElse: () => CurrencyModel.all.first,
    );

    // Decode reportsData
    Map<String, dynamic> reportsMap = {};
    try {
      reportsMap = jsonDecode(estimate.reportsData) as Map<String, dynamic>;
    } catch (_) {}

    final blueColor = PdfColor.fromInt(0xFF2563EB); // Finora Blue
    final greyColor = PdfColor.fromInt(0xFF4B5563);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      if (logo != null) pw.Image(logo, width: 80, height: 80),
                      pw.SizedBox(height: 10),
                      pw.Text('FINORA', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: blueColor)),
                      pw.Text('Professional Accounting Estimate', style: pw.TextStyle(fontSize: 12, color: greyColor)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),
                
                // Client & Business Details
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _sectionHeader('Client Details'),
                          _detailRow('Company', estimate.companyName),
                          _detailRow('Address', estimate.address),
                          _detailRow('Email', estimate.email),
                          _detailRow('Owner', estimate.ownerName),
                          _detailRow('Phone', estimate.phone),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 40),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _sectionHeader('Business Context'),
                          _detailRow('Type', estimate.businessType),
                          _detailRow('Date', DateFormat('dd MMM yyyy').format(DateTime.now())),
                        ],
                      ),
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 40),

                // Financials section
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Projected Turnover', style: pw.TextStyle(color: greyColor)),
                          pw.Text('${currency.symbol} ${NumberFormat("#,##,##0.00").format(estimate.turnover)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Divider(height: 20),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Fee Percentage', style: pw.TextStyle(color: greyColor)),
                          pw.Text('${estimate.feePercentage}%', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.SizedBox(height: 20),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('ESTIMATED FEE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: blueColor)),
                          pw.Text('${currency.symbol} ${NumberFormat("#,##,##0.00").format(estimate.estimatedFee)}', 
                            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: blueColor)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 40),

                // Reports checklist
                _sectionHeader('Reports & Attachments'),
                pw.SizedBox(height: 10),
                ...reportsMap.entries.map((e) {
                  final hasFile = e.value != null;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 10, height: 10,
                          decoration: pw.BoxDecoration(color: hasFile ? blueColor : PdfColors.grey300, shape: pw.BoxShape.circle),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Text(e.key, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        if (hasFile) pw.Text(' (Attached: ${e.value.split('/').last})', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                      ],
                    ),
                  );
                }).toList(),

                pw.Spacer(),
                
                // Footer
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Divider(color: PdfColors.grey300),
                      pw.SizedBox(height: 5),
                      pw.Text('Generated by Finora App', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
                      pw.Text('Professional Ledger & Estimation System', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey400)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Share PDF
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Estimate_${estimate.companyName}.pdf');
  }

  static pw.Widget _sectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
          pw.Container(height: 2, width: 30, color: PdfColors.blue),
        ],
      ),
    );
  }

  static pw.Widget _detailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey), ),
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
