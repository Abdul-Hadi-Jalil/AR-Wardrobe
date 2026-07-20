import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/consent_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';

/// Terms & photo consent — open from Profile/Settings or before try-on.
class TermsConsentScreen extends StatefulWidget {
  const TermsConsentScreen({
    super.key,
    this.onAccepted,
    this.requireAcceptance = false,
  });

  /// Called after the user saves consent (optional).
  final VoidCallback? onAccepted;

  /// When true, user must agree before popping with success (try-on gate).
  final bool requireAcceptance;

  @override
  State<TermsConsentScreen> createState() => _TermsConsentScreenState();
}

class _TermsConsentScreenState extends State<TermsConsentScreen> {
  bool _agreed = false;
  bool _saving = false;
  bool _hasAccepted = false;

  @override
  void initState() {
    super.initState();
    _loadConsent();
  }

  Future<void> _loadConsent() async {
    final accepted = await ConsentService.hasAccepted();
    if (mounted) {
      setState(() {
        _hasAccepted = accepted;
        _agreed = accepted;
      });
    }
  }

  Future<void> _saveConsent() async {
    if (!_agreed || _saving) return;
    setState(() => _saving = true);
    await ConsentService.accept();
    if (!mounted) return;
    setState(() {
      _saving = false;
      _hasAccepted = true;
    });
    widget.onAccepted?.call();
    if (widget.requireAcceptance) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo consent saved')),
      );
    }
  }

  Future<void> _revokeConsent() async {
    await ConsentService.revoke();
    if (!mounted) return;
    setState(() {
      _hasAccepted = false;
      _agreed = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo consent revoked')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Terms & Privacy'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 8.h),
              if (_hasAccepted)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 20.sp),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          'You have accepted photo terms',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 16.h),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppShadows.soft,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      termsBody,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13.5.sp,
                        height: 1.55,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              InkWell(
                onTap: () => setState(() => _agreed = !_agreed),
                borderRadius: BorderRadius.circular(12.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreed,
                        onChanged: (v) => setState(() => _agreed = v ?? false),
                        activeColor: AppColors.primary,
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 12.h),
                          child: Text(
                            'I agree to the Terms & Conditions and consent to AR Wardrobe '
                            'capturing, processing, and storing my photos as described above.',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GradientButton(
                onPressed: _agreed && !_saving ? _saveConsent : null,
                label: _saving ? 'Saving…' : 'Save consent',
              ),
              if (_hasAccepted) ...[
                SizedBox(height: 10.h),
                TextButton(
                  onPressed: _revokeConsent,
                  child: Text(
                    'Revoke consent',
                    style: TextStyle(color: AppColors.danger, fontSize: 14.sp),
                  ),
                ),
              ],
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}

const termsBody = '''
AR Wardrobe — Terms & Conditions (Photo Use)

By using AR Wardrobe you agree to the following:

1. Photo capture
When you use live AR try-on or AI virtual try-on, the app accesses your device camera or photo library to capture images of you.

2. How we use your photos
Your photos may be:
• Processed on your device for real-time AR overlays (Google ML Kit)
• Sent to third-party AI services (e.g. Google Gemini, FASHN.ai) when you choose AI virtual try-on
• Stored locally on your device as try-on results you save
• Stored in your account (Firebase) when you save outfits or orders linked to try-on images

3. Purpose
Photos are used solely to provide virtual try-on, outfit preview, and related shopping features.

4. Retention
Saved try-on images remain until you delete them or remove your account.

5. Your responsibilities
• You must have permission to use any photo you upload
• You must be at least 13 years old (or the minimum age required in your region)
• Do not upload images of other people without their consent

6. Withdrawal of consent
You may stop using photo features at any time or revoke consent in Profile → Terms & Privacy.

7. No guarantee
Virtual try-on is an approximation. Colors, fit, and appearance may differ from real garments.

8. Updates
We may update these terms. Continued use after updates constitutes acceptance of the revised terms.

Contact: support@arwardrobe.app (placeholder)
''';

/// Prompts for consent before camera / AI try-on if not yet accepted.
Future<bool> ensurePhotoConsent(BuildContext context) async {
  if (await ConsentService.hasAccepted()) return true;
  if (!context.mounted) return false;

  final accepted = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => const TermsConsentScreen(requireAcceptance: true),
    ),
  );

  return accepted == true || await ConsentService.hasAccepted();
}
