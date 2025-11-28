import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:smart_travel_app/config/api/api_config.dart';
import 'package:smart_travel_app/models/trips/trip.dart';
import 'package:smart_travel_app/models/trips/trip_item.dart';
import 'package:smart_travel_app/models/trips/trip_cost_estimate.dart';

/// Service để tính toán chi phí du lịch bằng AI (Gemini)
class AICostEstimationService {
  AICostEstimationService._();
  static final AICostEstimationService instance = AICostEstimationService._();

  String? _lastUsedModel; // Lưu model đã dùng để set vào estimate

  /// Tính toán chi phí cho trip bằng AI
  /// [multiplier] để điều chỉnh nhu cầu: 1.0 = bình thường, >1.0 = cao hơn, <1.0 = thấp hơn
  Future<TripCostEstimate?> estimateTripCost(
    Trip trip, {
    double multiplier = 1.0,
  }) async {
    try {
      // Build prompt
      final prompt = _buildPrompt(trip, multiplier);

      // Gọi Gemini API
      final response = await _callGeminiAPI(prompt);

      String? aiDescription;
      if (response != null) {
        // Parse response
        final estimate = _parseAIResponse(response, trip);
        if (estimate != null) {
          debugPrint(
            '✅ AI cost estimation completed (multiplier: $multiplier)',
          );
          return estimate;
        }

        // Nếu parse fail nhưng có description, lưu lại để dùng trong fallback
        // Thử nhiều patterns để tìm description
        RegExpMatch? descMatch;

        // Pattern 1: [DETAILED_DESCRIPTION]...[/DETAILED_DESCRIPTION]
        descMatch = RegExp(
          r'\[DETAILED_DESCRIPTION\]([\s\S]*?)\[/DETAILED_DESCRIPTION\]',
          caseSensitive: false,
        ).firstMatch(response);

        // Pattern 2: Nếu không có closing tag, lấy từ [DETAILED_DESCRIPTION] đến cuối hoặc đến [JSON]
        if (descMatch == null) {
          descMatch = RegExp(
            r'\[DETAILED_DESCRIPTION\]([\s\S]*?)(?:\[/DETAILED_DESCRIPTION\]|\[JSON\]|$)',
            caseSensitive: false,
          ).firstMatch(response);
        }

        // Pattern 3: Nếu vẫn không có, tìm từ "DETAILED_DESCRIPTION" (không có brackets)
        if (descMatch == null) {
          descMatch = RegExp(
            r'DETAILED_DESCRIPTION[:\s]*([\s\S]*?)(?:\[/DETAILED_DESCRIPTION\]|\[JSON\]|$)',
            caseSensitive: false,
          ).firstMatch(response);
        }

        if (descMatch != null) {
          aiDescription = descMatch.group(1)?.trim();
          if (aiDescription != null && aiDescription.isNotEmpty) {
            debugPrint(
              '💡 AI trả về description (${aiDescription.length} chars) nhưng không có JSON. Sẽ dùng fallback với description từ AI.',
            );
          } else {
            debugPrint('⚠️ Found description tag but content is empty');
          }
        } else {
          debugPrint('⚠️ No description tag found in AI response');
        }
      }

      // Fallback to manual calculation
      debugPrint('⚠️ AI estimation failed, using fallback');
      final fallback = _fallbackEstimate(trip, multiplier);

      // Nếu có description từ AI, dùng nó thay vì fallback description
      if (aiDescription != null && aiDescription.isNotEmpty) {
        return fallback.copyWith(
          detailedDescription: aiDescription,
          aiModel: _lastUsedModel ?? 'gemini-2.5-pro',
        );
      }

      return fallback;
    } catch (e, stack) {
      debugPrint('❌ Error estimating cost: $e');
      debugPrint('$stack');
      // Fallback to manual calculation
      return _fallbackEstimate(trip, multiplier);
    }
  }

  /// Build prompt cho Gemini API
  String _buildPrompt(Trip trip, double multiplier) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('dd/MM/yyyy');

    // PHẦN 1: YÊU CẦU JSON TRƯỚC (QUAN TRỌNG NHẤT)
    buffer.writeln(
      'Bạn là chuyên gia du lịch. Hãy ước tính chi phí và trả về KẾT QUẢ DƯỚI DẠNG JSON.',
    );
    buffer.writeln('');
    buffer.writeln(
      '**YÊU CẦU: Trả về JSON trước, sau đó mới mô tả chi tiết.**',
    );
    buffer.writeln('');
    buffer.writeln('**Format JSON (BẮT BUỘC - phải có đầy đủ 8 trường):**');
    buffer.writeln('```json');
    buffer.writeln('{');
    buffer.writeln('  "entranceFees": 0,');
    buffer.writeln('  "food": 0,');
    buffer.writeln('  "accommodation": 0,');
    buffer.writeln('  "transportation": 0,');
    buffer.writeln('  "shopping": 0,');
    buffer.writeln('  "miscellaneous": 0,');
    buffer.writeln('  "total": 0,');
    buffer.writeln('  "perPerson": 0');
    buffer.writeln('}');
    buffer.writeln('```');
    buffer.writeln('');
    buffer.writeln(
      '**Lưu ý:** Tất cả giá trị là số nguyên (VND), không có dấu phẩy, không có đơn vị.',
    );
    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('');
    buffer.writeln('**Thông tin chuyến đi:**');
    buffer.writeln('- Số ngày: ${trip.daysCount} ngày');
    buffer.writeln('- Số người: ${trip.numberOfTravelers} người');
    buffer.writeln('- Loại du lịch: ${trip.budgetLevel.displayName}');
    buffer.writeln(
      '- Ngày: ${dateFormat.format(trip.startDate)} - ${dateFormat.format(trip.endDate)}',
    );
    if (trip.startingLocation != null && trip.startingLocation!.isNotEmpty) {
      buffer.writeln('- Điểm xuất phát: ${trip.startingLocation}');
    }
    buffer.writeln('');

    // Danh sách điểm đến (rút gọn)
    buffer.writeln('**Điểm đến:**');
    final itemsByDate = <DateTime, List<TripItem>>{};
    for (var item in trip.items) {
      if (item.destination != null && item.plannedDate != null) {
        final date = DateTime(
          item.plannedDate!.year,
          item.plannedDate!.month,
          item.plannedDate!.day,
        );
        itemsByDate.putIfAbsent(date, () => []).add(item);
      }
    }

    final sortedDates = itemsByDate.keys.toList()..sort();
    for (var date in sortedDates) {
      final items = itemsByDate[date]!;
      buffer.writeln(
        '- ${dateFormat.format(date)}: ${items.map((i) => i.destination!.name).join(', ')}',
      );
      for (var item in items) {
        if (item.destination!.entranceFee != null &&
            item.destination!.entranceFee! > 0) {
          buffer.writeln(
            '  • Vé ${item.destination!.name}: ${item.destination!.entranceFee!.toStringAsFixed(0)} VND/người',
          );
        }
      }
    }
    buffer.writeln('');

    // Di chuyển (rút gọn)
    if (trip.startingLocation != null && trip.startingLocation!.isNotEmpty) {
      final sortedItems =
          trip.items
              .where(
                (item) => item.destination != null && item.plannedDate != null,
              )
              .toList()
            ..sort((a, b) => a.plannedDate!.compareTo(b.plannedDate!));
      if (sortedItems.isNotEmpty) {
        buffer.writeln('**Di chuyển:**');
        buffer.writeln(
          '- ${trip.startingLocation} → ${sortedItems.first.destination!.name}',
        );
        for (var i = 0; i < sortedItems.length - 1; i++) {
          buffer.writeln(
            '- ${sortedItems[i].destination!.name} → ${sortedItems[i + 1].destination!.name}',
          );
        }
        buffer.writeln('');
      }
    }

    // Hướng dẫn tính toán (rút gọn)
    buffer.writeln('**Hướng dẫn tính toán:**');
    switch (trip.budgetLevel) {
      case TripBudgetLevel.budget:
        buffer.writeln('- Ăn uống: ~150k/người/ngày');
        buffer.writeln('- Nơi ở: ~300k/phòng/đêm');
        break;
      case TripBudgetLevel.moderate:
        buffer.writeln('- Ăn uống: ~300k/người/ngày');
        buffer.writeln('- Nơi ở: ~600k/phòng/đêm');
        break;
      case TripBudgetLevel.luxury:
        buffer.writeln('- Ăn uống: ~600k/người/ngày');
        buffer.writeln('- Nơi ở: ~1.5M/phòng/đêm');
        break;
    }
    if (multiplier != 1.0) {
      buffer.writeln(
        '- Điều chỉnh: ${(multiplier * 100).toStringAsFixed(0)}% ${multiplier > 1.0 ? "cao hơn" : "thấp hơn"}',
      );
    }
    buffer.writeln('- Di chuyển: tính theo từng chặng (xe khách/taxi/máy bay)');
    buffer.writeln('- Mua sắm: ~500k/người');
    buffer.writeln('');

    // Yêu cầu output (JSON trước, description sau)
    buffer.writeln('**OUTPUT FORMAT (QUAN TRỌNG):**');
    buffer.writeln('');
    buffer.writeln('1. TRẢ VỀ JSON TRƯỚC (bắt buộc):');
    buffer.writeln('```json');
    buffer.writeln('{');
    buffer.writeln('  "entranceFees": [tổng vé tham quan],');
    buffer.writeln('  "food": [tổng ăn uống],');
    buffer.writeln('  "accommodation": [tổng nơi ở],');
    buffer.writeln('  "transportation": [tổng di chuyển],');
    buffer.writeln('  "shopping": [tổng mua sắm],');
    buffer.writeln('  "miscellaneous": [chi phí phát sinh ~10% tổng],');
    buffer.writeln('  "total": [tổng tất cả],');
    buffer.writeln('  "perPerson": [total / số người]');
    buffer.writeln('}');
    buffer.writeln('```');
    buffer.writeln('');
    buffer.writeln('2. SAU ĐÓ mô tả chi tiết kế hoạch theo ngày (BẮT BUỘC):');
    buffer.writeln('```');
    buffer.writeln('## Kế hoạch theo ngày');
    buffer.writeln('');
    buffer.writeln('### Ngày 1 (${dateFormat.format(trip.startDate)})');
    buffer.writeln('**Sáng:** Di chuyển, tham quan, ăn sáng...');
    buffer.writeln('**Trưa:** Hoạt động, ăn trưa...');
    buffer.writeln('**Chiều:** Tham quan, mua sắm...');
    buffer.writeln('**Tối:** Ăn tối, nghỉ đêm...');
    buffer.writeln('');
    buffer.writeln('### Ngày 2...');
    buffer.writeln('```');
    buffer.writeln('');
    buffer.writeln('**LƯU Ý:**');
    buffer.writeln(
      '- JSON là bắt buộc, phải có đầy đủ 8 trường. Giá trị là số nguyên (VND).',
    );
    buffer.writeln(
      '- Mô tả chi tiết cũng BẮT BUỘC, phải liệt kê từng ngày với hoạt động và chi phí cụ thể.',
    );

    return buffer.toString();
  }

  /// List các models có sẵn và tự động lấy models hỗ trợ generateContent
  Future<List<String>> getAvailableModels() async {
    final availableModels = <String>[];

    // Thử cả v1 và v1beta
    final baseUrls = [
      'https://generativelanguage.googleapis.com/v1beta',
      ApiConfig.geminiBaseUrl, // v1
    ];

    for (final baseUrl in baseUrls) {
      try {
        final url = Uri.parse('$baseUrl/models?key=${ApiConfig.geminiApiKey}');

        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final models = data['models'] as List?;
          if (models != null) {
            for (var model in models) {
              final name = model['name'] as String?;
              final supportedMethods =
                  model['supportedGenerationMethods'] as List?;
              if (name != null &&
                  supportedMethods != null &&
                  supportedMethods.contains('generateContent')) {
                // Lấy tên model (bỏ prefix "models/")
                final modelName = name.replaceFirst('models/', '');
                if (!availableModels.contains(modelName)) {
                  availableModels.add(modelName);
                }
              }
            }
            if (availableModels.isNotEmpty) {
              debugPrint(
                '✅ Found ${availableModels.length} available models from $baseUrl',
              );
              break; // Đã tìm thấy, không cần thử baseUrl khác
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error listing models from $baseUrl: $e');
      }
    }

    return availableModels;
  }

  /// Gọi Gemini API
  Future<String?> _callGeminiAPI(String prompt) async {
    // Danh sách models ưu tiên (từ stable đến experimental)
    // Ưu tiên gemini-2.5-pro trước, nếu fail thì thử các models khác
    final models = [
      'gemini-2.5-pro', // Ưu tiên 1: Model stable, mạnh
      'gemini-2.5-flash', // Ưu tiên 2: Model stable, nhanh
      'gemini-2.0-flash-001', // Ưu tiên 3: Model stable
      'gemini-2.0-flash', // Ưu tiên 4: Model mới nhất
    ];

    // Thử cả v1beta và v1 (v1beta thường có nhiều models hơn)
    final baseUrls = [
      'https://generativelanguage.googleapis.com/v1beta',
      'https://generativelanguage.googleapis.com/v1',
    ];

    String? lastError;
    for (final model in models) {
      for (final baseUrl in baseUrls) {
        try {
          final url = Uri.parse(
            '$baseUrl/models/$model:generateContent?key=${ApiConfig.geminiApiKey}',
          );

          final requestBody = {
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
            'generationConfig': {
              'temperature': 0.7,
              'topK': 40,
              'topP': 0.95,
              'maxOutputTokens':
                  8192, // Tăng lên 8192 để không bị giới hạn description (Gemini 2.5-pro hỗ trợ tối đa 8192 tokens)
            },
          };

          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final candidates = data['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final content = candidates[0]['content'];
              final parts = content['parts'] as List?;
              if (parts != null && parts.isNotEmpty) {
                final responseText = parts[0]['text'] as String?;
                debugPrint('✅ Successfully used model: $model with $baseUrl');
                // Lưu model name để dùng trong parse
                _lastUsedModel = model;
                return responseText;
              }
            }
          } else {
            final errorBody = response.body;
            try {
              final errorData = json.decode(errorBody);
              final errorMsg = errorData['error']?['message'] ?? errorBody;
              debugPrint(
                '⚠️ Model $model with $baseUrl: ${response.statusCode} - $errorMsg',
              );
            } catch (_) {
              debugPrint(
                '⚠️ Model $model with $baseUrl: ${response.statusCode} - $errorBody',
              );
            }
            // Tiếp tục thử baseUrl tiếp theo
            continue;
          }
        } catch (e) {
          debugPrint('⚠️ Model $model with $baseUrl: $e');
          continue; // Thử baseUrl tiếp theo
        }
      }
      // Nếu cả 2 baseUrls đều fail cho model này, lưu lỗi và thử model tiếp theo
      lastError = 'Model $model: Failed with both v1 and v1beta';
      debugPrint('⚠️ $lastError, trying next model...');
    }

    // Nếu tất cả models đều fail
    debugPrint('❌ All models failed. Last error: $lastError');
    debugPrint('💡 Sẽ dùng fallback calculation thay vì AI');
    return null;
  }

  /// Parse response từ AI
  TripCostEstimate? _parseAIResponse(String response, Trip trip) {
    try {
      // Tách text mô tả và JSON
      String? detailedDescription;
      String? jsonString;

      // Tìm phần JSON trước (vì JSON được ưu tiên trong prompt)
      // Tìm phần JSON - ưu tiên tìm trong markdown code blocks trước (AI thường dùng format này)
      // Pattern 1: ```json ... ``` hoặc ``` ... ```
      final codeBlockMatch = RegExp(
        r'```(?:json)?\s*(\{[\s\S]*?\})\s*```',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(response);
      if (codeBlockMatch != null) {
        jsonString = codeBlockMatch.group(1)?.trim();
        debugPrint('✅ Found JSON in markdown code block');
      } else {
        // Pattern 2: [JSON]...[/JSON] tags
        final jsonTagMatch = RegExp(
          r'\[JSON\]([\s\S]*?)\[/JSON\]',
          caseSensitive: false,
          dotAll: true,
        ).firstMatch(response);
        if (jsonTagMatch != null) {
          jsonString = jsonTagMatch.group(1)?.trim();
          debugPrint('✅ Found JSON in tags');
        } else {
          // Pattern 3: Tìm JSON object trong description text (nếu AI trả về JSON trong description)
          // Tìm pattern như: "entranceFees": 500000, "food": 1800000, ...
          final jsonInTextMatch = RegExp(
            r'\{[\s\S]*?"entranceFees"[\s\S]*?"perPerson"[\s\S]*?\}',
            caseSensitive: false,
            dotAll: true,
          ).firstMatch(response);
          if (jsonInTextMatch != null) {
            jsonString = jsonInTextMatch.group(0)?.trim();
            debugPrint('✅ Found JSON object in description text');
          } else {
            // Pattern 4: JSON object bất kỳ (fallback cuối cùng)
            final jsonMatch = RegExp(
              r'\{[\s\S]*?\}',
              dotAll: true,
            ).firstMatch(response);
            if (jsonMatch != null) {
              jsonString = jsonMatch.group(0)?.trim();
              debugPrint('✅ Found JSON object (generic)');
            }
          }
        }
      }

      // Tìm phần DESCRIPTION (sau khi đã tìm JSON)
      // Pattern 1: [DETAILED_DESCRIPTION]...[/DETAILED_DESCRIPTION]
      RegExpMatch? descMatch = RegExp(
        r'\[DETAILED_DESCRIPTION\]([\s\S]*?)\[/DETAILED_DESCRIPTION\]',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(response);
      if (descMatch != null) {
        detailedDescription = descMatch.group(1)?.trim();
        debugPrint(
          '✅ Found detailed description in tags (${detailedDescription?.length ?? 0} chars)',
        );
        if (detailedDescription != null && detailedDescription.isNotEmpty) {
          final previewLength = detailedDescription.length > 300
              ? 300
              : detailedDescription.length;
          debugPrint(
            '📝 Description preview (first $previewLength chars): ${detailedDescription.substring(0, previewLength)}...',
          );
        }
      } else {
        // Pattern 2: Tìm trong markdown code block (không phải json)
        // Tìm ``` ... ``` nhưng không phải ```json
        final descCodeBlockMatch = RegExp(
          r'```(?!json\b)([\s\S]*?)```',
          caseSensitive: false,
          dotAll: true,
        ).firstMatch(response);
        if (descCodeBlockMatch != null) {
          detailedDescription = descCodeBlockMatch.group(1)?.trim();
          debugPrint(
            '✅ Found detailed description in markdown code block (${detailedDescription?.length ?? 0} chars)',
          );
        } else {
          // Pattern 3: Tìm text sau JSON (vì prompt yêu cầu JSON trước, description sau)
          if (jsonString != null) {
            final jsonEndIndex =
                response.indexOf(jsonString) + jsonString.length;
            if (jsonEndIndex < response.length) {
              final textAfterJson = response.substring(jsonEndIndex).trim();
              // Lấy phần text sau JSON, bỏ qua các ký tự markdown/code block còn sót
              if (textAfterJson.isNotEmpty && textAfterJson.length > 50) {
                // Loại bỏ các ký tự markdown/code block ở đầu
                final cleanedText = textAfterJson
                    .replaceFirst(
                      RegExp(r'^```\s*', caseSensitive: false, multiLine: true),
                      '',
                    )
                    .replaceFirst(
                      RegExp(r'\s*```$', caseSensitive: false, multiLine: true),
                      '',
                    )
                    .trim();
                if (cleanedText.isNotEmpty && cleanedText.length > 50) {
                  detailedDescription = cleanedText;
                  debugPrint(
                    '✅ Found detailed description after JSON (${detailedDescription.length} chars)',
                  );
                  debugPrint(
                    '📝 Description preview (first 200 chars): ${detailedDescription.substring(0, detailedDescription.length > 200 ? 200 : detailedDescription.length)}...',
                  );
                }
              }
            }
          }
        }
      }

      // Loại bỏ markdown code block syntax nếu còn sót (đảm bảo clean JSON)
      if (jsonString != null) {
        // Loại bỏ ```json hoặc ``` ở đầu/cuối (nếu regex chưa capture đúng)
        jsonString = jsonString.replaceFirst(
          RegExp(r'^```(?:json)?\s*', caseSensitive: false, multiLine: true),
          '',
        );
        jsonString = jsonString.replaceFirst(
          RegExp(r'\s*```$', caseSensitive: false, multiLine: true),
          '',
        );
        // Loại bỏ các ký tự markdown khác có thể còn sót
        jsonString = jsonString.trim();
      }

      if (jsonString == null || jsonString.isEmpty) {
        debugPrint('⚠️ No JSON found in AI response');
        debugPrint(
          'Response preview (first 500 chars): ${response.substring(0, response.length > 500 ? 500 : response.length)}...',
        );
        return null;
      }

      // Parse JSON
      final data = json.decode(jsonString) as Map<String, dynamic>;

      final estimate = TripCostEstimate(
        entranceFees: (data['entranceFees'] ?? 0).toDouble(),
        food: (data['food'] ?? 0).toDouble(),
        accommodation: (data['accommodation'] ?? 0).toDouble(),
        transportation: (data['transportation'] ?? 0).toDouble(),
        shopping: (data['shopping'] ?? 0).toDouble(),
        miscellaneous: (data['miscellaneous'] ?? 0).toDouble(),
        total: (data['total'] ?? 0).toDouble(),
        perPerson: (data['perPerson'] ?? 0).toDouble(),
        estimatedAt: DateTime.now(),
        aiModel:
            _lastUsedModel ??
            'gemini-2.5-pro', // Model đã được sử dụng thành công
        detailedDescription: detailedDescription,
      );

      // Log để debug
      if (detailedDescription != null) {
        debugPrint(
          '📊 Final estimate - description length: ${detailedDescription.length} chars',
        );
        debugPrint(
          '📝 Description preview (first 300 chars): ${detailedDescription.substring(0, detailedDescription.length > 300 ? 300 : detailedDescription.length)}...',
        );
      } else {
        debugPrint('⚠️ Final estimate - NO description');
      }

      return estimate;
    } catch (e, stack) {
      debugPrint('❌ Error parsing AI response: $e');
      debugPrint(
        'Response preview: ${response.substring(0, response.length > 500 ? 500 : response.length)}...',
      );
      debugPrint('$stack');
      return null;
    }
  }

  /// Fallback: Tính toán thủ công nếu AI fail
  TripCostEstimate _fallbackEstimate(Trip trip, double multiplier) {
    // Tính vé tham quan
    double entranceFees = 0;
    for (var item in trip.items) {
      if (item.destination?.entranceFee != null) {
        entranceFees += item.destination!.entranceFee! * trip.numberOfTravelers;
      }
    }

    // Tính ăn uống và nơi ở dựa trên budget level
    double foodPerPersonPerDay;
    double accommodationPerRoomPerNight;

    switch (trip.budgetLevel) {
      case TripBudgetLevel.budget:
        foodPerPersonPerDay = 150000;
        accommodationPerRoomPerNight = 300000;
        break;
      case TripBudgetLevel.moderate:
        foodPerPersonPerDay = 300000;
        accommodationPerRoomPerNight = 600000;
        break;
      case TripBudgetLevel.luxury:
        foodPerPersonPerDay = 600000;
        accommodationPerRoomPerNight = 1500000;
        break;
    }

    var food = foodPerPersonPerDay * trip.numberOfTravelers * trip.daysCount;
    // Giả sử 2 người/phòng
    final numberOfRooms = (trip.numberOfTravelers / 2).ceil();
    var accommodation =
        accommodationPerRoomPerNight * numberOfRooms * (trip.daysCount - 1);

    // Di chuyển: ước tính 200k/người/ngày
    var transportation = 200000.0 * trip.numberOfTravelers * trip.daysCount;

    // Mua sắm: ước tính 500k/người
    var shopping = 500000.0 * trip.numberOfTravelers;

    // Áp dụng multiplier
    food *= multiplier;
    accommodation *= multiplier;
    transportation *= multiplier;
    shopping *= multiplier;

    // Chi phí phát sinh: 10% tổng
    final subtotal =
        entranceFees + food + accommodation + transportation + shopping;
    final miscellaneous = subtotal * 0.1;

    final total = subtotal + miscellaneous;
    final perPerson = total / trip.numberOfTravelers;

    // Tạo text mô tả đơn giản cho fallback
    final description = _generateFallbackDescription(trip, multiplier);

    return TripCostEstimate(
      entranceFees: entranceFees,
      food: food,
      accommodation: accommodation,
      transportation: transportation,
      shopping: shopping,
      miscellaneous: miscellaneous,
      total: total,
      perPerson: perPerson,
      estimatedAt: DateTime.now(),
      aiModel: 'fallback',
      detailedDescription: description,
    );
  }

  /// Tạo text mô tả đơn giản cho fallback (có kế hoạch đi chơi theo ngày)
  String _generateFallbackDescription(Trip trip, double multiplier) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Tính giá theo budget level
    final foodPerPersonPerDay =
        150000 *
        (trip.budgetLevel == TripBudgetLevel.budget
            ? 1
            : trip.budgetLevel == TripBudgetLevel.moderate
            ? 2
            : 4) *
        multiplier;
    final accommodationPerRoomPerNight =
        300000 *
        (trip.budgetLevel == TripBudgetLevel.budget
            ? 1
            : trip.budgetLevel == TripBudgetLevel.moderate
            ? 2
            : 5) *
        multiplier;
    final transportationPerPersonPerDay = 200000 * multiplier;
    final shoppingPerPerson = 500000 * multiplier;

    // Nhóm điểm đến theo ngày
    final itemsByDate = <DateTime, List<TripItem>>{};
    for (var item in trip.items) {
      if (item.destination != null && item.plannedDate != null) {
        final date = DateTime(
          item.plannedDate!.year,
          item.plannedDate!.month,
          item.plannedDate!.day,
        );
        itemsByDate.putIfAbsent(date, () => []).add(item);
      }
    }

    // Sắp xếp items theo ngày để tính di chuyển giữa các điểm
    final sortedItems =
        trip.items
            .where(
              (item) => item.destination != null && item.plannedDate != null,
            )
            .toList()
          ..sort((a, b) => a.plannedDate!.compareTo(b.plannedDate!));

    // Tạo kế hoạch đi chơi theo ngày
    for (var dayIndex = 0; dayIndex < trip.daysCount; dayIndex++) {
      final currentDate = trip.startDate.add(Duration(days: dayIndex));
      final dateKey = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
      );
      final itemsForDay = itemsByDate[dateKey] ?? [];

      buffer.writeln(
        '## Ngày ${dayIndex + 1} (${dateFormat.format(currentDate)})',
      );
      buffer.writeln('');

      // Kiểm tra xem có cần di chuyển đến điểm nào trong ngày này không
      String? transportationNote;
      double transportationCostForDay = 0;

      // Tìm item đầu tiên trong ngày này
      if (itemsForDay.isNotEmpty && itemsForDay.first.destination != null) {
        final currentItem = itemsForDay.first;
        final currentDest = currentItem.destination!;

        // Tìm điểm trước đó
        String? fromLocation;
        if (dayIndex == 0 &&
            trip.startingLocation != null &&
            trip.startingLocation!.isNotEmpty) {
          // Ngày đầu: di chuyển từ điểm xuất phát
          fromLocation = trip.startingLocation;
          transportationCostForDay =
              transportationPerPersonPerDay *
              trip.numberOfTravelers *
              0.5; // Chi phí di chuyển đường dài
          transportationNote =
              'Di chuyển từ $fromLocation đến ${currentDest.name} (${currentDest.location.city}): Taxi/Xe khách - ~${transportationCostForDay.toStringAsFixed(0)} VND';
        } else {
          // Tìm điểm đến trước đó trong sortedItems
          for (var i = 0; i < sortedItems.length; i++) {
            if (sortedItems[i].destination?.id == currentDest.id) {
              // Tìm điểm trước đó
              if (i > 0) {
                final prevDest = sortedItems[i - 1].destination!;
                fromLocation = prevDest.name;
                // Tính chi phí di chuyển giữa 2 điểm (có thể cùng thành phố hoặc khác thành phố)
                final isSameCity =
                    prevDest.location.city == currentDest.location.city;
                transportationCostForDay = isSameCity
                    ? transportationPerPersonPerDay *
                          trip.numberOfTravelers *
                          0.2 // Di chuyển trong thành phố
                    : transportationPerPersonPerDay *
                          trip.numberOfTravelers *
                          0.5; // Di chuyển đường dài
                transportationNote =
                    'Di chuyển từ $fromLocation (${prevDest.location.city}) đến ${currentDest.name} (${currentDest.location.city}): ${isSameCity ? "Taxi/Xe máy" : "Xe khách/Máy bay"} - ~${transportationCostForDay.toStringAsFixed(0)} VND';
              }
              break;
            }
          }
        }
      }

      // Sáng
      buffer.writeln('**Sáng:**');
      if (transportationNote != null) {
        buffer.writeln('- $transportationNote');
      }
      if (itemsForDay.isNotEmpty) {
        for (var item in itemsForDay) {
          if (item.destination != null) {
            final entranceFee = item.destination!.entranceFee ?? 0;
            if (entranceFee > 0) {
              buffer.writeln(
                '- Tham quan ${item.destination!.name}: Vé vào cửa ~${(entranceFee * trip.numberOfTravelers).toStringAsFixed(0)} VND',
              );
            } else {
              buffer.writeln('- Tham quan ${item.destination!.name}');
            }
          }
        }
      } else {
        buffer.writeln(
          '- Nghỉ ngơi/Tham quan tự do (không có điểm đến cố định)',
        );
      }
      buffer.writeln(
        '- Ăn sáng: ~${(foodPerPersonPerDay * trip.numberOfTravelers * 0.2).toStringAsFixed(0)} VND',
      );
      buffer.writeln('');

      // Trưa
      buffer.writeln('**Trưa:**');
      if (itemsForDay.length > 1) {
        buffer.writeln('- Tiếp tục tham quan các điểm đến');
      } else if (itemsForDay.isEmpty) {
        buffer.writeln('- Tham quan tự do/Khám phá địa phương');
      }
      buffer.writeln(
        '- Ăn trưa: ~${(foodPerPersonPerDay * trip.numberOfTravelers * 0.4).toStringAsFixed(0)} VND',
      );
      buffer.writeln('');

      // Chiều
      buffer.writeln('**Chiều:**');
      if (itemsForDay.isNotEmpty) {
        buffer.writeln('- Tham quan và khám phá');
      } else {
        buffer.writeln('- Nghỉ ngơi/Tham quan tự do');
      }
      buffer.writeln(
        '- Mua sắm/Quà lưu niệm: ~${(shoppingPerPerson * trip.numberOfTravelers / trip.daysCount).toStringAsFixed(0)} VND',
      );
      buffer.writeln('');

      // Tối
      buffer.writeln('**Tối:**');
      buffer.writeln(
        '- Ăn tối: ~${(foodPerPersonPerDay * trip.numberOfTravelers * 0.4).toStringAsFixed(0)} VND',
      );
      if (dayIndex < trip.daysCount - 1) {
        final numberOfRooms = (trip.numberOfTravelers / 2).ceil();
        buffer.writeln(
          '- Nghỉ đêm: ~${(accommodationPerRoomPerNight * numberOfRooms).toStringAsFixed(0)} VND',
        );
      }

      // Tổng ngày (bao gồm chi phí di chuyển nếu có)
      final entranceFeesForDay = itemsForDay.isNotEmpty
          ? itemsForDay
                .map(
                  (item) =>
                      (item.destination?.entranceFee ?? 0) *
                      trip.numberOfTravelers,
                )
                .fold(0.0, (a, b) => a + b)
          : 0.0;
      final dayTotal =
          (foodPerPersonPerDay * trip.numberOfTravelers) +
          (dayIndex < trip.daysCount - 1
              ? accommodationPerRoomPerNight *
                    (trip.numberOfTravelers / 2).ceil()
              : 0) +
          transportationCostForDay + // Chi phí di chuyển cụ thể cho ngày này
          (shoppingPerPerson * trip.numberOfTravelers / trip.daysCount) +
          entranceFeesForDay;
      buffer.writeln('');
      buffer.writeln(
        '**Tổng chi phí ngày ${dayIndex + 1}:** ~${dayTotal.toStringAsFixed(0)} VND',
      );
      buffer.writeln('');
    }

    // Tổng hợp breakdown
    buffer.writeln('---');
    buffer.writeln('');
    buffer.writeln('## Tổng hợp chi phí');
    buffer.writeln('');
    buffer.writeln('### Ăn uống');
    buffer.writeln('- Loại: ${trip.budgetLevel.displayName}');
    buffer.writeln(
      '- Ước tính: ~${foodPerPersonPerDay.toStringAsFixed(0)} VND/người/ngày',
    );
    buffer.writeln('');
    buffer.writeln('### Nơi ở');
    buffer.writeln('- Loại: ${trip.budgetLevel.displayName}');
    buffer.writeln(
      '- Ước tính: ~${accommodationPerRoomPerNight.toStringAsFixed(0)} VND/phòng/đêm',
    );
    buffer.writeln('');
    buffer.writeln('### Di chuyển');
    buffer.writeln(
      '- Ước tính: ~${transportationPerPersonPerDay.toStringAsFixed(0)} VND/người/ngày',
    );
    buffer.writeln('');
    buffer.writeln('### Mua sắm');
    buffer.writeln(
      '- Ước tính: ~${shoppingPerPerson.toStringAsFixed(0)} VND/người',
    );
    if (multiplier != 1.0) {
      buffer.writeln('');
      buffer.writeln(
        '*Đã điều chỉnh ${multiplier > 1.0 ? "cao hơn" : "thấp hơn"} ${((multiplier - 1.0).abs() * 100).toStringAsFixed(0)}%*',
      );
    }
    buffer.writeln('');
    buffer.writeln(
      '*Lưu ý: Đây là ước tính dựa trên công thức chuẩn. Để có kế hoạch chi tiết hơn với các cửa hàng cụ thể, vui lòng thử lại tính toán bằng AI.*',
    );

    return buffer.toString();
  }
}
