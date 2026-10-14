import 'package:flutter/material.dart';

import '../../../app/theme/coolcare_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/technician_skill.dart';
import '../repositories/technician_portal_repository.dart';

class ManageSkillsPage extends StatefulWidget {
  const ManageSkillsPage({super.key});

  @override
  State<ManageSkillsPage> createState() => _ManageSkillsPageState();
}

class _ManageSkillsPageState extends State<ManageSkillsPage> {
  late final TechnicianPortalRepository _repository;
  List<TechnicianSkill> _current = const [];
  List<PortalSkillOption> _options = const [];
  final Set<String> _selected = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = TechnicianPortalRepository(
      apiClient: ApiClient.fromEnvironment(),
    );
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final result = await Future.wait([
        _repository.skills(),
        _repository.skillOptions(),
      ]);
      if (!mounted) return;
      setState(() {
        _current = result[0] as List<TechnicianSkill>;
        _options = result[1] as List<PortalSkillOption>;
        _selected.clear();
        _loading = false;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() { _error = error.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Không thể tải danh sách kỹ năng.'; _loading = false; });
    }
  }

  List<PortalSkillOption> get _availableOptions {
    final currentIds = _current.map((item) => item.skillId).toSet();
    return _options.where((item) => !currentIds.contains(item.id)).toList();
  }

  Future<void> _save() async {
    if (_selected.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      for (final skillId in _selected.toList()) {
        await _repository.addSkill(skillId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật kỹ năng.')),
      );
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      await _load();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove(TechnicianSkill skill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa kỹ năng?'),
        content: Text('Bạn có muốn loại bỏ “${skill.name}” khỏi hồ sơ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.removeSkill(skill.id);
      if (!mounted) return;
      setState(() => _current = _current.where((item) => item.id != skill.id).toList());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã loại bỏ kỹ năng.')),
      );
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F8F9),
    appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
        color: CoolCareColors.primary,
        onPressed: () => Navigator.maybePop(context),
      ),
      titleSpacing: 0,
      title: const Text('My Skills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? _ErrorState(message: _error!, onRetry: _load)
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const _PreviewCard(),
                    const SizedBox(height: 20),
                    _SectionTitle('MY CURRENT SKILLS (${_current.length})'),
                    const SizedBox(height: 8),
                    if (_current.isEmpty)
                      const Text('Chưa có kỹ năng.', style: TextStyle(color: CoolCareColors.mutedText))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _current.map((skill) => _SkillChip(skill: skill, onRemove: () => _remove(skill))).toList(),
                      ),
                    const SizedBox(height: 24),
                    const _SectionTitle('ADD MORE SKILLS'),
                    const SizedBox(height: 10),
                    if (_availableOptions.isEmpty)
                      const Text('Không còn kỹ năng mới để thêm.', style: TextStyle(color: CoolCareColors.mutedText))
                    else
                      ..._availableOptions.map((option) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SkillOptionTile(
                          option: option,
                          selected: _selected.contains(option.id),
                          onChanged: (selected) => setState(() {
                            if (selected) { _selected.add(option.id); } else { _selected.remove(option.id); }
                          }),
                        ),
                      )),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 46,
                      child: FilledButton(
                        onPressed: _selected.isEmpty || _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: CoolCareColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _saving
                            ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save Skills', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
  );
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: const Color(0xFFEAF6F7), borderRadius: BorderRadius.circular(10)),
    child: const Row(children: [
      Icon(Icons.auto_awesome_rounded, size: 16, color: CoolCareColors.primary),
      SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('AC Cleaning (Preview)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        SizedBox(height: 2),
        Text('Reference price from 150,000 VND', style: TextStyle(fontSize: 11, color: CoolCareColors.mutedText)),
      ])),
    ]),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: CoolCareColors.mutedText, fontSize: 13, fontWeight: FontWeight.w700));
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.skill, required this.onRemove});
  final TechnicianSkill skill;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => Material(
    color: skill.isAvailable ? const Color(0xFFEAF6F7) : const Color(0xFFF0F2F3),
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onRemove,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(skill.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: skill.isAvailable ? CoolCareColors.primary : CoolCareColors.mutedText)),
          const SizedBox(width: 6),
          Icon(Icons.close_rounded, size: 15, color: skill.isAvailable ? CoolCareColors.primary : CoolCareColors.mutedText),
        ]),
      ),
    ),
  );
}

class _SkillOptionTile extends StatelessWidget {
  const _SkillOptionTile({required this.option, required this.selected, required this.onChanged});
  final PortalSkillOption option;
  final bool selected;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(side: const BorderSide(color: CoolCareColors.border), borderRadius: BorderRadius.circular(12)),
    child: InkWell(
      onTap: () => onChanged(!selected),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(option.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            if (option.serviceName.isNotEmpty) Text(option.serviceName, style: const TextStyle(fontSize: 11, color: CoolCareColors.mutedText)),
          ])),
          SizedBox.square(
            dimension: 20,
            child: Checkbox(value: selected, onChanged: (value) => onChanged(value ?? false), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
          ),
        ]),
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, size: 44, color: CoolCareColors.primary),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 14),
      OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
    ]),
  ));
}
