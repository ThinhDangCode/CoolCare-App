import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/coolcare_theme.dart';
import '../../../core/network/api_client.dart';
import '../controllers/technician_application_controller.dart';
import '../models/technician_application_models.dart';
import '../repositories/technician_application_repository.dart';

class TechnicianApplicationPage extends StatefulWidget {
  const TechnicianApplicationPage({super.key});

  @override
  State<TechnicianApplicationPage> createState() =>
      _TechnicianApplicationPageState();
}

class _TechnicianApplicationPageState extends State<TechnicianApplicationPage> {
  late final TechnicianApplicationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TechnicianApplicationController(
      TechnicianApplicationRepository(apiClient: ApiClient.fromEnvironment()),
    )..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          context.tr('technicianApplicationTitle'),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_controller.options == null) {
            return _LoadError(
              message:
                  _controller.errorMessage ??
                  context.tr('unableLoadTechnicianApplication'),
              onRetry: _controller.initialize,
            );
          }
          final application = _controller.application;
          if (application != null && application.status != 'REJECTED') {
            return _ApplicationStatusView(application: application);
          }
          return _TechnicianApplicationForm(
            controller: _controller,
            previousApplication: application,
          );
        },
      ),
    );
  }
}

class _TechnicianApplicationForm extends StatefulWidget {
  const _TechnicianApplicationForm({
    required this.controller,
    this.previousApplication,
  });

  final TechnicianApplicationController controller;
  final TechnicianApplicationStatus? previousApplication;

  @override
  State<_TechnicianApplicationForm> createState() =>
      _TechnicianApplicationFormState();
}

class _TechnicianApplicationFormState
    extends State<_TechnicianApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  final _picker = ImagePicker();
  final _selectedWards = <String>{};
  final _selectedSkills = <String>{};
  final _skillLevels = <String, String>{};
  final _certificates = <TechnicianCertificateInput>[];
  String _qualification = 'BEGINNER';
  String? _selectedCity;
  String? _selectedWard;
  String? _selectedSkillId;
  String _selectedSkillLevel = 'BEGINNER';
  String? _identityFrontPath;
  String? _identityBackPath;

  TechnicianApplicationOptions get _options => widget.controller.options!;

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.controller.options?.city;
  }

  @override
  void dispose() {
    _identityController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickIdentity(bool front) async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (image == null || !mounted) return;

    final otherPath = front ? _identityBackPath : _identityFrontPath;
    if (otherPath != null && await _areSameImages(image.path, otherPath)) {
      if (mounted) {
        _showMessage(context.tr('identityImagesMustDiffer'));
      }
      return;
    }

    setState(() {
      if (front) {
        _identityFrontPath = image.path;
      } else {
        _identityBackPath = image.path;
      }
    });
  }

  Future<bool> _areSameImages(String firstPath, String secondPath) async {
    if (firstPath == secondPath) return true;
    try {
      final first = File(firstPath);
      final second = File(secondPath);
      if (await first.length() != await second.length()) return false;
      return listEquals(await first.readAsBytes(), await second.readAsBytes());
    } on FileSystemException {
      return false;
    }
  }

  Future<void> _addCertificate() async {
    final result = await showDialog<TechnicianCertificateInput>(
      context: context,
      builder: (_) => _CertificateDialog(picker: _picker),
    );
    if (result != null && mounted) {
      setState(() => _certificates.add(result));
    }
  }

  void _addSelectedWard() {
    final ward = _selectedWard;
    if (ward == null) return;
    setState(() {
      _selectedWards.add(ward);
      _selectedWard = null;
    });
  }

  void _addSelectedSkill() {
    final skillId = _selectedSkillId;
    if (skillId == null) return;
    setState(() {
      _selectedSkills.add(skillId);
      _skillLevels[skillId] = _selectedSkillLevel;
      _selectedSkillId = null;
      _selectedSkillLevel = 'BEGINNER';
    });
  }

  String _skillLevelLabel(String level) => switch (level) {
    'INTERMEDIATE' => context.tr('qualificationIntermediateShort'),
    'ADVANCED' => context.tr('qualificationAdvancedShort'),
    'EXPERT' => context.tr('qualificationExpertShort'),
    _ => context.tr('qualificationBeginnerShort'),
  };

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    if (_identityFrontPath == null || _identityBackPath == null) {
      _showMessage(context.tr('uploadBothIdentitySides'));
      return;
    }
    final duplicatedIdentityImages = await _areSameImages(
      _identityFrontPath!,
      _identityBackPath!,
    );
    if (!mounted) return;
    if (duplicatedIdentityImages) {
      _showMessage(context.tr('identityImagesMustDiffer'));
      return;
    }
    if (_selectedWards.isEmpty) {
      _showMessage(context.tr('selectAtLeastOneArea'));
      return;
    }
    if (_selectedSkills.isEmpty) {
      _showMessage(context.tr('selectAtLeastOneSkill'));
      return;
    }

    final input = TechnicianApplicationInput(
      identityNumber: _identityController.text,
      identityFrontPath: _identityFrontPath!,
      identityBackPath: _identityBackPath!,
      qualificationLevel: _qualification,
      yearsExperience: int.parse(_experienceController.text),
      bio: _bioController.text,
      city: _selectedCity ?? _options.city,
      wards: _selectedWards.toList(),
      skills: _selectedSkills
          .map(
            (id) => TechnicianSkillInput(
              skillId: id,
              level: _skillLevels[id] ?? 'BEGINNER',
            ),
          )
          .toList(),
      certifications: List.unmodifiable(_certificates),
    );
    final success = await widget.controller.submit(input);
    if (!mounted) return;
    if (!success) {
      _showMessage(
        widget.controller.errorMessage ??
            context.tr('unableSubmitTechnicianApplication'),
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 36),
        children: [
          if (widget.previousApplication?.status == 'REJECTED')
            _RejectedBanner(
              reason: widget.previousApplication?.rejectionReason,
            ),
          const _IntroCard(),
          const SizedBox(height: 18),
          _SectionTitle(
            number: '1',
            title: context.tr('identityInformation'),
            subtitle: context.tr('identityInformationHint'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _identityController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 12,
            decoration: InputDecoration(
              labelText: context.tr('identityNumber'),
              hintText: context.tr('identityNumberHint'),
              counterText: '',
            ),
            validator: (value) {
              final identityNumber = value?.trim() ?? '';
              if (identityNumber.isEmpty) {
                return context.tr('identityNumberRequired');
              }
              if (!RegExp(r'^\d+$').hasMatch(identityNumber)) {
                return context.tr('identityNumberDigitsOnly');
              }
              if (!identityNumber.startsWith('0')) {
                return context.tr('identityNumberStartsZero');
              }
              if (identityNumber.length != 12) {
                return context.tr('identityNumberLength');
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ImagePickerCard(
                  label: context.tr('identityFront'),
                  path: _identityFrontPath,
                  onTap: () => _pickIdentity(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ImagePickerCard(
                  label: context.tr('identityBack'),
                  path: _identityBackPath,
                  onTap: () => _pickIdentity(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle(
            number: '2',
            title: context.tr('professionalExperience'),
            subtitle: context.tr('professionalExperienceHint'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _qualification,
            decoration: InputDecoration(
              labelText: context.tr('currentQualification'),
            ),
            items: [
              DropdownMenuItem(
                value: 'BEGINNER',
                child: Text(context.tr('qualificationBeginnerShort')),
              ),
              DropdownMenuItem(
                value: 'INTERMEDIATE',
                child: Text(context.tr('qualificationIntermediateShort')),
              ),
              DropdownMenuItem(
                value: 'ADVANCED',
                child: Text(context.tr('qualificationAdvancedShort')),
              ),
              DropdownMenuItem(
                value: 'EXPERT',
                child: Text(context.tr('qualificationExpertShort')),
              ),
            ],
            onChanged: (value) => setState(() => _qualification = value!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _experienceController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: context.tr('yearsExperience'),
            ),
            validator: (value) {
              final years = int.tryParse(value ?? '');
              return years != null && years >= 0 && years <= 80
                  ? null
                  : context.tr('yearsExperienceRange');
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bioController,
            minLines: 4,
            maxLines: 7,
            maxLength: 2000,
            decoration: InputDecoration(
              labelText: context.tr('professionalProfile'),
              alignLabelWithHint: true,
              hintText: context.tr('professionalProfileHint'),
            ),
            validator: (value) {
              final length = value?.trim().length ?? 0;
              return length >= 20 && length <= 2000
                  ? null
                  : context.tr('professionalProfileLength');
            },
          ),
          const SizedBox(height: 24),
          _SectionTitle(
            number: '3',
            title: context.tr('serviceAreas'),
            subtitle: context.tr('serviceAreasSelectionHint'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedCity,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: context.tr('provinceCity'),
              prefixIcon: const Icon(Icons.location_city_outlined),
            ),
            items: [
              DropdownMenuItem(
                value: _options.city,
                child: Text(_options.city),
              ),
            ],
            onChanged: (value) => setState(() {
              _selectedCity = value;
              _selectedWard = null;
              _selectedWards.clear();
            }),
            validator: (value) => value == null || value.isEmpty
                ? context.tr('selectProvinceCity')
                : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('ward-${_selectedCity ?? ''}-$_selectedWard'),
            initialValue: _selectedWard,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: context.tr('ward'),
              hintText: _selectedCity == null
                  ? context.tr('selectProvinceFirst')
                  : context.tr('selectServiceWard'),
              prefixIcon: const Icon(Icons.place_outlined),
              suffixIcon: _selectedWard == null
                  ? null
                  : IconButton(
                      tooltip: context.tr('addArea'),
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _addSelectedWard,
                    ),
            ),
            items: _selectedCity == null
                ? const []
                : _options.wards
                      .where((ward) => !_selectedWards.contains(ward))
                      .map(
                        (ward) => DropdownMenuItem(
                          value: ward,
                          child: Text(ward, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
            onChanged: _selectedCity == null
                ? null
                : (value) => setState(() => _selectedWard = value),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: _selectedWard == null ? null : _addSelectedWard,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: Text(context.tr('addArea')),
            ),
          ),
          if (_selectedWards.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              context.trArgs('selectedServiceAreas', {
                'count': _selectedWards.length,
              }),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _selectedWards
                  .map(
                    (ward) => InputChip(
                      avatar: const Icon(Icons.location_on_outlined, size: 18),
                      label: Text(ward),
                      onDeleted: () => setState(() {
                        _selectedWards.remove(ward);
                        if (_selectedWard == ward) {
                          _selectedWard = null;
                        }
                      }),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 24),
          _SectionTitle(
            number: '4',
            title: context.tr('skills'),
            subtitle: context.tr('skillsSelectionHint'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('skill-${_selectedSkillId ?? ''}'),
            initialValue: _selectedSkillId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: context.tr('professionalSkill'),
              hintText: context.tr('selectSkill'),
              prefixIcon: const Icon(Icons.home_repair_service_outlined),
            ),
            items: _options.skills
                .where((skill) => !_selectedSkills.contains(skill.id))
                .map(
                  (skill) => DropdownMenuItem(
                    value: skill.id,
                    child: Text(
                      '${skill.name} — ${skill.serviceName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedSkillId = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey(
              'skill-level-${_selectedSkillId ?? ''}-$_selectedSkillLevel',
            ),
            initialValue: _selectedSkillLevel,
            decoration: InputDecoration(
              labelText: context.tr('proficiencyLevel'),
              prefixIcon: const Icon(Icons.workspace_premium_outlined),
            ),
            items: [
              DropdownMenuItem(
                value: 'BEGINNER',
                child: Text(context.tr('qualificationBeginnerShort')),
              ),
              DropdownMenuItem(
                value: 'INTERMEDIATE',
                child: Text(context.tr('qualificationIntermediateShort')),
              ),
              DropdownMenuItem(
                value: 'ADVANCED',
                child: Text(context.tr('qualificationAdvancedShort')),
              ),
              DropdownMenuItem(
                value: 'EXPERT',
                child: Text(context.tr('qualificationExpertShort')),
              ),
            ],
            onChanged: (value) =>
                setState(() => _selectedSkillLevel = value ?? 'BEGINNER'),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: _selectedSkillId == null ? null : _addSelectedSkill,
              icon: const Icon(Icons.add_circle_outline),
              label: Text(context.tr('addSkill')),
            ),
          ),
          if (_selectedSkills.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              context.trArgs('selectedSkillsCount', {
                'count': _selectedSkills.length,
              }),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ..._selectedSkills.map((skillId) {
              final skill = _options.skills.firstWhere(
                (item) => item.id == skillId,
              );
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.build_outlined, size: 19),
                  ),
                  title: Text(skill.name),
                  subtitle: Text(
                    '${skill.serviceName} • ${_skillLevelLabel(_skillLevels[skillId] ?? 'BEGINNER')}',
                  ),
                  trailing: IconButton(
                    tooltip: context.tr('removeSkill'),
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(() {
                      _selectedSkills.remove(skillId);
                      _skillLevels.remove(skillId);
                    }),
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 24),
          _SectionTitle(
            number: '5',
            title: context.tr('professionalCertifications'),
            subtitle: context.tr('professionalCertificationsHint'),
          ),
          const SizedBox(height: 10),
          ..._certificates.asMap().entries.map(
            (entry) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(
                    File(entry.value.imagePath),
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(entry.value.name),
                subtitle: Text(
                  entry.value.issuedBy ?? context.tr('issuerNotProvided'),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () =>
                      setState(() => _certificates.removeAt(entry.key)),
                ),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _certificates.length >= 10 ? null : _addCertificate,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(context.tr('addCertification')),
          ),
          const SizedBox(height: 26),
          FilledButton.icon(
            onPressed: widget.controller.isSubmitting ? null : _submit,
            icon: widget.controller.isSubmitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(
              widget.controller.isSubmitting
                  ? context.tr('submittingApplication')
                  : context.tr('submitForReview'),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF087F89), Color(0xFF0BA3A8)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.engineering_rounded, color: Colors.white, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('becomeCoolCarePartner'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  context.tr('becomeCoolCarePartnerHint'),
                  style: const TextStyle(color: Colors.white, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: CoolCareColors.primary,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: CoolCareColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({
    required this.label,
    required this.path,
    required this.onTap,
  });

  final String label;
  final String? path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 132,
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.appBorder),
          image: path == null
              ? null
              : DecorationImage(
                  image: FileImage(File(path!)),
                  fit: BoxFit.cover,
                ),
        ),
        child: path == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: CoolCareColors.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(7),
                  color: Colors.black54,
                  child: Text(
                    '$label · ${context.tr('change')}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
      ),
    );
  }
}

class _CertificateDialog extends StatefulWidget {
  const _CertificateDialog({required this.picker});

  final ImagePicker picker;

  @override
  State<_CertificateDialog> createState() => _CertificateDialogState();
}

class _CertificateDialogState extends State<_CertificateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _number = TextEditingController();
  final _issuer = TextEditingController();
  String? _path;
  DateTime? _issuedDate;
  DateTime? _expiryDate;

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _issuer.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final image = await widget.picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (image != null && mounted) setState(() => _path = image.path);
  }

  Future<void> _pickDate({required bool expiry}) async {
    if (expiry && _issuedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('selectIssueDateFirst'))),
      );
      return;
    }

    final firstDate = expiry ? _issuedDate! : DateTime(1950);
    final lastDate = expiry ? DateTime(2100) : DateTime.now();
    final current = expiry ? _expiryDate : _issuedDate;
    final initialDate = current != null && !current.isBefore(firstDate)
        ? current
        : (expiry ? firstDate : DateTime.now());
    final value = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: context
          .tr(expiry ? 'selectExpiryDate' : 'selectIssueDate')
          .toUpperCase(),
    );
    if (value != null && mounted) {
      var expiryWasCleared = false;
      setState(() {
        if (expiry) {
          _expiryDate = value;
        } else {
          _issuedDate = value;
          if (_expiryDate != null && _expiryDate!.isBefore(value)) {
            _expiryDate = null;
            expiryWasCleared = true;
          }
        }
      });
      if (expiryWasCleared && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('expiryClearedAfterIssueChange'))),
        );
      }
    }
  }

  String _displayDate(DateTime? value) {
    if (value == null) return context.tr('optional');
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('addCertification')),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                maxLength: 150,
                decoration: InputDecoration(
                  labelText: context.tr('certificateName'),
                ),
                validator: (value) => value?.trim().isNotEmpty == true
                    ? null
                    : context.tr('certificateNameRequired'),
              ),
              TextField(
                controller: _number,
                maxLength: 30,
                decoration: InputDecoration(
                  labelText: context.tr('certificateNumber'),
                ),
              ),
              TextField(
                controller: _issuer,
                maxLength: 150,
                decoration: InputDecoration(labelText: context.tr('issuedBy')),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(expiry: false),
                      icon: const Icon(Icons.event_outlined),
                      label: Text(
                        '${context.tr('issueDate')}\n${_displayDate(_issuedDate)}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _issuedDate == null
                          ? null
                          : () => _pickDate(expiry: true),
                      icon: const Icon(Icons.event_busy_outlined),
                      label: Text(
                        _issuedDate == null
                            ? '${context.tr('expiryDate')}\n${context.tr('selectIssueDateFirst')}'
                            : '${context.tr('expiryDate')}\n${_displayDate(_expiryDate)}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pick,
                icon: const Icon(Icons.image_outlined),
                label: Text(
                  context.tr(
                    _path == null
                        ? 'selectCertificationImage'
                        : 'certificationImageSelected',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            if (_path == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('selectCertificationImage'))),
              );
              return;
            }
            if (_issuedDate != null &&
                _expiryDate != null &&
                _expiryDate!.isBefore(_issuedDate!)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('expiryAfterIssueDate'))),
              );
              return;
            }
            Navigator.pop(
              context,
              TechnicianCertificateInput(
                name: _name.text.trim(),
                number: _number.text.trim().isEmpty
                    ? null
                    : _number.text.trim(),
                issuedBy: _issuer.text.trim().isEmpty
                    ? null
                    : _issuer.text.trim(),
                issuedDate: _issuedDate,
                expiryDate: _expiryDate,
                imagePath: _path!,
              ),
            );
          },
          child: Text(context.tr('add')),
        ),
      ],
    );
  }
}

class _ApplicationStatusView extends StatelessWidget {
  const _ApplicationStatusView({required this.application});

  final TechnicianApplicationStatus application;

  @override
  Widget build(BuildContext context) {
    final verified = application.status == 'VERIFIED';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: (verified ? Colors.green : Colors.orange)
                  .withValues(alpha: .12),
              child: Icon(
                verified ? Icons.verified_rounded : Icons.hourglass_top_rounded,
                size: 45,
                color: verified
                    ? Colors.green.shade700
                    : Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr(
                verified ? 'applicationVerified' : 'applicationPendingReview',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appText,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              verified
                  ? context.tr('applicationVerifiedHint')
                  : context.tr('applicationPendingReviewHint'),
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appMuted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _RejectedBanner extends StatelessWidget {
  const _RejectedBanner({this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CoolCareColors.error.withValues(alpha: .06),
        border: Border.all(color: CoolCareColors.error.withValues(alpha: .25)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: CoolCareColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.trArgs('applicationRejectedHint', {
                'reason': reason?.trim().isNotEmpty == true
                    ? '\n${context.tr('reason')}: $reason'
                    : '',
              }),
              style: const TextStyle(color: CoolCareColors.error, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text(context.tr('tryAgain')),
            ),
          ],
        ),
      ),
    );
  }
}
