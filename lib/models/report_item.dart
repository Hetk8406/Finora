import 'dart:convert';

/// Represents a single report entry with an optional attached file.
class ReportItem {
  final String name;
  final bool isSelected;
  final String? filePath;
  final String? fileName;

  const ReportItem({
    required this.name,
    this.isSelected = false,
    this.filePath,
    this.fileName,
  });

  ReportItem copyWith({
    bool? isSelected,
    String? filePath,
    String? fileName,
    bool clearFile = false,
  }) {
    return ReportItem(
      name: name,
      isSelected: isSelected ?? this.isSelected,
      filePath: clearFile ? null : (filePath ?? this.filePath),
      fileName: clearFile ? null : (fileName ?? this.fileName),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isSelected': isSelected,
      'filePath': filePath,
      'fileName': fileName,
    };
  }

  factory ReportItem.fromMap(Map<String, dynamic> map) {
    return ReportItem(
      name: map['name'] ?? '',
      isSelected: map['isSelected'] ?? false,
      filePath: map['filePath'],
      fileName: map['fileName'],
    );
  }

  // Encode a list of ReportItems to a JSON string for database storage
  static String encodeList(List<ReportItem> items) {
    return jsonEncode(items.map((e) => e.toMap()).toList());
  }

  // Decode a JSON string from the database back to a list of ReportItems
  static List<ReportItem> decodeList(String jsonStr) {
    if (jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => ReportItem.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // Default set of reports for a new estimate
  static List<ReportItem> get defaults => const [
    ReportItem(name: 'Balance Sheet'),
    ReportItem(name: 'Profit & Loss'),
    ReportItem(name: 'Cash Book'),
    ReportItem(name: 'Bank Book'),
    ReportItem(name: 'General Ledger'),
  ];
}
