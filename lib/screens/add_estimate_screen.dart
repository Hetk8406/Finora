import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/database_helper.dart';
import '../models/estimate.dart';
import '../models/currency.dart';
import '../services/pdf_service.dart';
import '../services/cloud_sync_service.dart';

class AddEstimateScreen extends StatefulWidget {
  final Estimate? estimateToEdit;

  const AddEstimateScreen({super.key, this.estimateToEdit});

  @override
  _AddEstimateScreenState createState() => _AddEstimateScreenState();
}

class _AddEstimateScreenState extends State<AddEstimateScreen> {
  final _formKey = GlobalKey<FormState>();
  final CloudSyncService _syncService = CloudSyncService();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  final _companyController    = TextEditingController();
  final _addressController    = TextEditingController();
  final _emailController      = TextEditingController();
  final _ownerController      = TextEditingController();
  final _phoneController      = TextEditingController();
  final _turnoverController   = TextEditingController();
  final _percentageController = TextEditingController(text: "1");

  String _businessType = 'Service';
  CurrencyModel _selectedCurrency = CurrencyModel.all.firstWhere((c) => c.code == 'INR');
  double _estimatedFee = 0.0;
  String _fullPhoneNumber = '';

  // Working state for reports
  final Map<String, bool> _selectedReports = {
    "Balance Sheet": false,
    "Profit & Loss": false,
    "Cash Book": false,
    "Bank Book": false,
    "General Ledger": false,
  };

  final Map<String, String?> _reportsData = {
    "Balance Sheet": null,
    "Profit & Loss": null,
    "Cash Book": null,
    "Bank Book": null,
    "General Ledger": null,
  };

  @override
  void initState() {
    super.initState();
    if (widget.estimateToEdit != null) {
      final e = widget.estimateToEdit!;
      _companyController.text    = e.companyName;
      _addressController.text    = e.address;
      _emailController.text      = e.email;
      _ownerController.text      = e.ownerName;
      _fullPhoneNumber           = e.phone;
      _turnoverController.text   = e.turnover.toString();
      _percentageController.text = e.feePercentage.toString();
      _businessType              = e.businessType;
      _selectedCurrency          = CurrencyModel.all.firstWhere(
        (c) => c.code == e.currency,
        orElse: () => CurrencyModel.all.first,
      );
      _estimatedFee = e.estimatedFee;

      // Decode reportsData
      try {
        final Map<String, dynamic> decoded = jsonDecode(e.reportsData);
        decoded.forEach((key, value) {
          if (_selectedReports.containsKey(key)) {
            _selectedReports[key] = true;
            _reportsData[key] = value as String?;
          }
        });
      } catch (err) {
        debugPrint("Error decoding reportsData: $err");
      }
    }

    // Dynamic fee listeners
    _turnoverController.addListener(_calculateFee);
    _percentageController.addListener(_calculateFee);
    _calculateFee();
  }

  void _calculateFee() {
    double turnover = double.tryParse(_turnoverController.text) ?? 0.0;
    double percent = double.tryParse(_percentageController.text) ?? 0.0;
    setState(() {
      _estimatedFee = turnover * (percent / 100);
    });
  }

  Future<void> _exportPdf() async {
    if (widget.estimateToEdit != null) {
      await PdfService.generateAndShareEstimate(widget.estimateToEdit!);
    }
  }

  Future<void> _pickFile(String reportName) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _reportsData[reportName] = result.files.single.path;
          _selectedReports[reportName] = true;
        });
      }
    } catch (e) {
      debugPrint("File picking error: $e");
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      if (_fullPhoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid phone number'), backgroundColor: Colors.red),
        );
        return;
      }

      // Create a map of only SELECTED reports to save
      final Map<String, String?> dataToSave = {};
      _selectedReports.forEach((name, isSelected) {
        if (isSelected) {
          dataToSave[name] = _reportsData[name];
        }
      });

      final estimate = Estimate(
        id: widget.estimateToEdit?.id,
        userId: _currentUid,
        companyName:  _companyController.text,
        address:      _addressController.text,
        email:        _emailController.text,
        businessType: _businessType,
        ownerName:    _ownerController.text,
        phone:        _fullPhoneNumber,
        turnover:     double.tryParse(_turnoverController.text) ?? 0.0,
        currency:     _selectedCurrency.code,
        estimatedFee: _estimatedFee,
        feePercentage: double.tryParse(_percentageController.text) ?? 1.0,
        reportsData:  jsonEncode(dataToSave),
        createdAt:    widget.estimateToEdit?.createdAt ??
                      DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      );

      // Save both local and cloud through SyncService
      await _syncService.saveEstimate(estimate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.estimateToEdit != null ? 'Update synced' : 'Estimate synced'), 
            backgroundColor: const Color(0xFF2563EB)),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.estimateToEdit != null ? 'Edit Estimate' : 'New Estimate'),
        centerTitle: true,
        actions: [
          if (widget.estimateToEdit != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Export PDF',
              onPressed: _exportPdf,
            ),
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _sectionTitle(Icons.business_center_rounded, 'Business Details'),
            _textField(_companyController, 'Company Name', Icons.business_rounded),
            _textField(_addressController, 'Business Address', Icons.location_on_rounded, maxLines: 2),
            _textField(_emailController, 'Business Email', Icons.email_rounded, keyboardType: TextInputType.emailAddress),
            
            const SizedBox(height: 16),
            _dropdownField(),

            const SizedBox(height: 24),
            _sectionTitle(Icons.person_rounded, 'Owner Information'),
            _textField(_ownerController, 'Owner Full Name', Icons.person_rounded),
            
            const SizedBox(height: 12),
            IntlPhoneField(
              controller: _phoneController,
              initialValue: widget.estimateToEdit?.phone,
              decoration: _inputDecoration('Phone Number', Icons.phone_rounded),
              initialCountryCode: 'IN',
              onChanged: (phone) => _fullPhoneNumber = phone.completeNumber,
            ),

            const SizedBox(height: 24),
            _sectionTitle(Icons.payments_rounded, 'Financial Overview'),
            _textField(_turnoverController, 'Projected Turnover', Icons.account_balance_wallet_rounded, 
              keyboardType: TextInputType.number, 
              suffix: _currencySelector()),
            _textField(_percentageController, 'Fee Percentage (%)', Icons.percent_rounded, 
              keyboardType: TextInputType.number),

            // Live preview of fee
            Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estimated Fee:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                  Text(
                    '${_selectedCurrency.symbol} ${NumberFormat("#,##,##0.00").format(_estimatedFee)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                  ),
                ],
              ),
            ),

            const Divider(height: 48),
            _sectionTitle(Icons.checklist_rounded, 'Reports Checklist'),
            const SizedBox(height: 8),
            ..._selectedReports.keys.map((name) => _reportItem(name)),
            
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF2563EB)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF6B7280), letterSpacing: 0.5)),
      ],
    ),
  );

  Widget _textField(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1, TextInputType? keyboardType, Widget? suffix}) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, icon).copyWith(suffixIcon: suffix),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    ),
  );

  InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20, color: const Color(0xFF9CA3AF)),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB))),
    filled: true,
    fillColor: Colors.grey.shade50,
    labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
  );

  Widget _dropdownField() => DropdownButtonFormField<String>(
    value: _businessType,
    decoration: _inputDecoration('Business Type', Icons.category_rounded),
    items: ['Service', 'Manufacturing', 'Retail', 'Wholesale', 'Other']
      .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
    onChanged: (v) => setState(() => _businessType = v!),
  );

  Widget _currencySelector() => DropdownButton<String>(
    value: _selectedCurrency.code,
    underline: const SizedBox(),
    onChanged: (v) => setState(() => _selectedCurrency = CurrencyModel.all.firstWhere((c) => c.code == v)),
    items: CurrencyModel.all.map((c) => DropdownMenuItem(value: c.code, child: Text(c.symbol, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))))).toList(),
  );

  Widget _reportItem(String name) {
    bool isSelected = _selectedReports[name]!;
    String? filePath = _reportsData[name];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2563EB).withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? const Color(0xFF2563EB).withOpacity(0.2) : Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: () => setState(() => _selectedReports[name] = !isSelected),
        leading: Checkbox(
          value: isSelected,
          onChanged: (v) => setState(() => _selectedReports[name] = v!),
          activeColor: const Color(0xFF2563EB),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? const Color(0xFF1F2937) : const Color(0xFF6B7280))),
        subtitle: isSelected && filePath != null 
          ? Text(filePath.split('/').last, style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB))) 
          : null,
        trailing: isSelected ? IconButton(
          icon: Icon(filePath == null ? Icons.upload_file_rounded : Icons.edit_rounded, color: const Color(0xFF2563EB)),
          onPressed: () => _pickFile(name),
        ) : null,
      ),
    );
  }
}
