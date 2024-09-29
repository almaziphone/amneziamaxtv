import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final isAndroidTvProvider = FutureProvider<bool>((ref) async {
  if (Platform.isAndroid) {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.systemFeatures.contains('android.software.leanback');
  }
  return false;
});