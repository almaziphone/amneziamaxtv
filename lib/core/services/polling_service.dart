// lib/core/services/polling_service.dart
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PollingService {
  final String baseUrl;
  final Duration initialInterval;
  final Duration maxInterval;
  final int maxRetries;

  PollingService({
    required this.baseUrl,
    this.initialInterval = const Duration(seconds: 1),
    this.maxInterval = const Duration(seconds: 30),
    this.maxRetries = 5,
  });

  Future<void> startPolling({
    required String uuid,
    required Function(dynamic) onDataReceived,
    required Function(String) onError,
  }) async {
    Duration currentInterval = initialInterval;
    int retries = 0;

    while (true) {
      try {
        final uri = Uri.parse('$baseUrl/poll').replace(queryParameters: {'uuid': uuid});
        final response = await http.get(
          uri,
          headers: {'Connection': 'keep-alive'},
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            print('Request timed out. Restarting immediately...');
            throw TimeoutException('Request timed out');
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['type'] != 'timeout') {
            onDataReceived(data);
            currentInterval = initialInterval;
            retries = 0;
          }
        } else if (response.statusCode == 204) {
          currentInterval = Duration(milliseconds: (currentInterval.inMilliseconds * 1.5).toInt());
          if (currentInterval > maxInterval) {
            currentInterval = maxInterval;
          }
        } else {
          throw Exception('HTTP error ${response.statusCode}');
        }
      } catch (e) {
        if (e is TimeoutException) {
          print('Timeout occurred. Restarting polling immediately.');
          continue; // Немедленный перезапуск при таймауте
        }

        onError(e.toString());
        retries++;
        if (retries >= maxRetries) {
          print('Max retries reached. Restarting polling process.');
          retries = 0; // Сбрасываем счетчик попыток
          currentInterval = initialInterval; // Сбрасываем интервал
          continue; // Перезапускаем процесс с начальными параметрами
        }
        currentInterval = Duration(milliseconds: (currentInterval.inMilliseconds * 2).toInt());
        if (currentInterval > maxInterval) {
          currentInterval = maxInterval;
        }
      }

      await Future.delayed(currentInterval);
    }
  }
}
