import 'dart:io'; // Cho File
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // Cho XFile
import 'package:cloud_firestore/cloud_firestore.dart'; // Cho GeoPoint

import '../../models/field_model.dart';
import '../../providers/field_providers.dart';
import '../../providers/core_providers.dart'; // Cho imageServiceProvider
import '../../core/utils/validators.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_indicator.dart';
// import '../../widgets/common/image_picker_input.dart'; // Bạn có thể tạo widget này để tái sử dụng

class FieldEditFormScreen extends ConsumerStatefulWidget {
  final FieldModel? field; // Nếu null -> tạo mới, nếu có -> sửa

  const FieldEditFormScreen({super.key, this.field});

  @override
  ConsumerState<FieldEditFormScreen> createState() => _FieldEditFormScreenState();
}

class _FieldEditFormScreenState extends ConsumerState<FieldEditFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers cho các trường text
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _openingHoursController;
  late TextEditingController _sizeController;
  late TextEditingController _latitudeController; // Cho GeoPoint
  late TextEditingController _longitudeController; // Cho GeoPoint

  SportType _selectedSportType = SportType.unknown; // Giá trị mặc định
  bool _isActive = true;
  List<String> _selectedAmenities = []; // Nếu amenities là List<String> trong model
  List<XFile> _newImageXFiles = []; // Ảnh mới người dùng chọn
  List<String> _existingImageUrls = []; // URL ảnh cũ (nếu đang sửa)
  List<String> _imageUrlsToDeleteOnSave = []; // URL ảnh cũ bị đánh dấu xóa

  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEditing => widget.field != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.field?.name);
    _addressController = TextEditingController(text: widget.field?.address);
    _descriptionController = TextEditingController(text: widget.field?.description);
    _priceController = TextEditingController(text: widget.field?.pricePerHour.toString());
    _openingHoursController = TextEditingController(text: widget.field?.openingHoursDescription);
    _sizeController = TextEditingController(text: widget.field?.sizeDescription);
    _latitudeController = TextEditingController(text: widget.field?.location?.latitude.toString());
    _longitudeController = TextEditingController(text: widget.field?.location?.longitude.toString());

    if (_isEditing) {
      _selectedSportType = widget.field!.sportType;
      _isActive = widget.field!.isActive;
      _selectedAmenities = List<String>.from(widget.field!.amenities ?? []);
      _existingImageUrls = List<String>.from(widget.field!.imageUrls);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _openingHoursController.dispose();
    _sizeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final imageService = ref.read(imageServiceProvider);
    final List<XFile> pickedXFiles = await imageService.pickMultiXFiles(imageQuality: 70);
    if (pickedXFiles.isNotEmpty) {
      // Giới hạn số lượng ảnh (ví dụ 5-10 ảnh)
      if ((_existingImageUrls.length - _imageUrlsToDeleteOnSave.length + _newImageXFiles.length + pickedXFiles.length) > 10) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn chỉ có thể có tối đa 10 ảnh cho sân.')));
        return;
      }
      setState(() {
        _newImageXFiles.addAll(pickedXFiles);
      });
    }
  }

  void _removeNewImage(XFile xFile) {
    setState(() {
      _newImageXFiles.remove(xFile);
    });
  }
  void _markExistingImageForDeletion(String url) {
    setState(() {
      if (_imageUrlsToDeleteOnSave.contains(url)) {
        _imageUrlsToDeleteOnSave.remove(url); // Hoàn tác xóa
      } else {
        _imageUrlsToDeleteOnSave.add(url);
      }
    });
  }


  Future<void> _saveField() async {
    FocusScope.of(context).unfocus();
    if (_selectedSportType == SportType.unknown) {
      setState(() => _errorMessage = "Vui lòng chọn loại hình thể thao.");
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final price = double.tryParse(_priceController.text.trim());
      if (price == null) {
        setState(() { _errorMessage = "Giá không hợp lệ."; _isLoading = false; });
        return;
      }

      GeoPoint? location;
      final lat = double.tryParse(_latitudeController.text.trim());
      final lon = double.tryParse(_longitudeController.text.trim());
      if (lat != null && lon != null) {
        if (lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
          location = GeoPoint(lat, lon);
        } else {
          setState(() { _errorMessage = "Tọa độ (vĩ độ/kinh độ) không hợp lệ."; _isLoading = false; });
          return;
        }
      }


      try {
        final fieldService = ref.read(fieldServiceProvider);
        if (_isEditing) {
          // Logic lấy các URL ảnh cũ cần giữ lại
          List<String> urlsToKeep = _existingImageUrls
              .where((url) => !_imageUrlsToDeleteOnSave.contains(url))
              .toList();

          await fieldService.updateField(
            fieldId: widget.field!.id,
            name: _nameController.text.trim(),
            sportType: _selectedSportType,
            address: _addressController.text.trim(),
            location: location,
            description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
            pricePerHour: price,
            openingHoursDescription: _openingHoursController.text.trim(),
            amenities: _selectedAmenities.isEmpty ? null : _selectedAmenities,
            sizeDescription: _sizeController.text.trim().isEmpty ? null : _sizeController.text.trim(),
            isActive: _isActive,
            newImageXFiles: _newImageXFiles,
            existingImageUrlsToKeep: urlsToKeep, // Truyền các URL cần giữ
          );
        } else {
          await fieldService.createField(
            name: _nameController.text.trim(),
            sportType: _selectedSportType,
            address: _addressController.text.trim(),
            location: location,
            description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
            pricePerHour: price,
            openingHoursDescription: _openingHoursController.text.trim(),
            amenities: _selectedAmenities.isEmpty ? null : _selectedAmenities,
            sizeDescription: _sizeController.text.trim().isEmpty ? null : _sizeController.text.trim(),
            imageXFiles: _newImageXFiles,
            // isActive được set mặc định trong createField
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEditing ? 'Cập nhật sân thành công!' : 'Tạo sân thành công!')),
          );
          Navigator.of(context).pop(); // Quay lại màn hình quản lý
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = e.toString().replaceFirst("Exception: ", "");
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa thông tin sân' : 'Thêm sân mới'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _isLoading ? null : _saveField,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Tên sân *'), validator: Validators.validateNotEmpty),
              const SizedBox(height: 12),
              DropdownButtonFormField<SportType>(
                value: _selectedSportType == SportType.unknown && !_isEditing ? null : _selectedSportType, // Để placeholder hiển thị khi tạo mới
                hint: const Text('Chọn loại hình thể thao *'),
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: SportType.values
                    .where((type) => type != SportType.unknown) // Không cho chọn "unknown"
                    .map((SportType type) {
                  return DropdownMenuItem<SportType>(
                    value: type,
                    child: Text(sportTypeToString(type)), // Cần hàm sportTypeToString
                  );
                }).toList(),
                onChanged: (SportType? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedSportType = newValue;
                    });
                  }
                },
                validator: (value) => value == null || value == SportType.unknown ? 'Vui lòng chọn loại hình thể thao' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Địa chỉ *'), validator: Validators.validateNotEmpty, maxLines: 2),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _latitudeController, decoration: const InputDecoration(labelText: 'Vĩ độ (Latitude)'), keyboardType: TextInputType.numberWithOptions(decimal: true))),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _longitudeController, decoration: const InputDecoration(labelText: 'Kinh độ (Longitude)'), keyboardType: TextInputType.numberWithOptions(decimal: true))),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Mô tả sân'), maxLines: 3),
              const SizedBox(height: 12),
              TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Giá mỗi giờ (VNĐ) *'), keyboardType: TextInputType.number, validator: (val) => Validators.validateNotEmpty(val, "Vui lòng nhập giá.")),
              const SizedBox(height: 12),
              TextFormField(controller: _openingHoursController, decoration: const InputDecoration(labelText: 'Mô tả giờ mở cửa *'), validator: Validators.validateNotEmpty, maxLines: 2),
              const SizedBox(height: 12),
              TextFormField(controller: _sizeController, decoration: const InputDecoration(labelText: 'Mô tả kích thước sân')),
              const SizedBox(height: 16),

              // TODO: Phần chọn Tiện ích (Amenities)
              // Nếu danh sách amenities là động từ Firestore: dùng MultiSelectDialogField hoặc CheckboxListTiles
              // Nếu là nhập tay: có thể dùng một TextFormField cho phép nhập các tiện ích cách nhau bởi dấu phẩy
              Text('Tiện ích (nhập cách nhau bởi dấu phẩy):', style: Theme.of(context).textTheme.labelLarge),
              TextFormField(
                initialValue: _selectedAmenities.join(', '),
                decoration: const InputDecoration(hintText: 'Ví dụ: Wifi, Nước uống, Mái che'),
                onChanged: (value) {
                  setState(() {
                    _selectedAmenities = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                  });
                },
              ),
              const SizedBox(height: 16),


              Text('Hình ảnh sân (tối đa 10 ảnh):', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              _buildImageManagementSection(),
              const SizedBox(height: 16),


              if (_isEditing) // Chỉ hiển thị khi sửa
                Row(
                  children: [
                    const Text('Trạng thái hoạt động: '),
                    Switch(
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                    ),
                    Text(_isActive ? 'Đang hoạt động' : 'Không hoạt động'),
                  ],
                ),
              const SizedBox(height: 24),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center),
                ),

              _isLoading
                  ? const Center(child: LoadingIndicator())
                  : CustomButton(
                onPressed: _saveField,
                text: _isEditing ? 'Lưu thay đổi' : 'Thêm sân mới',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hiển thị ảnh mới chọn
        if (_newImageXFiles.isNotEmpty) ...[
          const Text('Ảnh mới:', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8.0, runSpacing: 8.0,
            children: _newImageXFiles.map((xfile) => Stack(
              children: [
                Image.file(File(xfile.path), width: 80, height: 80, fit: BoxFit.cover),
                Positioned(top: -4, right: -4, child: InkWell(onTap: () => _removeNewImage(xfile), child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.red.withAlpha(200), shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16)))),
              ],
            )).toList(),
          ),
          const SizedBox(height: 10),
        ],

        // Hiển thị ảnh đã có (nếu đang sửa)
        if (_isEditing && _existingImageUrls.isNotEmpty) ...[
          const Text('Ảnh hiện tại:', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8.0, runSpacing: 8.0,
            children: _existingImageUrls.map((url) {
              final isMarkedForDeletion = _imageUrlsToDeleteOnSave.contains(url);
              return Opacity(
                opacity: isMarkedForDeletion ? 0.5 : 1.0,
                child: Stack(
                  children: [
                    Image.network(url, width: 80, height: 80, fit: BoxFit.cover),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _markExistingImageForDeletion(url),
                          child: Center(
                            child: isMarkedForDeletion
                                ? const Icon(Icons.undo, color: Colors.white, shadows: [Shadow(blurRadius: 2, color: Colors.black)])
                                : const Icon(Icons.delete_outline, color: Colors.red, shadows: [Shadow(blurRadius: 2, color: Colors.white)]),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
        ],

        // Nút chọn thêm ảnh
        OutlinedButton.icon(
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('Chọn/Thêm ảnh'),
          onPressed: _pickImages,
        ),
      ],
    );
  }
}