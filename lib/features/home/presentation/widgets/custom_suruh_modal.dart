import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';

/// Modal dialog for "Suruh Apa Saja" - enabling users to request any on-demand task.
class CustomSuruhModal extends StatefulWidget {
  const CustomSuruhModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => const CustomSuruhModal(),
    );
  }

  @override
  State<CustomSuruhModal> createState() => _CustomSuruhModalState();
}

class _CustomSuruhModalState extends State<CustomSuruhModal> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  String _selectedServiceType = 'Suruh Bebas';

  static const List<String> _serviceTypes = <String>[
    'Suruh Bebas',
    'Suruh Antar',
    'Suruh Belanja',
    'Suruh Antri',
    'Suruh Bersih',
    'Suruh Tukang',
  ];

  @override
  void dispose() {
    _taskController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _submit() {
    final String task = _taskController.text.trim();
    if (task.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan jelaskan apa yang ingin Anda suruh.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: <Widget>[
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Permintaan SURUH berhasil dikirim! Mitra terdekat sedang dihubungi.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MediaQueryData media = MediaQuery.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        media.viewInsets.bottom + AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Grabber handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Header
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Text('✨', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Suruh Apa Saja',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Ada urusan? Tulis tugasmu, serahkan pada SURUH!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Service Type Chips
            Text(
              'Jenis Urusan',
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: _serviceTypes.map((String type) {
                final bool isSelected = _selectedServiceType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    if (selected) setState(() => _selectedServiceType = type);
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),

            // Task instruction
            Text(
              'Instruksi Pekerjaan *',
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _taskController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Cth: Tolong belikan vitamin di Apotek Kimia Farma Jl. Gajah Mada dan antar ke kos saya...',
                hintStyle: TextStyle(fontSize: 13, color: theme.hintColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                contentPadding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Pick-up location
            Text(
              'Lokasi Asal / Toko / Loket',
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _pickupController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.storefront_rounded, size: 20),
                hintText: 'Cth: Pasar Flamboyan / Apotek Kimia Farma Gajah Mada',
                hintStyle: TextStyle(fontSize: 13, color: theme.hintColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Destination location
            Text(
              'Lokasi Tujuan / Antar',
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _dropoffController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.location_on_rounded, size: 20, color: AppColors.primary),
                hintText: 'Cth: Jl. Tanjungpura No. 88 (Pontianak Kota)',
                hintStyle: TextStyle(fontSize: 13, color: theme.hintColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Budget
            Text(
              'Estimasi Anggaran Barang / Belanja (Opsional)',
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                prefixText: 'Rp ',
                hintText: 'Contoh: 50.000',
                hintStyle: TextStyle(fontSize: 13, color: theme.hintColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Action Button
            AppButton(
              label: 'Kirim Permintaan Suruh 🚀',
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
