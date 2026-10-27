import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../error/exceptions.dart';
import '../storage/local_storage.dart';

/// HTTP Client communicating with the SURUH Django REST Framework API.
///
/// Configured to connect to the backend container at `suruh_backend/compose.yaml` (port 8019).
/// Handles JWT Bearer authentication, auto token refresh, and Pontianak service calls.
class SuruhApiClient {
  SuruhApiClient({
    required LocalStorage storage,
    http.Client? httpClient,
  })  : _storage = storage,
        _client = httpClient ?? http.Client();

  final LocalStorage _storage;
  final http.Client _client;

  // Storage keys for JWT tokens
  static const String kAccessToken = 'suruh_jwt_access_token';
  static const String kRefreshToken = 'suruh_jwt_refresh_token';
  static const String kCachedProfile = 'suruh_cached_user_profile';

  String get baseUrl => AppConfig.instance.apiBaseUrl;

  String? get accessToken => _storage.getString(kAccessToken);
  String? get refreshToken => _storage.getString(kRefreshToken);

  Future<void> saveTokens({required String access, required String refresh}) async {
    await _storage.setString(kAccessToken, access);
    await _storage.setString(kRefreshToken, refresh);
  }

  Future<void> clearTokens() async {
    await _storage.remove(kAccessToken);
    await _storage.remove(kRefreshToken);
    await _storage.remove(kCachedProfile);
  }

  bool get isAuthenticated => accessToken != null && accessToken!.isNotEmpty;

  // ---------------------------------------------------------------------------
  // Core HTTP Request Pipeline with JWT & Retry
  // ---------------------------------------------------------------------------

  Future<dynamic> request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
    bool isRetry = false,
  }) async {
    final String cleanPath = path.startsWith('/') ? path : '/$path';
    Uri uri = Uri.parse('$baseUrl$cleanPath');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };

    if (requiresAuth && accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    http.Response response;
    try {
      final String? encodedBody = body != null ? jsonEncode(body) : null;
      developer.log('[$method] $uri', name: 'SuruhApiClient');

      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(uri, headers: headers).timeout(
                const Duration(seconds: 15),
              );
          break;
        case 'POST':
          response = await _client.post(uri, headers: headers, body: encodedBody).timeout(
                const Duration(seconds: 20),
              );
          break;
        case 'PATCH':
          response = await _client.patch(uri, headers: headers, body: encodedBody).timeout(
                const Duration(seconds: 20),
              );
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: headers, body: encodedBody).timeout(
                const Duration(seconds: 15),
              );
          break;
        default:
          throw UnsupportedError('Unsupported HTTP method: $method');
      }
    } on TimeoutException {
      throw const NetworkException('Koneksi ke server SURUH waktu habis (timeout). Periksa compose.yaml backend.');
    } catch (e) {
      developer.log('Network error on $uri: $e', name: 'SuruhApiClient', error: e);
      throw NetworkException(
        'Gagal terhubung ke backend SURUH ($baseUrl). Pastikan docker compose aktif.',
        e,
      );
    }

    // Auto-refresh token on 401 Unauthorized
    if (response.statusCode == 401 && requiresAuth && !isRetry && refreshToken != null) {
      final bool refreshed = await _tryRefreshToken();
      if (refreshed) {
        return request(
          method: method,
          path: path,
          body: body,
          queryParams: queryParams,
          requiresAuth: requiresAuth,
          isRetry: true,
        );
      } else {
        await clearTokens();
        throw const AuthException('Sesi login telah berakhir. Silakan masuk kembali.');
      }
    }

    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        decoded = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final String errorMessage = _extractErrorMessage(decoded, response.statusCode);

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AuthException(errorMessage);
    }
    if (response.statusCode == 404) {
      throw NotFoundException(errorMessage);
    }
    throw ServerException(errorMessage);
  }

  String _extractErrorMessage(dynamic decoded, int statusCode) {
    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('detail')) {
        return decoded['detail'].toString();
      }
      if (decoded.containsKey('error')) {
        return decoded['error'].toString();
      }
      if (decoded.containsKey('message')) {
        return decoded['message'].toString();
      }
      // DRF field validation errors: e.g. {"phone_number": ["Nomor tidak valid"]}
      final List<String> fieldErrors = <String>[];
      decoded.forEach((String key, dynamic value) {
        if (value is List) {
          fieldErrors.add('$key: ${value.join(", ")}');
        } else if (value is String) {
          fieldErrors.add('$key: $value');
        }
      });
      if (fieldErrors.isNotEmpty) {
        return fieldErrors.join(' | ');
      }
    }
    return 'Terjadi kesalahan pada server SURUH (HTTP $statusCode)';
  }

  Future<bool> _tryRefreshToken() async {
    final String? refresh = refreshToken;
    if (refresh == null) return false;

    try {
      final Uri uri = Uri.parse('$baseUrl/api/v1/auth/token/refresh/');
      final http.Response res = await _client.post(
        uri,
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, String>{'refresh': refresh}),
      );
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final String? newAccess = data['access'] as String?;
        if (newAccess != null) {
          await _storage.setString(kAccessToken, newAccess);
          final String? newRefresh = data['refresh'] as String?;
          if (newRefresh != null) {
            await _storage.setString(kRefreshToken, newRefresh);
          }
          return true;
        }
      }
    } catch (e) {
      developer.log('Token refresh failed: $e', name: 'SuruhApiClient');
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Accounts / Authentication Endpoints (/api/v1/auth/)
  // ---------------------------------------------------------------------------

  /// Login using phone number (or email) and password.
  Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
  }) async {
    final Map<String, dynamic> response = await request(
      method: 'POST',
      path: '/api/v1/auth/login/',
      body: <String, dynamic>{
        'phone_number': phoneNumber,
        'password': password,
      },
      requiresAuth: false,
    ) as Map<String, dynamic>;

    if (response['tokens'] != null) {
      final Map<String, dynamic> tokens = response['tokens'] as Map<String, dynamic>;
      await saveTokens(
        access: tokens['access'] as String,
        refresh: tokens['refresh'] as String,
      );
    }
    if (response['user'] != null) {
      await _storage.writeJson(kCachedProfile, response['user'] as Map<String, dynamic>);
    }

    return response;
  }

  /// Register a new user in the SURUH platform.
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String phoneNumber,
    required String password,
    String? email,
    String role = 'customer',
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'full_name': fullName,
      'phone_number': phoneNumber,
      'password': password,
      'role': role,
    };
    if (email != null && email.trim().isNotEmpty) {
      body['email'] = email.trim();
    }

    final Map<String, dynamic> response = await request(
      method: 'POST',
      path: '/api/v1/auth/register/',
      body: body,
      requiresAuth: false,
    ) as Map<String, dynamic>;

    if (response['tokens'] != null) {
      final Map<String, dynamic> tokens = response['tokens'] as Map<String, dynamic>;
      await saveTokens(
        access: tokens['access'] as String,
        refresh: tokens['refresh'] as String,
      );
    }
    if (response['user'] != null) {
      await _storage.writeJson(kCachedProfile, response['user'] as Map<String, dynamic>);
    }

    return response;
  }

  /// Fetches authenticated user profile from /api/v1/auth/profile/
  Future<Map<String, dynamic>> getProfile() async {
    final Map<String, dynamic> response = await request(
      method: 'GET',
      path: '/api/v1/auth/profile/',
      requiresAuth: true,
    ) as Map<String, dynamic>;

    await _storage.writeJson(kCachedProfile, response);
    return response;
  }

  /// Logout and invalidate refresh token on backend.
  Future<void> logout() async {
    try {
      final String? refresh = refreshToken;
      if (refresh != null) {
        await request(
          method: 'POST',
          path: '/api/v1/auth/logout/',
          body: <String, String>{'refresh_token': refresh},
          requiresAuth: true,
        );
      }
    } catch (e) {
      developer.log('Logout notification to backend failed: $e', name: 'SuruhApiClient');
    } finally {
      await clearTokens();
    }
  }

  // ---------------------------------------------------------------------------
  // Services Endpoints (/api/v1/services/)
  // ---------------------------------------------------------------------------

  /// Fetches active public service categories.
  Future<List<dynamic>> getCategories() async {
    final dynamic response = await request(
      method: 'GET',
      path: '/api/v1/services/categories/',
      requiresAuth: false,
    );

    if (response is List) return response;
    if (response is Map && response['results'] is List) {
      return response['results'] as List<dynamic>;
    }
    return const <dynamic>[];
  }

  /// Fetches active public services. Optionally filtered by category slug.
  Future<List<dynamic>> getServices({String? categorySlug}) async {
    final Map<String, String>? params =
        categorySlug != null ? <String, String>{'category': categorySlug} : null;

    final dynamic response = await request(
      method: 'GET',
      path: '/api/v1/services/services/',
      queryParams: params,
      requiresAuth: false,
    );

    if (response is List) return response;
    if (response is Map && response['results'] is List) {
      return response['results'] as List<dynamic>;
    }
    return const <dynamic>[];
  }

  /// Fetches detailed service configuration by slug.
  Future<Map<String, dynamic>> getServiceDetail(String slug) async {
    final dynamic response = await request(
      method: 'GET',
      path: '/api/v1/services/services/$slug/',
      requiresAuth: false,
    );
    return response as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Pricing Endpoints (/api/v1/pricing/)
  // ---------------------------------------------------------------------------

  /// Estimates price breakdown using the SURUH dynamic pricing engine.
  Future<Map<String, dynamic>> estimatePrice({
    String? serviceId,
    double distanceKm = 0.0,
    double durationMinutes = 0.0,
    int quantity = 1,
    double additionalFees = 0.0,
    double? customQuotedPrice,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'distance_km': distanceKm,
      'duration_minutes': durationMinutes,
      'quantity': quantity,
      'additional_fees': additionalFees,
    };
    if (serviceId != null) body['service_id'] = serviceId;
    if (customQuotedPrice != null) body['custom_quoted_price'] = customQuotedPrice;

    final dynamic response = await request(
      method: 'POST',
      path: '/api/v1/pricing/estimate/',
      body: body,
      requiresAuth: false,
    );
    return response as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Orders Endpoints (/api/v1/orders/)
  // ---------------------------------------------------------------------------

  /// Fetches orders for current customer.
  Future<List<dynamic>> getOrders() async {
    final dynamic response = await request(
      method: 'GET',
      path: '/api/v1/orders/',
      requiresAuth: true,
    );

    if (response is List) return response;
    if (response is Map && response['results'] is List) {
      return response['results'] as List<dynamic>;
    }
    return const <dynamic>[];
  }

  /// Creates a new order on the SURUH backend.
  Future<Map<String, dynamic>> createOrder({
    String? serviceId,
    bool isCustomRequest = false,
    String? customRequestTitle,
    Map<String, dynamic>? instructionData,
    Map<String, dynamic>? pickupData,
    Map<String, dynamic>? destinationData,
    DateTime? scheduledAt,
    String? customerNote,
    double distanceKm = 0.0,
    double durationMinutes = 0.0,
    int quantity = 1,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'is_custom_request': isCustomRequest,
      'instruction_data': instructionData ?? <String, dynamic>{},
      'distance_km': distanceKm,
      'duration_minutes': durationMinutes,
      'quantity': quantity,
    };
    if (serviceId != null) body['service_id'] = serviceId;
    if (customRequestTitle != null) body['custom_request_title'] = customRequestTitle;
    if (pickupData != null) body['pickup_data'] = pickupData;
    if (destinationData != null) body['destination_data'] = destinationData;
    if (scheduledAt != null) body['scheduled_at'] = scheduledAt.toIso8601String();
    if (customerNote != null) body['customer_note'] = customerNote;

    final dynamic response = await request(
      method: 'POST',
      path: '/api/v1/orders/',
      body: body,
      requiresAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  /// Retrieves full order detail including driver, status history, and bids.
  Future<Map<String, dynamic>> getOrderDetail(String orderNumber) async {
    final dynamic response = await request(
      method: 'GET',
      path: '/api/v1/orders/$orderNumber/',
      requiresAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  /// Cancels an existing order.
  Future<Map<String, dynamic>> cancelOrder(String orderNumber, {required String reason}) async {
    final dynamic response = await request(
      method: 'POST',
      path: '/api/v1/orders/$orderNumber/cancel/',
      body: <String, String>{'cancellation_reason': reason},
      requiresAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  /// Accepts a driver bid quote.
  Future<Map<String, dynamic>> acceptQuote(String orderNumber, {required String bidId}) async {
    final dynamic response = await request(
      method: 'POST',
      path: '/api/v1/orders/$orderNumber/accept-quote/',
      body: <String, String>{'bid_id': bidId},
      requiresAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Driver / Mitra Endpoints (/api/v1/driver/)
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> getDriverAvailableOrders() async {
    final dynamic response = await request(
      method: 'GET',
      path: '/api/v1/driver/orders/available/',
      requiresAuth: true,
    );
    if (response is List) return response;
    if (response is Map && response['results'] is List) {
      return response['results'] as List<dynamic>;
    }
    return const <dynamic>[];
  }

  Future<Map<String, dynamic>> claimOrder(String orderNumber) async {
    final dynamic response = await request(
      method: 'POST',
      path: '/api/v1/driver/orders/$orderNumber/claim/',
      requiresAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitBid(
    String orderNumber, {
    required double bidPrice,
    String? notes,
  }) async {
    final dynamic response = await request(
      method: 'POST',
      path: '/api/v1/driver/orders/$orderNumber/bid/',
      body: <String, dynamic>{
        'bid_price': bidPrice,
        if (notes != null) 'notes': notes,
      },
      requiresAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> advanceOrderStatus(
    String orderNumber, {
    required String targetStatus,
    String? notes,
  }) async {
    final dynamic response = await request(
      method: 'POST',
      path: '/api/v1/driver/orders/$orderNumber/advance-status/',
      body: <String, dynamic>{
        'target_status': targetStatus,
        if (notes != null) 'notes': notes,
      },
      requiresAuth: true,
    );
    return response as Map<String, dynamic>;
  }
}
