import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:smart_travel_app/services/maps/mapbox_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    MapBoxService.instance.clearCache();
  });

  tearDown(() {
    MapBoxService.instance.setHttpClient(null);
  });

  test('calculateDistance falls back to Haversine when API fails', () async {
    MapBoxService.instance.setHttpClient(
      MockClient((request) async {
        return http.Response('error', 500);
      }),
    );

    final result = await MapBoxService.instance.calculateDistance(
      10.776889, // HCMC
      106.700897,
      21.027763, // Ha Noi
      105.83416,
    );

    expect(result, isNotNull);
    expect(result!.distance, closeTo(1130, 150));
    expect(result.duration, greaterThan(0));
  });

  test('getRoute parses geometry and steps', () async {
    const fakeResponse = {
      'routes': [
        {
          'distance': 1657300.0,
          'duration': 86400.0,
          'geometry': {
            'coordinates': [
              [106.7009, 10.7769],
              [105.8342, 21.0278]
            ],
          },
          'legs': [
            {
              'steps': [
                {
                  'distance': 1000.0,
                  'duration': 600.0,
                  'name': 'Đường Test',
                  'maneuver': {'instruction': 'Đi thẳng'}
                }
              ]
            }
          ],
        }
      ],
    };

    MapBoxService.instance.setHttpClient(
      MockClient((request) async {
        if (request.url.path.contains('directions')) {
          final body = jsonEncode(fakeResponse);
          return http.Response.bytes(
            utf8.encode(body),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('not found', 404);
      }),
    );

    final route = await MapBoxService.instance.getRoute(
      originLat: 10.776889,
      originLng: 106.700897,
      destinationLat: 21.027763,
      destinationLng: 105.83416,
    );

    expect(route, isNotNull);
    expect(route!.distance, closeTo(1657.3, 0.1));
    expect(route.steps, isNotEmpty);
    expect(route.steps.first.instruction, isNotEmpty);
  });
}

