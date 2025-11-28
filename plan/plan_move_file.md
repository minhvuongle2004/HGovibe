# Kế hoạch di chuyển & tái cấu trúc thư mục `lib/`

## 0. Chuẩn bị trước khi di chuyển
- [ ] Tạo nhánh mới `refactor/folder-structure` từ `main`.
- [ ] Chạy `flutter clean` (nếu workspace đang bị lỗi build).
- [ ] Chạy `flutter test` để xác nhận trạng thái hiện tại pass, lưu log.
- [ ] Dùng `tree` hoặc ghi chú lại cấu trúc `lib/` hiện tại (đề phòng rollback).
- [ ] Bật `analysis_options` để cảnh báo import lỗi ngay khi move file.

## 1. Tạo trước cây thư mục mới (tránh lỗi khi move)
- [ ] Tạo các thư mục cấp 2/3 cần dùng (có thể script mkdir hàng loạt):
  - `lib/app`
  - `lib/config/api`, `lib/config/auth`, `lib/config/theme`
  - `lib/models/trips`, `lib/models/destinations`, `lib/models/ai`, `lib/models/users`, `lib/models/maps`, `lib/models/weather`
  - `lib/providers/trips`, `lib/providers/ai`, `lib/providers/favorites`, `lib/providers/auth`
  - `lib/services/ai`, `lib/services/maps`, `lib/services/trips`, `lib/services/destinations`, `lib/services/auth`, `lib/services/utils`
  - `lib/screens/trips/trip_detail/widgets`, `lib/screens/destinations`, `lib/screens/auth`, `lib/screens/home`, `lib/screens/account`
  - `lib/widgets/common`, `lib/widgets/trips`, `lib/widgets/destinations`, `lib/widgets/ai`
  - `lib/utils` (giữ), bổ sung `lib/utils/formatters.dart`, `lib/utils/validators.dart` nếu cần
- [ ] Đảm bảo thư mục rỗng có `.gitkeep` nếu cần (để tránh Git bỏ qua).

## 2. Di chuyển theo từng nhóm file (ưu tiên model → service → provider → screen)

### 2.1 Models
- [ ] `trip.dart`, `trip_item.dart`, `trip_cost_estimate.dart` → `models/trips/`
- [ ] `destination.dart`, `favorite_destination.dart` → `models/destinations/`
- [ ] `ai_activity_suggestion.dart`, `ai_plan.dart` → `models/ai/`
- [ ] `app_user.dart` → `models/users/`
- [ ] `mapbox_place.dart` → `models/maps/`
- [ ] `weather_forecast.dart` → `models/weather/`
- [ ] Sau mỗi move, cập nhật import trong các file sử dụng (bằng `search & replace`).
- [ ] Chạy `dart format lib/models`.

### 2.2 Services
- [ ] Gom toàn bộ file AI (`ai_place_recommendation_service.dart`, `ai_destination_service.dart`, `ai_destination_builder.dart`, `ai_destination_validator.dart`, `ai_plan_service.dart`) → `services/ai/`
- [ ] `mapbox_service.dart`, `geolocation_service.dart` → `services/maps/`
- [ ] `trip_service.dart`, `trip_cost_service.dart` (nếu có) → `services/trips/`
- [ ] `auth_service.dart`, `user_service.dart` → `services/auth/`
- [ ] `destination_service.dart`, `favorites_service.dart` → `services/destinations/`
- [ ] `logging_service.dart`, helper dùng chung → `services/utils/`
- [ ] Sau mỗi nhóm, cập nhật import + chạy `dart format`.

### 2.3 Providers
- [ ] `trip_provider.dart` → `providers/trips/trip_provider.dart`
- [ ] `destination_provider.dart` → `providers/destinations/destination_provider.dart` (nếu cần tách, tạo folder)
- [ ] `favorites_provider.dart` → `providers/favorites/`
- [ ] `auth_form_provider.dart`, `user_provider.dart` → `providers/auth/`
- [ ] Nếu có provider riêng cho AI, move vào `providers/ai/`
- [ ] Update import ở các screen/widgets liên quan.

### 2.4 Screens
- [ ] Tạo cấu trúc:
  - `screens/trips/trips_screen.dart`
  - `screens/trips/trip_detail/trip_detail_screen.dart`
  - `screens/trips/trip_detail/widgets/` (move `ai_suggestion_card.dart`, `ai_suggestion_tab.dart`, `trip_timeline_section.dart`… nếu gắn với màn này)
  - `screens/trips/create_trip_screen.dart`, `screens/trips/edit_trip_screen.dart`, `screens/trips/edit_trip_item_screen.dart`, `screens/trips/add_destinations_to_trip_screen.dart`
  - `screens/destinations/destination_detail_screen.dart`, `screens/destinations/favorites_screen.dart`
  - `screens/auth/login_screen.dart`, `register_screen.dart`, `forgot_password_screen.dart`
  - `screens/home/home_screen.dart`, `map_screen.dart`, `sale_screen.dart`
  - `screens/account/account_screen.dart`
- [ ] Khi move, nhớ cập nhật import tới widget/provider/service mới.
- [ ] Chạy `dart format lib/screens`.

### 2.5 Widgets
- [ ] Chia `widgets/` thành:
  - `widgets/common/` (button, card chung)
  - `widgets/trips/` (cost breakdown, timeline item…)
  - `widgets/ai/` (ai_plan_viewer, ai_suggestion_card nếu dùng ở nhiều nơi)
  - `widgets/destinations/` (destination card, rating badge…)
- [ ] Nếu widget chỉ phục vụ screen cụ thể (ví dụ Trip Detail), cân nhắc move vào `screens/trips/trip_detail/widgets/` thay vì `widgets`.

### 2.6 Config & Utils
- [ ] `api_config.dart` → `config/api/api_config.dart`
- [ ] `social_login_config.dart` → `config/auth/social_login_config.dart`
- [ ] Nếu có theme, route config → `config/theme/`, `app/routes.dart`
- [ ] `utils/constants.dart`, `utils/import_data.dart` → giữ hoặc split thành `formatters.dart`, `validators.dart` nếu cần.

## 3. Cập nhật import & kiểm tra
- [ ] Sử dụng `dart fix --apply` hoặc VSCode multi-cursor để sửa import bị lỗi.
- [ ] Ưu tiên import dạng `package:smart_travel_app/...`.
- [ ] Chạy `dart format lib`.
- [ ] Chạy `flutter analyze` để phát hiện import hỏng.
- [ ] Chạy `flutter test` toàn bộ.

## 4. Verification thủ công
- [ ] Run app trên simulator/emulator kiểm tra:
  - Trang Trips, Trip Detail, AI Suggestions hoạt động.
  - Các màn màn Auth, Destination Detail load đúng.
- [ ] Mở log xem có error import/asset nào không.

## 5. Cleanup & Commit
- [ ] Xóa thư mục cũ nếu rỗng sau khi move (tránh folder trống).
- [ ] Đảm bảo `.gitignore` không chặn folder mới.
- [ ] Commit từng bước lớn (ví dụ `chore: move models`, `chore: move services`) hoặc 1 commit lớn cuối cùng tùy ý, nhưng ghi rõ trong message.
- [ ] Cập nhật `README.md` hoặc `docs/` mô tả cấu trúc mới (nếu cần).
- [ ] Mở PR, mô tả chi tiết những thay đổi + cách test.

## 6. Lưu ý lỗi thường gặp & cách xử lý
- Import vòng (circular) sau khi move:
  - Dời helper vào `core/utils`.
  - Dùng interface để tách dependency.
- File reference asset (ảnh/json) bị sai đường dẫn:
  - Update path trong `pubspec.yaml` và code.
- Test không tìm thấy file mock:
  - Cập nhật path trong thư mục `test/`.
- Build fail do `part '...'`:
  - Update đường dẫn trong các file `part`/`part of`.

Hoàn thành checklist này rồi hãy tiến hành di chuyển thực tế để tránh lỗi khó tìm nhé!

