import 'package:flutter/material.dart';

import '../../../app/theme/coolcare_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../technician_application/models/technician_application_models.dart';
import '../../technician_application/repositories/technician_application_repository.dart';
import 'certification_form_page.dart';

class CertificationStatusPage extends StatefulWidget {
  const CertificationStatusPage({super.key});

  @override
  State<CertificationStatusPage> createState() =>
      _CertificationStatusPageState();
}

class _CertificationStatusPageState extends State<CertificationStatusPage> {
  late final TechnicianApplicationRepository _repository;
  TechnicianApplicationStatus? _application;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = TechnicianApplicationRepository(
      apiClient: ApiClient.fromEnvironment(),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repository.loadStatus();
      if (mounted) setState(() => _application = result);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to load verification status.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([TechnicianCertificationStatus? certification]) async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CertificationFormPage(certification: certification),
      ),
    );
    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(certification == null
            ? 'Đã gửi chứng chỉ để xét duyệt.'
            : 'Đã tạo lần nộp mới và chuyển sang chờ duyệt.')),
      );
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FAFA),
    appBar: AppBar(
      title: const Text('My Certifications'),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      actions: [
        IconButton(
          onPressed: _application == null ? null : () => _openForm(),
          tooltip: 'Add certification',
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _StatusError(message: _error!, onRetry: _load)
            : _application == null
            ? const _StatusEmpty()
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _ProfileVerificationCard(application: _application!),
                    const SizedBox(height: 20),
                    const Text(
                      'CERTIFICATIONS',
                      style: TextStyle(
                        color: CoolCareColors.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_application!.certifications.isEmpty)
                      const _NoCertifications()
                    else
                      ..._application!.certifications.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _CertificationCard(
                            item: item,
                            onResubmit: item.status == 'REJECTED'
                                ? () => _openForm(item)
                                : null,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add New Certification'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    ),
  );
}

class _ProfileVerificationCard extends StatelessWidget {
  const _ProfileVerificationCard({required this.application});
  final TechnicianApplicationStatus application;
  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(application.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: CoolCareColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: style.color.withValues(alpha: .12),
                child: Icon(style.icon, color: style.color),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Technician Verification',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Identity and professional profile',
                      style: TextStyle(
                        color: CoolCareColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: application.status),
            ],
          ),
          if (application.submittedAt != null) ...[
            const Divider(height: 28),
            _InfoRow(label: 'Submitted', value: _date(application.submittedAt)),
          ],
          if (application.reviewedAt != null)
            _InfoRow(label: 'Reviewed', value: _date(application.reviewedAt)),
          if (application.status == 'REJECTED')
            _RejectionBox(reason: application.rejectionReason),
        ],
      ),
    );
  }
}

class _CertificationCard extends StatelessWidget {
  const _CertificationCard({required this.item, this.onResubmit});
  final TechnicianCertificationStatus item;
  final VoidCallback? onResubmit;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: CoolCareColors.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.workspace_premium_outlined,
              color: CoolCareColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            _StatusBadge(status: item.status),
          ],
        ),
        const SizedBox(height: 12),
        if (item.number?.isNotEmpty == true)
          _InfoRow(label: 'Certificate No.', value: item.number!),
        if (item.issuedBy?.isNotEmpty == true)
          _InfoRow(label: 'Issued by', value: item.issuedBy!),
        if (item.issuedDate != null)
          _InfoRow(label: 'Issue date', value: _date(item.issuedDate)),
        if (item.expiryDate != null)
          _InfoRow(label: 'Expiry date', value: _date(item.expiryDate)),
        if (item.status == 'REJECTED')
          _RejectionBox(reason: item.rejectionReason),
        if (onResubmit != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onResubmit,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Resubmit'),
            ),
          ),
        ],
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          color: style.color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RejectionBox extends StatelessWidget {
  const _RejectionBox({this.reason});
  final String? reason;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(12),
    width: double.infinity,
    decoration: BoxDecoration(
      color: const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      'Rejection reason\n${reason?.trim().isNotEmpty == true ? reason!.trim() : 'No rejection reason was provided.'}',
      style: const TextStyle(
        color: Color(0xFFB91C1C),
        height: 1.45,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: const TextStyle(
              color: CoolCareColors.mutedText,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

class _NoCertifications extends StatelessWidget {
  const _NoCertifications();
  @override
  Widget build(BuildContext context) => const _CenteredCard(
    icon: Icons.card_membership_outlined,
    title: 'No certifications submitted',
    message: 'Your professional certifications will appear here.',
  );
}

class _StatusEmpty extends StatelessWidget {
  const _StatusEmpty();
  @override
  Widget build(BuildContext context) => const _CenteredCard(
    icon: Icons.person_search_outlined,
    title: 'No technician profile',
    message: 'Submit a technician application to view its verification status.',
  );
}

class _StatusError extends StatelessWidget {
  const _StatusError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => _CenteredCard(
    icon: Icons.cloud_off_outlined,
    title: 'Unable to load status',
    message: message,
    action: FilledButton(onPressed: onRetry, child: const Text('Try Again')),
  );
}

class _CenteredCard extends StatelessWidget {
  const _CenteredCard({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: CoolCareColors.primary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: CoolCareColors.mutedText),
          ),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    ),
  );
}

({Color color, IconData icon, String label}) _statusStyle(String status) =>
    switch (status) {
      'VERIFIED' => (
        color: const Color(0xFF16A34A),
        icon: Icons.verified_rounded,
        label: 'VERIFIED',
      ),
      'REJECTED' => (
        color: const Color(0xFFDC2626),
        icon: Icons.cancel_rounded,
        label: 'REJECTED',
      ),
      _ => (
        color: const Color(0xFFD97706),
        icon: Icons.hourglass_top_rounded,
        label: 'PENDING',
      ),
    };
String _date(DateTime? value) => value == null
    ? '—'
    : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
