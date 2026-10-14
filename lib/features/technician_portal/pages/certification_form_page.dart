import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/coolcare_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../technician_application/models/technician_application_models.dart';
import '../repositories/technician_portal_repository.dart';

class CertificationFormPage extends StatefulWidget {
  const CertificationFormPage({this.certification, super.key});

  final TechnicianCertificationStatus? certification;

  @override
  State<CertificationFormPage> createState() => _CertificationFormPageState();
}

class _CertificationFormPageState extends State<CertificationFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _number;
  late final TextEditingController _issuer;
  late final TechnicianPortalRepository _repository;
  DateTime? _issuedDate;
  DateTime? _expiryDate;
  String? _filePath;
  int? _fileSize;
  bool _submitting = false;
  String? _numberError;

  bool get _isResubmit => widget.certification != null;

  @override
  void initState() {
    super.initState();
    final item = widget.certification;
    _name = TextEditingController(text: item?.name ?? '');
    _number = TextEditingController(text: item?.number ?? '');
    _issuer = TextEditingController(text: item?.issuedBy ?? '');
    _issuedDate = item?.issuedDate;
    _expiryDate = item?.expiryDate;
    _repository = TechnicianPortalRepository(apiClient: ApiClient.fromEnvironment());
  }

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _issuer.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
    final path = file?.path;
    if (path == null) return;
    final size = await File(path).length();
    if (!mounted) return;
    if (size > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tệp minh chứng không được vượt quá 5 MB.')));
      return;
    }
    setState(() {
      _filePath = path;
      _fileSize = size;
    });
  }

  Future<void> _pickDate(bool expiry) async {
    final initial = (expiry ? _expiryDate : _issuedDate) ?? DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: expiry ? DateTime(2100) : DateTime.now(),
    );
    if (result == null) return;
    setState(() {
      if (expiry) {
        _expiryDate = result;
      } else {
        _issuedDate = result;
        if (_expiryDate != null && _expiryDate!.isBefore(result)) _expiryDate = null;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_issuedDate == null) {
      _message('Vui lòng chọn ngày cấp.');
      return;
    }
    if (_expiryDate != null && _expiryDate!.isBefore(_issuedDate!)) {
      _message('Ngày hết hạn phải sau hoặc bằng ngày cấp.');
      return;
    }
    if (_filePath == null) {
      _message(_isResubmit ? 'Vui lòng chọn tệp minh chứng mới.' : 'Vui lòng chọn tệp minh chứng.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await _repository.submitCertification(
        TechnicianCertificateInput(
          name: _name.text,
          number: _number.text,
          issuedBy: _issuer.text,
          issuedDate: _issuedDate,
          expiryDate: _expiryDate,
          imagePath: _filePath!,
        ),
        certificationId: widget.certification?.id,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) {
        final numberError = error.fieldErrors['certificate_number'];
        setState(() => _numberError = numberError);
        _message(numberError ?? error.message);
      }
    } catch (_) {
      if (mounted) _message('Không thể gửi chứng chỉ. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FAFA),
    appBar: AppBar(
      title: Text(_isResubmit ? 'Resubmit Certification' : 'Add Certification'),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_isResubmit) ...[
                  _RejectedAlert(reason: widget.certification!.rejectionReason),
                  const SizedBox(height: 16),
                ],
                _Field(label: 'Tên chứng chỉ', controller: _name, hint: 'VD: Chứng chỉ kỹ thuật HVAC', maxLength: 150),
                _Field(
                  label: 'Số chứng chỉ',
                  controller: _number,
                  hint: 'Nhập số chứng chỉ duy nhất',
                  maxLength: 30,
                  errorText: _numberError,
                  onChanged: (_) {
                    if (_numberError != null) setState(() => _numberError = null);
                  },
                ),
                _Field(label: 'Đơn vị cấp', controller: _issuer, hint: 'VD: Bộ Lao động', maxLength: 150),
                _DateField(label: 'Ngày cấp', value: _issuedDate, onTap: () => _pickDate(false)),
                const SizedBox(height: 12),
                _DateField(label: 'Ngày hết hạn (không bắt buộc)', value: _expiryDate, onTap: () => _pickDate(true), onClear: _expiryDate == null ? null : () => setState(() => _expiryDate = null)),
                const SizedBox(height: 16),
                const Text('Tệp minh chứng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _submitting ? null : _pickFile,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: CoolCareColors.border), borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      const Icon(Icons.upload_file_rounded, size: 30, color: CoolCareColors.primary),
                      const SizedBox(height: 8),
                      Text(_filePath == null ? (_isResubmit ? 'Tải lên tệp rõ nét hơn' : 'Chạm để tải ảnh hoặc PDF') : _filePath!.split(Platform.pathSeparator).last, textAlign: TextAlign.center, style: const TextStyle(color: CoolCareColors.primary, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(_fileSize == null ? 'Hỗ trợ JPG, PNG, PDF tối đa 5 MB' : '${(_fileSize! / 1024).ceil()} KB', style: const TextStyle(color: CoolCareColors.mutedText, fontSize: 11)),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFEAF6F7), borderRadius: BorderRadius.circular(10)),
                  child: const Text('Lưu ý:\n• Nội dung, con dấu và họ tên phải rõ nét.\n• Không bị lóa, bóng hoặc cắt mất góc.\n• Chứng chỉ còn hiệu lực.', style: TextStyle(color: CoolCareColors.mutedText, fontSize: 11, height: 1.55)),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: _submitting ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_isResubmit ? 'Gửi lại chứng chỉ' : 'Gửi chứng chỉ'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    required this.maxLength,
    this.errorText,
    this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        maxLength: maxLength,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          errorText: errorText,
        ),
        validator: (value) => value == null || value.trim().isEmpty
            ? 'Vui lòng nhập $label.'
            : null,
      ),
    ]),
  );
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap, this.onClear});
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
    const SizedBox(height: 6),
    InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: InputDecorator(
      decoration: InputDecoration(suffixIcon: onClear == null ? const Icon(Icons.calendar_month_outlined) : IconButton(onPressed: onClear, icon: const Icon(Icons.close))),
      child: Text(value == null ? 'DD/MM/YYYY' : '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}', style: TextStyle(color: value == null ? CoolCareColors.mutedText : CoolCareColors.text)),
    )),
  ]);
}

class _RejectedAlert extends StatelessWidget {
  const _RejectedAlert({this.reason});
  final String? reason;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
      const SizedBox(width: 8),
      Expanded(child: Text('Bị từ chối: ${reason?.trim().isNotEmpty == true ? reason!.trim() : 'Tệp minh chứng chưa đáp ứng yêu cầu.'}', style: const TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w600))),
    ]),
  );
}
