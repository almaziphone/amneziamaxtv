import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:hiddify/core/analytics/analytics_controller.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:hiddify/features/connection/vpn_connection_manager.dart';
import 'package:hiddify/features/profile/add/add_profile_modal.dart';
import 'package:hiddify/gen/assets.gen.dart'; // Добавлен импорт для Assets
import 'package:sliver_tools/sliver_tools.dart'; // Добавлен импорт для SliverCrossAxisConstrained и MultiSliver

class IntroPage extends HookConsumerWidget {
  IntroPage({super.key});

  final String _uuid = Uuid().v4();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    final isStarting = useState(false);
    final vpnConfigs = useState<List<String>>([]);
    final userInfo = useState<String?>(null);
    final connectionManager = useState<VpnConnectionManager?>(null);
    final status = useState<String>('Ожидание сканирования QR-кода');
    final isVpnAdded = useState(false);

    useEffect(() {
      Future<void> initializeSettings() async {
        await ref.read(ConfigOptions.region.notifier).update(Region.ru);
        await ref.read(localePreferencesProvider.notifier).changeLocale(AppLocale.ru);
      }

      initializeSettings();

      return null;
    }, []);

    useEffect(() {
      connectionManager.value = VpnConnectionManager(
        uuid: _uuid,
        onMessage: (dynamic message) async {
          if (message['type'] == 'user_info') {
            userInfo.value = 'Пользователь: ${message['data']['first_name']} ${message['data']['last_name']}';
            status.value = 'Получена информация о пользователе';
          } else if (message['type'] == 'vpn_config_processed') {
            vpnConfigs.value = List<String>.from(message['config']);
            status.value = 'Конфигурации VPN получены';

            for (final config in vpnConfigs.value) {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AddProfileModal(url: config),
              );
            }

            isVpnAdded.value = true;
            status.value = 'VPN настроен';
          }
        },
        onError: (error) {
          print('Connection error: $error');
          status.value = 'Ошибка соединения';
        },
      );

      connectionManager.value!.connect();

      return () {
        connectionManager.value?.disconnect();
      };
    }, []);

    useEffect(() {
      if (isVpnAdded.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!isStarting.value) {
            isStarting.value = true;
            ref.read(Preferences.introCompleted.notifier).update(true);
          }
        });
      }
    }, [isVpnAdded.value]);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          shrinkWrap: true,
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                width: 224,
                height: 224,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Assets.images.logo.svg(),
                ),
              ),
            ),
            SliverCrossAxisConstrained(
              maxCrossAxisExtent: 368,
              child: MultiSliver(
                children: [
                  SliverToBoxAdapter(
                    child: Center(
                      child: QrImageView(
                        data: 'https://t.me/VPN4TV_Bot?start=$_uuid',
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                    ),
                  ),
                  const SliverGap(20),
                  SliverToBoxAdapter(
                    child: Center(
                      child: Text(status.value),
                    ),
                  ),
                  if (userInfo.value != null) ...[
                    const SliverGap(20),
                    SliverToBoxAdapter(
                      child: Center(
                        child: Text(userInfo.value!),
                      ),
                    ),
                  ],
                  const SliverGap(20),
                  SliverToBoxAdapter(
                    child: Center(
                      child: Text('Пожалуйста, продолжите общение с ботом @VPN4TV_Bot в Telegram для успешной установки VPN.'),
                    ),
                  ),
                  const SliverGap(20),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text.rich(
                        t.intro.termsAndPolicyCaution(
                          tap: (text) => TextSpan(
                            text: text,
                            style: const TextStyle(color: Colors.blue),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                await UriUtils.tryLaunch(
                                  Uri.parse(Constants.termsAndConditionsUrl),
                                );
                              },
                          ),
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      child: FilledButton(
                        onPressed: isVpnAdded.value && !isStarting.value
                            ? () {
                                isStarting.value = true;
                                ref.read(Preferences.introCompleted.notifier).update(true);
                              }
                            : null,
                        child: isStarting.value
                            ? LinearProgressIndicator(
                                backgroundColor: Colors.transparent,
                                color: Theme.of(context).colorScheme.onSurface,
                              )
                            : Text(isVpnAdded.value ? t.intro.start : 'Ожидание настройки VPN'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
