import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hackathon_salvara/app/router.dart';
import 'package:hackathon_salvara/core/errors/app_exception.dart';
import 'package:hackathon_salvara/features/reports/domain/report.dart';
import 'package:hackathon_salvara/features/reports/report_providers.dart';
import 'package:image_picker/image_picker.dart';

class CreateReportScreen extends ConsumerStatefulWidget {
  const CreateReportScreen({super.key});

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  ReportCategory _category = ReportCategory.other;
  XFile? _photo;
  bool _locationLoading = false;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _descCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) setState(() => _photo = picked);
  }

  Future<void> _detectLocation() async {
    setState(() => _locationLoading = true);
    try {
      final permission = await Geolocator.checkPermission();
      final effective = permission == LocationPermission.denied
          ? await Geolocator.requestPermission()
          : permission;

      if (effective == LocationPermission.denied ||
          effective == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin lokasi ditolak. Masukkan koordinat secara manual.',
              ),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      _latCtrl.text = position.latitude.toStringAsFixed(6);
      _lngCtrl.text = position.longitude.toStringAsFixed(6);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mendapatkan lokasi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final lat = double.parse(_latCtrl.text.trim());
      final lng = double.parse(_lngCtrl.text.trim());

      final report = await ref.read(reportRepositoryProvider).createReport(
            description: _descCtrl.text.trim(),
            category: _category,
            latitude: lat,
            longitude: lng,
            locationAddress: _addressCtrl.text.trim().isNotEmpty
                ? _addressCtrl.text.trim()
                : null,
            photoPath: _photo?.path,
          );

      // Invalidate list so it refreshes on return.
      ref.invalidate(reportsProvider);

      if (mounted) {
        context.go(AppRoutes.reportDetail(report.id));
      }
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Laporan gagal dikirim. Coba lagi.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Laporan')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Category
                DropdownButtonFormField<ReportCategory>(
                  // ignore: deprecated_member_use
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: ReportCategory.values
                      .map(
                        // ignore: deprecated_member_use
                        (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _category = v ?? _category),
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi masalah',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Deskripsi tidak boleh kosong.'
                      : null,
                ),
                const SizedBox(height: 16),

                // Location
                Text('Lokasi', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latCtrl,
                        decoration: const InputDecoration(labelText: 'Lintang'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Wajib diisi.';
                          }
                          if (double.tryParse(v.trim()) == null) {
                            return 'Angka tidak valid.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lngCtrl,
                        decoration: const InputDecoration(labelText: 'Bujur'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Wajib diisi.';
                          }
                          if (double.tryParse(v.trim()) == null) {
                            return 'Angka tidak valid.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    _locationLoading
                        ? const SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.my_location),
                            tooltip: 'Gunakan lokasi saat ini',
                            onPressed: _detectLocation,
                          ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama lokasi / alamat (opsional)',
                  ),
                ),
                const SizedBox(height: 16),

                // Photo
                Text('Foto (opsional)', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (_photo != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_photo!.path),
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton.filled(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _photo = null),
                          tooltip: 'Hapus foto',
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Kamera'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Galeri'),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),

                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 12),
                ],

                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Kirim Laporan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
