import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hackathon_salvara/core/network/dio_client.dart';
import 'package:hackathon_salvara/core/storage/token_storage.dart';

/// Provides the [FlutterSecureStorage] singleton.
///
/// resetOnError: true — if the keystore is corrupted or inaccessible (common
/// on some vivo/OPPO/Xiaomi devices), the storage resets instead of hanging.
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  ),
);

/// Provides the [TokenStorage] wrapper.
final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(ref.watch(secureStorageProvider)),
);

/// Provides the configured [Dio] client.
final dioProvider = Provider<Dio>(
  (ref) => buildDioClient(ref.watch(tokenStorageProvider)),
);
