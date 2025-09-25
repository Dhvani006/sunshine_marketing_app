// lib/config/cashfree_config.dart
class CashfreeConfig {
  // Use environment variables or build-time configuration
  static const String appId = String.fromEnvironment(
    'CASHFREE_APP_ID',
    defaultValue: 'CF_CLIENT_ID_TEST', // Safe placeholder for development
  );
  
  static const String secretKey = String.fromEnvironment(
    'CASHFREE_SECRET_KEY',
    defaultValue: 'CF_CLIENT_SECRET_TEST', // Safe placeholder for development
  );
  
  static const String environment = String.fromEnvironment(
    'CASHFREE_ENVIRONMENT',
    defaultValue: 'sandbox',
  );
  
  // API Configuration
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.27.5/sunshine_marketing_app_backend',
  );
  
  static const String ngrokUrl = String.fromEnvironment(
    'NGROK_URL',
    defaultValue: 'https://b81a71185ea7.ngrok-free.app/sunshine_marketing_app',
  );
  
  // Validation
  static bool get isConfigured => 
      appId.isNotEmpty && 
      secretKey.isNotEmpty && 
      !appId.startsWith('CF_CLIENT_ID') &&
      !secretKey.startsWith('CF_CLIENT_SECRET');
  
  // Environment checks
  static bool get isSandbox => environment.toLowerCase() == 'sandbox';
  static bool get isProduction => environment.toLowerCase() == 'production';
}
