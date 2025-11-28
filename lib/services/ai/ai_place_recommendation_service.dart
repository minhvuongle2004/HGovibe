import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:smart_travel_app/config/api/api_config.dart';
import 'package:smart_travel_app/models/ai/ai_activity_suggestion.dart';
import 'package:smart_travel_app/models/trips/trip.dart';
import 'package:smart_travel_app/models/trips/trip_item.dart';

/// Service gọi Gemini để gợi ý nhà hàng/quán ăn dựa trên lịch trình & POI lân cận
class AIPlaceRecommendationService {
  AIPlaceRecommendationService._();
  static final AIPlaceRecommendationService instance =
      AIPlaceRecommendationService._();

  // Chỉ dùng 2 models tốt nhất để tăng tốc (giảm từ 4 xuống 2)
  static const _modelCandidates = [
    'gemini-2.5-flash', // Nhanh nhất, ưu tiên
    'gemini-2.5-pro', // Thông minh nhất, fallback
  ];

  // Chỉ dùng v1beta (thường có nhiều models hơn)
  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  static const _requestTimeout = Duration(seconds: 40); // Timeout ngắn hơn

  Future<List<AIActivitySuggestion>> generateSuggestions({
    required String tripId,
    required Trip trip,
    required Map<String, TripItem> tripItemsByKey,
  }) async {
    if (tripItemsByKey.isEmpty) {
      return [];
    }

    final prompt = _buildPrompt(trip: trip, tripItemsByKey: tripItemsByKey);

    final response = await _callGemini(prompt);
    if (response == null) {
      return [];
    }

    final parsed = _parseResponse(
      response,
      tripId: tripId,
      trip: trip,
      tripItemsByKey: tripItemsByKey,
    );
    return parsed;
  }

  String _buildPrompt({
    required Trip trip,
    required Map<String, TripItem> tripItemsByKey,
  }) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('dd/MM/yyyy');

    buffer.writeln(
      'Bạn là chuyên gia ẩm thực địa phương. BẮT BUỘC tuân thủ các yêu cầu sau:',
    );
    buffer.writeln('');
    buffer.writeln('**YÊU CẦU OUTPUT (ĐỌC TRƯỚC):**');
    buffer.writeln(
      '1. PHẦN HỒI PHI PHẢI BẮT ĐẦU bằng code block ```json ... ``` và KHÔNG có text nào trước đó.',
    );
    buffer.writeln('2. Format:');
    buffer.writeln('```json');
    buffer.writeln('[');
    buffer.writeln('  {');
    buffer.writeln('    "id": "string duy nhất",');
    buffer.writeln('    "targetItemKey": "KEY trùng với KEY ở trên",');
    buffer.writeln('    "name": "Tên địa điểm ăn uống",');
    buffer.writeln(
      '    "description": "Mô tả ngắn (<=100 ký tự)",',
    ); // GIẢM từ 160 xuống 100
    buffer.writeln(
      '    "reason": "Lý do gợi ý (<=80 ký tự)",',
    ); // THÊM giới hạn
    buffer.writeln(
      '    "category": "restaurant | cafe | street-food | bar | dessert | other",',
    );
    buffer.writeln(
      '    "mealType": "breakfast | lunch | coffee | dinner | late-night",',
    );
    buffer.writeln('    "estimatedDuration": 90,');
    buffer.writeln('    "estimatedCost": 150000,');
    buffer.writeln('    "address": "Địa chỉ ngắn gọn",'); // THÊM "ngắn gọn"
    buffer.writeln('    "latitude": 21.03,');
    buffer.writeln('    "longitude": 105.85,');
    buffer.writeln('    "sourcePlaceId": null');
    buffer.writeln('  }');
    buffer.writeln(']');
    buffer.writeln('```');
    buffer.writeln('3. Bắt buộc `targetItemKey` hợp lệ.');
    buffer.writeln(
      '4. Chỉ gợi ý nhà hàng/quán cafe/quán ăn trong bán kính ~5km quanh điểm tương ứng.',
    );
    buffer.writeln(
      '5. Không tự bịa tọa độ. Nếu không chắc, đặt `latitude` và `longitude` là null.',
    );
    buffer.writeln('6. Không thêm mô tả hay markdown ngoài code block JSON.');
    buffer.writeln(
      '7. TỐI ĐA 3-4 gợi ý, ưu tiên trải nghiệm bản địa & phù hợp ngân sách.', // GIẢM từ 6 xuống 3-4
    );
    buffer.writeln(
      '8. Giữ description và reason NGẮN GỌN để JSON không quá dài.',
    ); // THÊM yêu cầu mới
    buffer.writeln('9. Không nhắc lại các yêu cầu trên trong phần JSON.');
    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('**Thông tin chuyến đi:**');
    buffer.writeln('- Tên chuyến đi: ${trip.name}');
    buffer.writeln(
      '- Ngày: ${dateFormat.format(trip.startDate)} đến ${dateFormat.format(trip.endDate)}',
    );
    buffer.writeln('- Số người: ${trip.numberOfTravelers}');
    buffer.writeln('- Phong cách chi tiêu: ${trip.budgetLevel.displayName}');
    if (trip.location != null && trip.location!.isNotEmpty) {
      buffer.writeln('- Khu vực chính: ${trip.location}');
    }
    buffer.writeln('');

    buffer.writeln('**Bối cảnh từng điểm dừng:**');
    var index = 1;
    for (final entry in tripItemsByKey.entries) {
      final itemKey = entry.key;
      final item = entry.value;
      final destination = item.destination;
      if (destination == null) continue;

      final day = item.plannedDate != null
          ? dateFormat.format(item.plannedDate!)
          : 'không rõ ngày';
      final timeText = item.plannedTime != null
          ? '${item.plannedTime!.hour.toString().padLeft(2, '0')}:${item.plannedTime!.minute.toString().padLeft(2, '0')}'
          : 'không rõ giờ';
      final mealSlot = _inferMealTypeFromTripItem(item);
      final location = destination.location;
      final specialties = destination.specialties
          .take(2) // GIẢM từ 3 xuống 2
          .map((s) => s.name)
          .join(', ');

      buffer.writeln(
        '$index. KEY=$itemKey • $day lúc $timeText • ${destination.name} (${location.city})', // BỎ country để ngắn hơn
      );
      buffer.writeln('   • Meal slot mong muốn: $mealSlot');
      if (specialties.isNotEmpty) {
        buffer.writeln('   • Đặc sản: $specialties');
      }
      buffer.writeln('');
      index++;
    }

    return buffer.toString();
  }

  /// Gọi Gemini với parallel requests - lấy kết quả đầu tiên thành công
  Future<String?> _callGemini(String prompt) async {
    debugPrint('🚀 Bắt đầu gọi ${_modelCandidates.length} models song song...');

    // Tạo danh sách futures cho tất cả models (gọi song song)
    final futures = <Future<String?>>[];

    for (final model in _modelCandidates) {
      futures.add(_callSingleModel(model, prompt));
    }

    // Race condition: lấy kết quả đầu tiên thành công
    final completer = Completer<String?>();
    int completedCount = 0;
    bool hasSuccess = false;
    final startTime = DateTime.now();

    for (int i = 0; i < futures.length; i++) {
      final modelName = _modelCandidates[i];
      futures[i]
          .then((result) {
            final elapsed = DateTime.now().difference(startTime).inSeconds;
            completedCount++;
            debugPrint(
              '📊 Model $modelName hoàn thành sau ${elapsed}s (result: ${result != null && result.isNotEmpty ? "có dữ liệu" : "null/empty"})',
            );

            if (!hasSuccess && result != null && result.isNotEmpty) {
              hasSuccess = true;
              if (!completer.isCompleted) {
                completer.complete(result);
                debugPrint(
                  '✅ Lấy kết quả từ model $modelName (model thứ ${i + 1}, sau ${elapsed}s)',
                );
              }
            } else if (completedCount == futures.length &&
                !completer.isCompleted) {
              // Tất cả đã hoàn thành nhưng không có kết quả nào
              debugPrint(
                '⚠️ Tất cả ${futures.length} models đã hoàn thành nhưng không có kết quả hợp lệ',
              );
              completer.complete(null);
            }
          })
          .catchError((error, stack) {
            final elapsed = DateTime.now().difference(startTime).inSeconds;
            completedCount++;
            debugPrint('❌ Model $modelName fail sau ${elapsed}s: $error');
            if (completedCount == futures.length && !completer.isCompleted) {
              completer.complete(null);
            }
          });
    }

    final result = await completer.future;

    if (result == null || result.isEmpty) {
      debugPrint('❌ Gemini không trả dữ liệu gợi ý từ bất kỳ model nào.');
    }

    return result;
  }

  /// Gọi một model cụ thể với timeout
  Future<String?> _callSingleModel(String model, String prompt) async {
    final startTime = DateTime.now();
    debugPrint(
      '🔄 Đang gọi model $model... (timeout: ${_requestTimeout.inSeconds}s)',
    );
    try {
      final url = Uri.parse(
        '$_baseUrl/models/$model:generateContent?key=${ApiConfig.geminiApiKey}',
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
          'temperature': 0.6,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 8192, // Tăng từ 4096 lên 8192 để tránh MAX_TOKENS
        },
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(
            _requestTimeout,
            onTimeout: () {
              final elapsed = DateTime.now().difference(startTime).inSeconds;
              debugPrint('⏱️ Request timeout cho model $model sau ${elapsed}s');
              throw TimeoutException(
                'Request timeout after ${_requestTimeout.inSeconds}s',
                _requestTimeout,
              );
            },
          );

      final elapsed = DateTime.now().difference(startTime).inSeconds;

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final candidate = candidates.first as Map<String, dynamic>;

          // Kiểm tra finishReason
          final finishReason = candidate['finishReason'] as String?;
          if (finishReason != null && finishReason != 'STOP') {
            if (finishReason == 'MAX_TOKENS') {
              debugPrint(
                '⚠️ Model $model finishReason=MAX_TOKENS (đã dùng hết token, có thể vẫn có partial output)',
              );
            } else {
              debugPrint('⚠️ Model $model finishReason=$finishReason');
              if (candidate.containsKey('safetyRatings')) {
                final safetyRatings = candidate['safetyRatings'] as List?;
                if (safetyRatings != null) {
                  debugPrint('⚠️ Safety ratings: $safetyRatings');
                }
              }
            }
          }

          final content = candidate['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts.first['text'] as String?;
            if (text != null && text.trim().isNotEmpty) {
              debugPrint(
                '✅ Gemini trả kết quả với model $model sau ${elapsed}s (${text.length} chars)',
              );
              return text;
            } else {
              debugPrint(
                '⚠️ Model $model trả về nhưng text rỗng sau ${elapsed}s',
              );
              debugPrint(
                '📄 Response preview: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
              );
            }
          } else {
            debugPrint(
              '⚠️ Model $model trả về nhưng không có parts sau ${elapsed}s',
            );
            debugPrint(
              '📄 Response structure: candidates=${candidates.length}, content=${content != null ? "exists" : "null"}, parts=${parts != null ? "exists but empty" : "null"}',
            );
            debugPrint(
              '📄 Response preview: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
            );
          }
        } else {
          debugPrint(
            '⚠️ Model $model trả về nhưng không có candidates sau ${elapsed}s',
          );
          debugPrint(
            '📄 Response body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
          );
        }
      } else {
        debugPrint(
          '⚠️ Gemini error (${response.statusCode}) model=$model sau ${elapsed}s: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
        );
      }

      // Nếu đến đây nghĩa là response không hợp lệ (đã có elapsed ở trên)
      debugPrint('⚠️ Model $model không trả về dữ liệu hợp lệ sau ${elapsed}s');
      return null;
    } on TimeoutException {
      final elapsed = DateTime.now().difference(startTime).inSeconds;
      debugPrint(
        '⏱️ Timeout khi gọi model $model sau ${elapsed}s (timeout limit: ${_requestTimeout.inSeconds}s)',
      );
      return null;
    } catch (e, stack) {
      final elapsed = DateTime.now().difference(startTime).inSeconds;
      debugPrint('⚠️ Gemini request failed for $model sau ${elapsed}s: $e');
      debugPrint('Stack: $stack');
      return null;
    }
  }

  List<AIActivitySuggestion> _parseResponse(
    String response, {
    required String tripId,
    required Trip trip,
    required Map<String, TripItem> tripItemsByKey,
  }) {
    try {
      final jsonString = _extractJsonBlock(response);
      if (jsonString == null || jsonString.trim().isEmpty) {
        debugPrint('⚠️ Không tìm thấy JSON trong phản hồi AI');
        return [];
      }

      final decoded = json.decode(jsonString);
      List<dynamic> rawList;
      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map && decoded['suggestions'] is List) {
        rawList = decoded['suggestions'] as List<dynamic>;
      } else {
        debugPrint('⚠️ JSON trả về không đúng format mong muốn');
        return [];
      }

      final results = <AIActivitySuggestion>[];
      var fallbackIndex = 0;

      for (final entry in rawList) {
        if (entry is! Map) continue;

        final targetKey = entry['targetItemKey']?.toString().trim();
        final tripItem = targetKey != null ? tripItemsByKey[targetKey] : null;

        double? latitude = _parseDouble(entry['latitude']);
        double? longitude = _parseDouble(entry['longitude']);
        final address = entry['address']?.toString();
        final category = entry['category']?.toString();

        final activityName =
            entry['name']?.toString() ?? entry['activityName']?.toString();
        if (activityName == null || activityName.trim().isEmpty) {
          continue;
        }

        final suggestionId = entry['id']?.toString().trim();
        final generatedId = suggestionId != null && suggestionId.isNotEmpty
            ? suggestionId
            : 'ai_${tripId}_$fallbackIndex';

        final estimatedCost = _parseDouble(entry['estimatedCost']);
        final estimatedDuration =
            _parseInt(entry['estimatedDuration']) ??
            _parseInt(entry['duration']) ??
            90;

        final suggestion = AIActivitySuggestion(
          id: generatedId,
          tripId: tripId,
          destinationId: tripItem?.destinationId,
          activityName: activityName.trim(),
          description:
              entry['description']?.toString().trim() ??
              address ??
              'Địa điểm ăn uống được đề xuất',
          reason:
              entry['reason']?.toString().trim() ??
              'Gợi ý từ AI dựa trên vị trí gần đó',
          estimatedDuration: estimatedDuration,
          estimatedCost: estimatedCost,
          category: category,
          latitude: latitude,
          longitude: longitude,
          address: address,
          sourcePlaceId: entry['sourcePlaceId']?.toString(),
          mealType: entry['mealType']?.toString(),
          suggestedAt: DateTime.now(),
        );

        results.add(suggestion);
        fallbackIndex++;
      }

      return results;
    } catch (e, stack) {
      debugPrint('❌ Lỗi parse phản hồi AI: $e');
      debugPrint('$stack');
      return [];
    }
  }

  String? _extractJsonBlock(String response) {
    debugPrint('🔍 Full AI response length: ${response.length} chars');

    // Loại bỏ các ký tự đặc biệt không nhìn thấy được
    final cleanedResponse = response.trim();

    // Pattern 1: Tìm JSON trong code block (ưu tiên cao nhất)
    // Thử nhiều pattern khác nhau cho code block
    final patterns = [
      // Pattern 1a: Code block đầy đủ với closing ```
      RegExp(
        r'```(?:json)?\s*([\s\S]*?)```',
        dotAll: true,
        caseSensitive: false,
      ),
      // Pattern 1b: Code block không có closing ``` (response bị cắt)
      RegExp(r'```(?:json)?\s*([\s\S]*)', dotAll: true, caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(cleanedResponse);
      if (match != null) {
        final extracted = match.group(1)?.trim();
        if (extracted != null && extracted.isNotEmpty) {
          // Kiểm tra xem có phải JSON hợp lệ không
          if (extracted.startsWith('[') || extracted.startsWith('{')) {
            // Thử parse trực tiếp trước
            try {
              json.decode(extracted);
              debugPrint('✅ JSON is valid, no fix needed');
              return extracted;
            } catch (e) {
              debugPrint('⚠️ JSON invalid, attempting to fix: $e');
            }

            // Thử sửa JSON bị cắt
            String fixedJson = _fixIncompleteJson(extracted);

            // Validate lại sau khi fix
            try {
              json.decode(fixedJson);
              debugPrint(
                '✅ Fixed JSON successfully (${fixedJson.length} chars)',
              );
              return fixedJson;
            } catch (e) {
              debugPrint('❌ Cannot fix JSON: $e');
              debugPrint(
                '📝 Attempted fix: ${fixedJson.substring(0, fixedJson.length > 300 ? 300 : fixedJson.length)}',
              );

              // Fallback: Parse partial JSON - lấy các objects hoàn chỉnh
              final partialJson = _extractPartialJson(extracted);
              if (partialJson != null) {
                try {
                  json.decode(partialJson);
                  debugPrint(
                    '✅ Extracted partial JSON successfully (${partialJson.length} chars)',
                  );
                  return partialJson;
                } catch (e2) {
                  debugPrint('❌ Partial JSON also invalid: $e2');
                }
              }
            }
          }
        }
      }
    }

    // Pattern 2: Tìm JSON array trực tiếp (không có code block)
    final arrayPattern = RegExp(r'\[\s*\{[\s\S]*?\}\s*\]', dotAll: true);

    final bracketMatch = arrayPattern.firstMatch(cleanedResponse);
    if (bracketMatch != null) {
      final extracted = bracketMatch.group(0)?.trim();
      if (extracted != null && extracted.isNotEmpty) {
        debugPrint(
          '✅ Extracted JSON array directly (${extracted.length} chars)',
        );
        debugPrint(
          '📝 First 200 chars: ${extracted.substring(0, extracted.length > 200 ? 200 : extracted.length)}',
        );
        return extracted;
      }
    }

    // Pattern 3: Tìm JSON object trực tiếp
    final objectPattern = RegExp(
      r'\{[\s\S]*?"suggestions"\s*:[\s\S]*?\}',
      dotAll: true,
    );

    final objectMatch = objectPattern.firstMatch(cleanedResponse);
    if (objectMatch != null) {
      final extracted = objectMatch.group(0)?.trim();
      if (extracted != null && extracted.isNotEmpty) {
        debugPrint('✅ Extracted JSON object (${extracted.length} chars)');
        return extracted;
      }
    }

    // Nếu không tìm thấy, log chi tiết hơn
    debugPrint('❌ No JSON block found in AI response');
    debugPrint('📄 Response preview (first 1000 chars):');
    debugPrint(
      cleanedResponse.length > 1000
          ? cleanedResponse.substring(0, 1000)
          : cleanedResponse,
    );
    debugPrint('📄 Response ending (last 200 chars):');
    debugPrint(
      cleanedResponse.length > 200
          ? cleanedResponse.substring(cleanedResponse.length - 200)
          : cleanedResponse,
    );

    return null;
  }

  String _inferMealTypeFromTripItem(TripItem item) {
    final plannedTime = item.plannedTime;
    if (plannedTime == null) {
      return 'any';
    }
    final hour = plannedTime.hour;
    if (hour < 10) return 'breakfast';
    if (hour < 14) return 'lunch';
    if (hour < 17) return 'coffee';
    if (hour < 21) return 'dinner';
    return 'late-night';
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '').trim());
    }
    return null;
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String)
      return int.tryParse(value.replaceAll(RegExp(r'[^0-9-]'), ''));
    return null;
  }

  /// Extract partial JSON - lấy các objects hoàn chỉnh từ JSON bị cắt
  String? _extractPartialJson(String jsonString) {
    final trimmed = jsonString.trim();
    if (!trimmed.startsWith('[')) {
      return null; // Chỉ xử lý JSON array
    }

    try {
      // Tìm vị trí của các objects hoàn chỉnh (braceCount về 0)
      final List<int> completeObjectEnds = [];
      int braceCount = 0;
      bool inString = false;
      bool escapeNext = false;

      for (int i = 0; i < trimmed.length; i++) {
        final char = trimmed[i];

        if (escapeNext) {
          escapeNext = false;
          continue;
        }

        if (char == '\\') {
          escapeNext = true;
          continue;
        }

        if (char == '"' && !escapeNext) {
          inString = !inString;
          continue;
        }

        if (!inString) {
          if (char == '{') {
            braceCount++;
          } else if (char == '}') {
            braceCount--;
            // Nếu braceCount về 0, đây là object hoàn chỉnh
            if (braceCount == 0) {
              completeObjectEnds.add(i);
            }
          }
        }
      }

      if (completeObjectEnds.isEmpty) {
        debugPrint('⚠️ Không tìm thấy object hoàn chỉnh nào');
        return null;
      }

      // Lấy vị trí object cuối cùng hoàn chỉnh
      final lastCompleteIndex = completeObjectEnds.last;

      // Extract từ đầu đến object cuối cùng hoàn chỉnh (bao gồm cả `}`)
      String extracted = trimmed.substring(0, lastCompleteIndex + 1).trim();

      // Xóa trailing comma nếu có (sau object cuối cùng)
      extracted = extracted.trim();
      while (extracted.endsWith(',')) {
        extracted = extracted.substring(0, extracted.length - 1).trim();
      }

      // Đảm bảo có closing bracket
      if (!extracted.endsWith(']')) {
        extracted += '\n]';
      }

      debugPrint(
        '✅ Extracted ${completeObjectEnds.length} complete objects from partial JSON',
      );
      return extracted;
    } catch (e) {
      debugPrint('❌ Error extracting partial JSON: $e');
      return null;
    }
  }

  /// Sửa JSON bị cắt giữa chừng
  String _fixIncompleteJson(String json) {
    String fixed = json.trimRight();

    // Đếm số brackets
    int openBraces = 0;
    int closeBraces = 0;
    int openBrackets = 0;
    int closeBrackets = 0;
    bool inString = false;
    String? lastChar;

    for (int i = 0; i < fixed.length; i++) {
      final char = fixed[i];

      // Track string context để không đếm { } [ ] trong string
      if (char == '"' && (i == 0 || fixed[i - 1] != '\\')) {
        inString = !inString;
      }

      if (!inString) {
        if (char == '{') openBraces++;
        if (char == '}') closeBraces++;
        if (char == '[') openBrackets++;
        if (char == ']') closeBrackets++;

        if (char.trim().isNotEmpty) {
          lastChar = char;
        }
      }
    }

    debugPrint(
      '🔍 JSON structure: {open: $openBraces, close: $closeBraces}, [open: $openBrackets, close: $closeBrackets]',
    );
    debugPrint('🔍 Last non-whitespace char: "$lastChar"');

    // Xóa trailing comma hoặc ký tự lạ ở cuối
    if (lastChar == ',') {
      fixed = fixed.trimRight();
      if (fixed.endsWith(',')) {
        fixed = fixed.substring(0, fixed.length - 1).trimRight();
        debugPrint('🔧 Removed trailing comma');
      }
    }

    // Nếu đang trong string (thiếu closing quote)
    if (inString) {
      fixed += '"';
      debugPrint('🔧 Added missing closing quote');
    }

    // Đóng các object đang mở
    while (openBraces > closeBraces) {
      // Kiểm tra xem có cần thêm dấu , trước } không
      final lastMeaningfulChar = fixed
          .trimRight()[fixed.trimRight().length - 1];
      if (lastMeaningfulChar != '{' &&
          lastMeaningfulChar != ',' &&
          lastMeaningfulChar != '}') {
        // Không thêm comma nếu ký tự cuối là quote hoặc number (hợp lệ)
        // Chỉ thêm nếu thiếu
      }

      fixed += '\n  }';
      closeBraces++;
      debugPrint('🔧 Added closing brace');
    }

    // Đóng array
    while (openBrackets > closeBrackets) {
      fixed += '\n]';
      closeBrackets++;
      debugPrint('🔧 Added closing bracket');
    }

    return fixed;
  }
}
