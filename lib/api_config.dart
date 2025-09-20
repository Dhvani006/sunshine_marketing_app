const String baseUrl = 'http://192.168.56.69/sunshine_marketing_app_backend';
const String webSocketUrl = 'ws://192.168.56.69';
const String uploadsUrl =
    'http://192.168.56.69/sunshine_marketing_app_backend/uploads/';

// Cashfree Integration URLs - Use YOUR APP BACKEND
const String cashfreeReturnUrl = '$baseUrl/cashfree_return_url.php';
const String cashfreeWebhookUrl = 'https://ad797d09e91d.ngrok-free.app/sunshine_marketing_app_backend/cashfree_webhook.php';
    
// ✅ Updated endpoints to use YOUR APP BACKEND
const String cashfreeOrderUrl = '$baseUrl/cashfree-create-session.php';
const String savePaymentUrl = '$baseUrl/save_payment.php';
const String verifyOrderUrl = '$baseUrl/cashfree-verify-order.php';
const String cashfreeUpdateOrderStatusUrl = '$baseUrl/cashfree_update_order_status.php';
