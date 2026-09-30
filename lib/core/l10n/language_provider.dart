import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyimpeun/core/l10n/app_language.dart';

/// Provider global untuk menyimpan bahasa yang sedang aktif.
/// Default: Bahasa Indonesia
final languageProvider = StateProvider<AppLanguage>((ref) => AppLanguage.id);
