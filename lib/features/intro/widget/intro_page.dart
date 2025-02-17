import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/connection/vpn_connection_manager.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:webview_flutter/webview_flutter.dart';

class IntroPage extends HookConsumerWidget {
  IntroPage({super.key});

  final String _uuid = Uuid().v4();

  String generate10DigitCode() {
    final rand = Random();
    return List.generate(10, (_) => rand.nextInt(10)).join();
  }

  String format10DigitCode(String code) {
    if (code.length != 10) {
      return code; // Возвращаем исходный код, если он не 10-значный
    }
    return '${code[0]} ${code.substring(1, 4)} ${code.substring(4, 7)} ${code.substring(7)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    final isStarting = useState(false);
    final vpnConfigs = useState<List<dynamic>>([]);
    final userInfo = useState<String?>(null);
    final connectionManagerUuid = useState<VpnConnectionManager?>(null);
    final connectionManagerCode = useState<VpnConnectionManager?>(null);
    final isVpnAdded = useState(false);
    final code10Digit = useState<String>(generate10DigitCode());
    final combinedStatus = useState<String>(t.intro.waitingForQrScan);

    void updateCombinedStatus() {
      String uuidStatus = connectionManagerUuid.value == null
          ? t.intro.waitingForQrScan
          : isVpnAdded.value
              ? t.intro.vpnSetupComplete
              : userInfo.value != null
                  ? t.intro.userInfoReceived
                  : t.intro.waitingForQrScan;

      String codeStatus = connectionManagerCode.value == null
          ? t.intro.waitingForCodeInput
          : isVpnAdded.value
              ? t.intro.vpnSetupComplete
              : userInfo.value != null
                  ? t.intro.userInfoReceived
                  : t.intro.waitingForCodeInput;
      if (codeStatus != uuidStatus) {
        combinedStatus.value = '$uuidStatus\n$codeStatus';
      } else {
        combinedStatus.value = uuidStatus;
      }
    }

    Future<void> processConfigs(List<dynamic> configs) async {
      for (final config in configs) {
        if (config is Map<String, dynamic> && config['type'] == 'subscription') {
          await ref.read(addProfileProvider.notifier).add(config['url'] as String);
        } else if (config is String) {
          await ref.read(addProfileProvider.notifier).add(config);
        } else {
          print('Неподдерживаемый формат конфигурации: $config');
        }
      }
      isVpnAdded.value = true;
      updateCombinedStatus();
    }

    useEffect(() {
      Future<void> initializeSettings() async {
        await ref.read(ConfigOptions.region.notifier).update(Region.ru);
      }

      initializeSettings();
      return null;
    }, []);

    useEffect(() {
      connectionManagerUuid.value = VpnConnectionManager(
        // uuid: _uuid,
        uuid: code10Digit.value,
        onMessage: (dynamic message) async {
          // if (message['type'] == 'user_info') {
          //   userInfo.value = t.intro.userInfo(
          //     firstName: message['data']['first_name'],
          //     lastName: message['data']['last_name'],
          //   );
          //   updateCombinedStatus();
          // } else 
          if (message['type'] == 'vpn_config_processed') {
            final configs = message['config'] as List<dynamic>;
            vpnConfigs.value = configs;
            updateCombinedStatus();
            await processConfigs(configs);
          }
        },
        onError: (error) {
          print('Connection error UUID: $error');
          combinedStatus.value = '${t.intro.connectionError}\n${combinedStatus.value.split('\n').last}';
        },
      );

      connectionManagerUuid.value!.connect();

      return () {
        connectionManagerUuid.value?.disconnect();
      };
    }, []);

    useEffect(() {
      connectionManagerCode.value = VpnConnectionManager(
        uuid: code10Digit.value,
        onMessage: (dynamic message) async {
          // if (message['type'] == 'user_info') {
          //   userInfo.value = t.intro.userInfo(
          //     firstName: message['data']['first_name'],
          //     lastName: message['data']['last_name'],
          //   );
          //   updateCombinedStatus();
          // } else
          if (message['type'] == 'vpn_config_processed') {
            final configs = message['config'] as List<dynamic>;
            vpnConfigs.value = configs;
            updateCombinedStatus();
            await processConfigs(configs);
          }
        },
        onError: (error) {
          print('Connection error Code: $error');
          combinedStatus.value = '${combinedStatus.value.split('\n').first}\n${t.intro.connectionError}';
        },
      );

      connectionManagerCode.value!.connect();

      return () {
        connectionManagerCode.value?.disconnect();
      };
    }, [code10Digit.value]);

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

    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.general.appTitle),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              if (value == 'terms') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WebViewPage(
                      url: Constants.termsAndConditionsUrl,
                      title: t.general.termsAndConditions,
                    ),
                  ),
                );
              } else if (value == 'privacy') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WebViewPage(
                      url: Constants.privacyPolicyUrl,
                      title: t.general.privacyPolicy,
                    ),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'terms',
                child: Text(t.general.termsAndConditions),
              ),
              PopupMenuItem<String>(
                value: 'privacy',
                child: Text(t.general.privacyPolicy),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: SafeArea(
        child: FocusTraversalGroup(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Center(
                    child: QrImageView(
                      // data: 'https://t.me/amneziamaxbot?start=$_uuid',
                      data: 'https://t.me/amneziarusbot?start=tv_${code10Digit.value}',
                      version: QrVersions.auto,
                      size: 200.0,
                      foregroundColor: isDarkTheme ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      '10-значный код: ${format10DigitCode(code10Digit.value)}',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      t.intro.continueWithBot,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      combinedStatus.value,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (userInfo.value != null) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        userInfo.value!,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: Column(
                      children: [
                        if (isVpnAdded.value && !isStarting.value)
                          ElevatedButton(
                            onPressed: () {
                              isStarting.value = true;
                              ref.read(Preferences.introCompleted.notifier).update(true);
                            },
                            child: Text(
                              t.intro.start,
                              textAlign: TextAlign.center,
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(double.infinity, 48),
                            ),
                          ),
                        if (isVpnAdded.value && !isStarting.value) const SizedBox(height: 16),
                        if (!isStarting.value)
                          TextButton(
                            onPressed: () {
                              isStarting.value = true;
                              ref.read(Preferences.introCompleted.notifier).update(true);
                            },
                            child: Text(
                              t.intro.addProfileLater,
                              textAlign: TextAlign.center,
                            ),
                            style: TextButton.styleFrom(
                              minimumSize: Size(double.infinity, 48),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WebViewPage extends HookWidget {
  final String url;
  final String title;

  const WebViewPage({Key? key, required this.url, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = useState<WebViewController?>(null);

    useEffect(() {
      controller.value = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              // Здесь вы можете обновить индикатор загрузки, если хотите
            },
            onPageStarted: (String url) {},
            onPageFinished: (String url) {},
            onWebResourceError: (WebResourceError error) {
              // Обработка ошибок
              print('WebView error: ${error.description}');
            },
            onNavigationRequest: (NavigationRequest request) {
              // Здесь вы можете добавить логику для обработки навигации
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(url));

      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: controller.value != null ? WebViewWidget(controller: controller.value!) : const Center(child: CircularProgressIndicator()),
    );
  }
}
