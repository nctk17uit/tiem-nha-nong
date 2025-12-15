import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/controllers/address_controller.dart';
import 'package:mobile/controllers/location_controller.dart';
import 'package:mobile/models/location.dart';
import 'package:mobile/models/shipping_address.dart';
import 'package:mobile/ui/widgets/searchable_selection_sheet.dart';

class AddEditAddressPage extends ConsumerStatefulWidget {
  final ShippingAddress? address;

  const AddEditAddressPage({super.key, this.address});

  @override
  ConsumerState<AddEditAddressPage> createState() => _AddEditAddressPageState();
}

class _AddEditAddressPageState extends ConsumerState<AddEditAddressPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _streetCtrl;

  // Display Controllers for Location
  final _provinceDisplayCtrl = TextEditingController(); // NEW
  final _wardDisplayCtrl = TextEditingController();

  // State
  Province? _selectedProvince;
  Ward? _selectedWard;
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final addr = widget.address;

    _nameCtrl = TextEditingController(text: addr?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: addr?.phoneNumber ?? '');
    _streetCtrl = TextEditingController(text: addr?.streetAddress ?? '');
    _isDefault = addr?.isDefault ?? false;

    // Pre-fill Display Text if Editing
    if (addr != null) {
      if (addr.provinceName != null)
        _provinceDisplayCtrl.text = addr.provinceName!;
      if (addr.wardName != null) _wardDisplayCtrl.text = addr.wardName!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    _provinceDisplayCtrl.dispose(); // Don't forget to dispose
    _wardDisplayCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProvince == null || _selectedWard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn Tỉnh/Thành và Phường/Xã')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newAddress = ShippingAddress(
        id: widget.address?.id ?? '',
        fullName: _nameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        streetAddress: _streetCtrl.text.trim(),
        provinceCode: _selectedProvince!.code,
        wardCode: _selectedWard!.code,
        isDefault: _isDefault,
      );

      final controller = ref.read(addressControllerProvider.notifier);

      if (widget.address == null) {
        await controller.addAddress(newAddress);
      } else {
        await controller.updateAddress(newAddress.id, newAddress);
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provincesAsync = ref.watch(provincesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.address == null ? 'Thêm địa chỉ mới' : 'Sửa địa chỉ',
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- SECTION 1: CONTACT ---
              _buildSectionHeader(context, 'Thông tin liên hệ'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _nameCtrl,
                label: 'Họ và tên',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _phoneCtrl,
                label: 'Số điện thoại',
                icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 24),

              // --- SECTION 2: LOCATION ---
              _buildSectionHeader(context, 'Địa chỉ nhận hàng'),
              const SizedBox(height: 12),

              // 1. Province Selection (Searchable)
              provincesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (err, _) => Text('Lỗi tải danh sách tỉnh: $err'),
                data: (provinces) {
                  // Logic to sync object with ID if editing (runs once when data loads)
                  if (_selectedProvince == null && widget.address != null) {
                    try {
                      _selectedProvince = provinces.firstWhere(
                        (p) => p.code == widget.address!.provinceCode,
                      );
                      // Sync text if empty
                      if (_provinceDisplayCtrl.text.isEmpty) {
                        _provinceDisplayCtrl.text = _selectedProvince!.name;
                      }
                    } catch (_) {}
                  }

                  // CHANGED: Use TextFormField + Search Sheet
                  return TextFormField(
                    controller: _provinceDisplayCtrl,
                    readOnly: true,
                    decoration: _inputDecoration(
                      context,
                      'Tỉnh/Thành phố',
                      Icons.map_outlined,
                    ).copyWith(suffixIcon: const Icon(Icons.arrow_drop_down)),
                    validator: (value) => _selectedProvince == null
                        ? 'Vui lòng chọn Tỉnh/Thành'
                        : null,
                    onTap: () async {
                      final Province? result = await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (context) =>
                            SearchableSelectionSheet<Province>(
                              items: provinces,
                              title: 'Chọn Tỉnh/Thành phố',
                              itemLabel: (p) => p.name,
                            ),
                      );

                      if (result != null) {
                        setState(() {
                          _selectedProvince = result;
                          _provinceDisplayCtrl.text = result.name;

                          // Reset Cascading Fields
                          _selectedWard = null;
                          _wardDisplayCtrl.clear();
                        });
                      }
                    },
                  );
                },
              ),

              const SizedBox(height: 12),

              // 2. Ward Selection (Searchable)
              if (_selectedProvince == null)
                TextFormField(
                  enabled: false,
                  decoration: _inputDecoration(
                    context,
                    'Phường/Xã',
                    Icons.location_city,
                  ).copyWith(labelText: 'Vui lòng chọn Tỉnh trước'),
                )
              else
                Consumer(
                  builder: (context, ref, _) {
                    final wardsAsync = ref.watch(
                      wardsProvider(_selectedProvince!.code),
                    );

                    return wardsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => const Text('Lỗi tải danh sách phường'),
                      data: (wards) {
                        // Sync logic for Edit Mode
                        if (_selectedWard == null && widget.address != null) {
                          try {
                            _selectedWard = wards.firstWhere(
                              (w) => w.code == widget.address!.wardCode,
                            );
                            if (_wardDisplayCtrl.text.isEmpty) {
                              _wardDisplayCtrl.text = _selectedWard!.name;
                            }
                          } catch (_) {}
                        }

                        return TextFormField(
                          controller: _wardDisplayCtrl,
                          readOnly: true,
                          decoration:
                              _inputDecoration(
                                context,
                                'Phường/Xã',
                                Icons.location_city,
                              ).copyWith(
                                suffixIcon: const Icon(Icons.arrow_drop_down),
                              ),
                          validator: (value) => _selectedWard == null
                              ? 'Vui lòng chọn Phường/Xã'
                              : null,
                          onTap: () async {
                            final Ward? result = await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              builder: (context) =>
                                  SearchableSelectionSheet<Ward>(
                                    items: wards,
                                    title: 'Chọn Phường/Xã',
                                    itemLabel: (w) => w.name,
                                  ),
                            );

                            if (result != null) {
                              setState(() {
                                _selectedWard = result;
                                _wardDisplayCtrl.text = result.name;
                              });
                            }
                          },
                        );
                      },
                    );
                  },
                ),

              const SizedBox(height: 12),

              // 3. Street Address
              _buildTextField(
                controller: _streetCtrl,
                label: 'Tên đường, tòa nhà, số nhà',
                icon: Icons.home_outlined,
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // --- SECTION 3: SETTINGS ---
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text('Đặt làm địa chỉ mặc định'),
                  value: _isDefault,
                  activeColor: colorScheme.primary,
                  onChanged: (val) => setState(() => _isDefault = val),
                ),
              ),

              const SizedBox(height: 32),

              // --- SAVE BUTTON ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: _isLoading ? null : _onSave,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Lưu địa chỉ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: _inputDecoration(context, label, icon),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Vui lòng nhập $label';
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context,
    String label,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      filled: true,
      fillColor: colorScheme.surface,
    );
  }
}
