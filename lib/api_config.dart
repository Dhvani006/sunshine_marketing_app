import 'config/cashfree_config.dart';

// Use secure configuration
const String baseUrl = CashfreeConfig.baseUrl;
const String webSocketUrl = 'ws://192.168.56.69';
const String uploadsUrl = '$baseUrl/uploads/';

// Cashfree Integration URLs - Use secure configuration
const String cashfreeReturnUrl = '${CashfreeConfig.ngrokUrl}/cashfree_return_url.php';
const String cashfreeWebhookUrl = '${CashfreeConfig.ngrokUrl}/cashfree_webhook.php';
    
// ✅ Updated endpoints to use secure configuration
const String cashfreeOrderUrl = '$baseUrl/cashfree-create-session.php';
const String savePaymentUrl = '$baseUrl/save_payment.php';
const String verifyOrderUrl = '$baseUrl/cashfree-verify-order.php';
const String cashfreeUpdateOrderStatusUrl = '$baseUrl/cashfree_update_order_status.php';
