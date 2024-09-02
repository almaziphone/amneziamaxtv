import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';

class AddConfigPage extends HookConsumerWidget {
  AddConfigPage({Key? key}) : super(key: key);

  final String _uuid = const Uuid().v4();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = useState<String>('Ожидание подключения...');
    final vpnConfigs = useState<List<String>>([]);

    useEffect(() {
      bool isActive = true;
      Timer? pollTimer;

      Future<void> pollServer() async {
        if (!isActive) return;

        try {
          final response = await http.get(Uri.parse('https://api.vpn4tv.com/poll?uuid=$_uuid'));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            print('Received data: $data'); // Добавлено логирование

            if (data['type'] == 'user_info') {
              connectionStatus.value = 'Получена информация о пользователе: ${data['data']}';
            } else if (data['type'] == 'vpn_config_processed') {
              vpnConfigs.value = List<String>.from(data['config']);
              connectionStatus.value = 'Конфигурации VPN получены: ${vpnConfigs.value.length}';

              // Добавляем полученные конфигурации
              for (var config in vpnConfigs.value) {
                print('Adding config: $config'); // Добавлено логирование
                await ref.read(addProfileProvider.notifier).add(config);
              }

              // Возвращаемся на предыдущий экран после добавления конфигураций
              if (isActive) {
                Navigator.of(context).pop();
              }
            } else if (data['type'] == 'timeout') {
              print('Received timeout, continuing polling'); // Добавлено логирование
              pollTimer = Timer(const Duration(seconds: 1), pollServer);
            } else {
              print('Received unknown message type: ${data['type']}'); // Добавлено логирование
              connectionStatus.value = 'Получено неизвестное сообщение: ${data['type']}';
            }
          } else {
            print('Received error status code: ${response.statusCode}'); // Добавлено логирование
            connectionStatus.value = 'Ошибка соединения: ${response.statusCode}';
          }
        } catch (e) {
          print('Error during polling: $e'); // Добавлено логирование
          connectionStatus.value = 'Ошибка соединения: $e';
        }

        if (isActive && pollTimer == null) {
          pollTimer = Timer(const Duration(seconds: 1), pollServer);
        }
      }

      // Начинаем опрос сервера
      pollServer();

      return () {
        isActive = false;
        pollTimer?.cancel();
      };
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Новый профиль"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(
              data: 'https://t.me/VPN4TV_Bot?start=$_uuid',
              version: QrVersions.auto,
              size: 200.0,
            ),
            const SizedBox(height: 20),
            const Text("Отсканируйте QR-код в Telegram"),
            const SizedBox(height: 20),
            const Text("Продолжите настройку в Telegram боте"),
            const SizedBox(height: 20),
            Text(connectionStatus.value),
          ],
        ),
      ),
    );
  }
}
