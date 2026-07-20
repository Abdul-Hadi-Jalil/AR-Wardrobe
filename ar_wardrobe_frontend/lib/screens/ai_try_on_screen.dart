import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../models/brand_catalog.dart';
import '../models/clothing_item.dart';
import '../services/fashn_service.dart';
import '../services/nano_banana_service.dart';
import '../services/try_on_result.dart';
import '../screens/terms_consent_screen.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';

/// Which AI engine to use for the try-on.
enum TryOnEngine { auto, gemini, fashn }

class AiTryOnScreen extends StatefulWidget {
  const AiTryOnScreen({super.key, this.initialCloth});

  /// Optionally pre-select a garment (e.g. when launched from a product).
  final ClothingItem? initialCloth;

  @override
  State<AiTryOnScreen> createState() => _AiTryOnScreenState();
}

class _AiTryOnScreenState extends State<AiTryOnScreen> {
  final ImagePicker _picker = ImagePicker();
  final NanoBananaService _service = NanoBananaService();
  final FashnService _fashn = FashnService();

  TryOnEngine _engine = TryOnEngine.auto;

  Uint8List? _personBytes;
  String _personMime = 'image/jpeg';

  Uint8List? _clothBytes;
  String _clothMime = 'image/png';
  String? _clothLabel;

  bool _loading = false;
  Uint8List? _resultBytes;
  String? _resultEngine;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialCloth != null) {
      _loadClothFromAsset(widget.initialCloth!);
    }
  }

  @override
  void dispose() {
    _service.dispose();
    _fashn.dispose();
    super.dispose();
  }

  String _mimeFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _pickPerson(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 90,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _personBytes = bytes;
        _personMime = _mimeFromPath(file.path);
        _resultBytes = null;
        _error = null;
      });
    } catch (e) {
      _showSnack('Could not load photo: $e');
    }
  }

  Future<void> _pickClothFromDevice() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 90,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _clothBytes = bytes;
        _clothMime = _mimeFromPath(file.path);
        _clothLabel = 'Uploaded garment';
        _resultBytes = null;
        _error = null;
      });
    } catch (e) {
      _showSnack('Could not load garment: $e');
    }
  }

  Future<void> _loadClothFromAsset(ClothingItem item) async {
    try {
      final data = await rootBundle.load(item.assetPath);
      setState(() {
        _clothBytes = data.buffer.asUint8List();
        _clothMime = _mimeFromPath(item.assetPath);
        _clothLabel = item.name;
        _resultBytes = null;
        _error = null;
      });
    } catch (e) {
      _showSnack('Could not load garment: $e');
    }
  }

  Future<TryOnResult> _runGemini() => _service.generateTryOn(
        personImage: _personBytes!,
        personMimeType: _personMime,
        clothImage: _clothBytes!,
        clothMimeType: _clothMime,
      );

  Future<TryOnResult> _runFashn() => _fashn.generateTryOn(
        personImage: _personBytes!,
        personMimeType: _personMime,
        clothImage: _clothBytes!,
        clothMimeType: _clothMime,
      );

  Future<void> _generate() async {
    if (_personBytes == null || _clothBytes == null) return;

    final consent = await ensurePhotoConsent(context);
    if (!consent || !mounted) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _resultBytes = null;
      _resultEngine = null;
    });

    TryOnResult result;
    switch (_engine) {
      case TryOnEngine.gemini:
        result = await _runGemini();
        break;
      case TryOnEngine.fashn:
        result = await _runFashn();
        break;
      case TryOnEngine.auto:
        result = await _runGemini();
        if (!result.isSuccess) {
          final geminiError = result.error;
          final fallback = await _runFashn();
          result = fallback.isSuccess
              ? fallback
              : TryOnResult(
                  engine: 'Auto',
                  error: 'Gemini: ${geminiError ?? 'failed'}\n'
                      'FASHN: ${fallback.error ?? 'failed'}',
                );
        }
        break;
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _resultBytes = result.image;
      _resultEngine = result.engine;
      _error = result.isSuccess ? null : (result.error ?? 'Generation failed');
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showPersonSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            SizedBox(height: 8.h),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.primary),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickPerson(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickPerson(ImageSource.gallery);
              },
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  void _showClothSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            SizedBox(height: 8.h),
            ListTile(
              leading: const Icon(Icons.storefront_outlined,
                  color: AppColors.primary),
              title: const Text('Choose from store'),
              onTap: () {
                Navigator.pop(context);
                _openCatalogPicker();
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_outlined,
                  color: AppColors.primary),
              title: const Text('Upload garment photo'),
              onTap: () {
                Navigator.pop(context);
                _pickClothFromDevice();
              },
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  Future<void> _openCatalogPicker() async {
    final selected = await showModalBottomSheet<ClothingItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => const _CatalogPickerSheet(),
    );
    if (selected != null) {
      await _loadClothFromAsset(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canGenerate =
        _personBytes != null && _clothBytes != null && !_loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('AI Virtual Try-On')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Banner(),
              SizedBox(height: 18.h),
              _EngineSelector(
                value: _engine,
                onChanged: _loading
                    ? null
                    : (e) => setState(() => _engine = e),
              ),
              SizedBox(height: 20.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _UploadTile(
                      label: 'Your Photo',
                      icon: Icons.person_outline_rounded,
                      bytes: _personBytes,
                      hint: 'Tap to add',
                      onTap: _showPersonSourceSheet,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: _UploadTile(
                      label: 'Garment',
                      icon: Icons.checkroom_rounded,
                      bytes: _clothBytes,
                      hint: 'Tap to choose',
                      caption: _clothLabel,
                      onTap: _showClothSourceSheet,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              GradientButton(
                label: _loading ? 'Generating...' : 'Generate Try-On',
                icon: Icons.auto_awesome_rounded,
                isLoading: _loading,
                onPressed: canGenerate ? _generate : null,
              ),
              SizedBox(height: 24.h),
              _buildResultArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultArea() {
    if (_loading) {
      return Container(
        height: 320.h,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16.h),
            Text(
              'Dressing you up with AI...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded,
                color: AppColors.danger, size: 36.sp),
            SizedBox(height: 12.h),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.danger, fontSize: 14.sp),
            ),
          ],
        ),
      );
    }

    if (_resultBytes != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.card,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Image.memory(_resultBytes!, fit: BoxFit.contain),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(Icons.verified_rounded,
                  color: AppColors.success, size: 18.sp),
              SizedBox(width: 6.w),
              Text(
                'Generated with ${_resultEngine ?? 'AI'}'
                '${_resultEngine == 'Gemini' ? ' (Nano Banana)' : ''}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome_outlined,
              color: AppColors.textMuted, size: 40.sp),
          SizedBox(height: 12.h),
          Text(
            'Your AI try-on result will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.brandGlow(AppColors.primary),
      ),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 26.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Powered Try-On',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Add your photo and a garment to see it on you.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.5.sp,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EngineSelector extends StatelessWidget {
  const _EngineSelector({required this.value, required this.onChanged});

  final TryOnEngine value;
  final ValueChanged<TryOnEngine>? onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      (TryOnEngine.auto, 'Auto'),
      (TryOnEngine.gemini, 'Gemini'),
      (TryOnEngine.fashn, 'FASHN'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Engine',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              value == TryOnEngine.auto ? '(Gemini, falls back to FASHN)' : '',
              style: TextStyle(
                fontSize: 11.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            children: options.map((opt) {
              final selected = opt.$1 == value;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onChanged == null ? null : () => onChanged!(opt.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(vertical: 9.h),
                    decoration: BoxDecoration(
                      gradient: selected ? AppGradients.brandHorizontal : null,
                      borderRadius: BorderRadius.circular(AppRadius.sm - 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      opt.$2,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color:
                            selected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.label,
    required this.icon,
    required this.bytes,
    required this.hint,
    required this.onTap,
    this.caption,
  });

  final String label;
  final IconData icon;
  final Uint8List? bytes;
  final String hint;
  final String? caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: 0.82,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: bytes == null ? AppColors.border : AppColors.primary,
                  width: bytes == null ? 1 : 1.6,
                ),
                boxShadow: AppShadows.soft,
              ),
              child: bytes == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon,
                              color: AppColors.primary, size: 24.sp),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          hint,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppRadius.md - 1),
                          child: Image.memory(bytes!, fit: BoxFit.cover),
                        ),
                        Positioned(
                          right: 8.w,
                          top: 8.h,
                          child: Container(
                            padding: EdgeInsets.all(5.w),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.edit_rounded,
                                size: 14.sp, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (caption != null) ...[
          SizedBox(height: 6.h),
          Text(
            caption!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5.sp,
            ),
          ),
        ],
      ],
    );
  }
}

/// Bottom sheet that lists store garments grouped from the brand catalog.
class _CatalogPickerSheet extends StatefulWidget {
  const _CatalogPickerSheet();

  @override
  State<_CatalogPickerSheet> createState() => _CatalogPickerSheetState();
}

class _CatalogPickerSheetState extends State<_CatalogPickerSheet> {
  late final Future<List<ClothingItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _loadItems();
  }

  Future<List<ClothingItem>> _loadItems() async {
    final brands = await BrandCatalog.loadBrands();
    return brands.expand((b) => b.products).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: [
            SizedBox(height: 10.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Text(
                    'Choose a garment',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<ClothingItem>>(
                future: _itemsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    );
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return const EmptyState(
                      icon: Icons.checkroom_outlined,
                      title: 'No garments available',
                    );
                  }
                  return GridView.builder(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10.w,
                      mainAxisSpacing: 10.h,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return GestureDetector(
                        onTap: () => Navigator.pop(context, item),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                          ),
                          padding: EdgeInsets.all(8.w),
                          child: SafeAssetImage(assetPath: item.assetPath),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
