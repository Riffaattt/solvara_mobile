import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hackathon_salvara/app/router.dart';
import 'package:hackathon_salvara/core/errors/app_exception.dart';
import 'package:hackathon_salvara/features/reports/domain/category.dart';
import 'package:hackathon_salvara/features/reports/report_providers.dart';
import 'package:image_picker/image_picker.dart';

class CreateReportScreen extends ConsumerStatefulWidget {
  const CreateReportScreen({super.key});

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  Category? _selectedCategory;
  XFile? _photo;
  bool _locationLoading = false;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto-detect location when the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) => _detectLocation());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    // Compress to keep upload under PHP post_max_size limit.
    final picked = await picker.pickImage(source: source, imageQuality: 60, maxWidth: 1920);
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
    if (_selectedCategory == null) {
      setState(() => _errorMessage = 'Pilih kategori terlebih dahulu.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final lat = _latCtrl.text.trim().isNotEmpty
          ? double.tryParse(_latCtrl.text.trim())
          : null;
      final lng = _lngCtrl.text.trim().isNotEmpty
          ? double.tryParse(_lngCtrl.text.trim())
          : null;

      final submissionId = await ref.read(reportRepositoryProvider).createReport(
            categoryId: _selectedCategory!.id,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            latitude: lat,
            longitude: lng,
            addressText: _addressCtrl.text.trim().isNotEmpty
                ? _addressCtrl.text.trim()
                : null,
            photoPath: _photo?.path,
          );

      if (mounted) {
        context.go(AppRoutes.submissionTracking(submissionId));
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
    final categoriesAsync = ref.watch(categoriesProvider);
    final primaryColor = Colors.blue.shade700;

    InputDecoration inputDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        title: const Text(
          'Buat Laporan',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Category — loaded from API
                categoriesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(
                    'Gagal memuat kategori: $e',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  data: (categories) => DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    decoration: inputDecoration('Kategori', Icons.category_outlined),
                    hint: const Text('Pilih kategori'),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                    validator: (v) => v == null ? 'Pilih kategori.' : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                TextFormField(
                  controller: _titleCtrl,
                  decoration: inputDecoration('Judul laporan', Icons.title_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Judul tidak boleh kosong.';
                    if (v.trim().length < 5) return 'Judul minimal 5 karakter.';
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descCtrl,
                  decoration: inputDecoration('Deskripsi masalah', Icons.description_outlined).copyWith(
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Deskripsi tidak boleh kosong.';
                    if (v.trim().length < 20) return 'Deskripsi minimal 20 karakter.';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Location Section Header
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Lokasi Kejadian',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latCtrl,
                        decoration: inputDecoration('Lintang', Icons.map_outlined),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lngCtrl,
                        decoration: inputDecoration('Bujur', Icons.map_outlined),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 56,
                      width: 56,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.blue.shade200),
                          ),
                        ),
                        onPressed: _locationLoading ? null : _detectLocation,
                        tooltip: 'Gunakan lokasi saat ini',
                        icon: _locationLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryColor,
                                ),
                              )
                            : Icon(Icons.my_location, color: primaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: inputDecoration('Nama lokasi / alamat (opsional)', Icons.place_outlined),
                ),
                const SizedBox(height: 24),

                // Photo Section Header
                Row(
                  children: [
                    Icon(Icons.camera_alt_outlined, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Foto Bukti (opsional)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_photo != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_photo!.path),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.6),
                          ),
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => setState(() => _photo = null),
                          tooltip: 'Hapus foto',
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: Colors.blue.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _pickPhoto(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Kamera'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: Colors.blue.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _pickPhoto(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Galeri'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 28),

                // Error Message Card
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Submit Button
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Kirim Laporan',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}