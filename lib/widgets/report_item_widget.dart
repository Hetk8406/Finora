import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/report_item.dart';

/// A single report row with a custom checkbox + file upload button.
/// Must be StatefulWidget so that local loading state can be shown
/// while the file picker dialog is open.
class ReportItemWidget extends StatefulWidget {
  final ReportItem item;
  final ValueChanged<ReportItem> onChanged;

  const ReportItemWidget({
    super.key,
    required this.item,
    required this.onChanged,
  });

  @override
  State<ReportItemWidget> createState() => _ReportItemWidgetState();
}

class _ReportItemWidgetState extends State<ReportItemWidget> {
  bool _isPicking = false;

  // ── File picker ────────────────────────────────────────────────────────────
  Future<void> _pickFile() async {
    if (_isPicking) return; // Prevent double-tap
    setState(() => _isPicking = true);

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        // On web path is always null — we only need the name
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) {
        // User cancelled — do nothing
        debugPrint('[ReportItemWidget] File picker cancelled');
        return;
      }

      final PlatformFile pickedFile = result.files.first;
      debugPrint('[ReportItemWidget] Picked: ${pickedFile.name} | path: ${pickedFile.path}');

      // On web, path is null; store only the name so UI still shows it.
      final String? storedPath = kIsWeb ? pickedFile.name : pickedFile.path;

      widget.onChanged(widget.item.copyWith(
        isSelected: true,           // Auto-select when file is picked
        filePath: storedPath ?? pickedFile.name,
        fileName: pickedFile.name,
      ));
    } catch (e, st) {
      debugPrint('[ReportItemWidget] Error picking file: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file picker: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _removeFile() {
    widget.onChanged(widget.item.copyWith(clearFile: true));
  }

  void _toggleSelected(bool newValue) {
    if (!newValue && widget.item.filePath != null) {
      // Unchecking → also clear file
      widget.onChanged(widget.item.copyWith(isSelected: false, clearFile: true));
    } else {
      widget.onChanged(widget.item.copyWith(isSelected: newValue));
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool isSelected = widget.item.isSelected;
    final bool hasFile    = widget.item.filePath != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF2563EB).withOpacity(0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF2563EB).withOpacity(0.3)
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Main row ────────────────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _toggleSelected(!isSelected),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  // Custom animated checkbox
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : Colors.grey.shade400,
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Report name
                  Expanded(
                    child: Text(
                      widget.item.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? const Color(0xFF1F2937)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Upload button
                  _buildUploadButton(isSelected, hasFile),
                ],
              ),
            ),
          ),
          // ── File info row ────────────────────────────────────────────────
          if (hasFile)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _fileIcon(widget.item.fileName ?? ''),
                    size: 16,
                    color: const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.item.fileName ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF374151)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: _removeFile,
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: Colors.redAccent),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Upload button widget ───────────────────────────────────────────────────
  Widget _buildUploadButton(bool isEnabled, bool hasFile) {
    return AnimatedOpacity(
      opacity: isEnabled ? 1.0 : 0.35,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        // Only trigger when selected and not already picking
        onTap: (isEnabled && !_isPicking) ? _pickFile : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: hasFile
                ? Colors.green.withOpacity(0.1)
                : const Color(0xFF2563EB).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasFile
                  ? Colors.green.withOpacity(0.4)
                  : const Color(0xFF2563EB).withOpacity(0.3),
            ),
          ),
          child: _isPicking
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasFile
                          ? Icons.check_circle_rounded
                          : Icons.upload_file_rounded,
                      size: 14,
                      color:
                          hasFile ? Colors.green : const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasFile ? 'Attached' : 'Upload',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasFile
                            ? Colors.green
                            : const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  IconData _fileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}
