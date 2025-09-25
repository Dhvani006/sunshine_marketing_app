# Cashfree Payment Integration - Flutter App

This guide explains the complete Cashfree payment integration implemented in the Sunshine Marketing Flutter app, following the same pattern as the sunshine website.

## 🔄 Complete Payment Flow

```
Flutter App → Backend PHP → Cashfree API → Payment Gateway → Webhook → Order Success
```

### 1. Checkout Process (`checkout_screen.dart`)
- User fills out customer details form
- App validates form data
- Creates Cashfree payment session via backend
- Navigates to Cashfree checkout screen

### 2. Payment Processing (`cashfree_web_checkout_screen.dart`)
- Opens Cashfree hosted checkout page in In-App WebView
- User completes payment on Cashfree's secure page
- App provides "Return to App" button for navigation
- Manual payment status checking available

### 3. Order Success (`order_success_screen.dart`)
- Verifies payment status with backend
- Displays payment confirmation
- Saves payment details automatically
- Provides navigation back to home

## 📁 File Structure

### Flutter App Files
```
lib/ecommerce/screens/cart/
├── checkout_screen.dart              # Main checkout form
├── cashfree_web_checkout_screen.dart # Payment processing
└── order_success_screen.dart         # Payment confirmation
```

### Backend PHP Files
```
├── cashfree_config.php               # Cashfree configuration
├── cashfree-create-session.php       # Create payment session
├── cashfree-verify-order.php         # Verify payment status
├── cashfree_webhook.php              # Handle webhooks
└── save_payment.php                  # Save payment details
```

## 🔧 Configuration

### API Configuration (`lib/api_config.dart`)
```dart
const String ngrokBaseUrl = 'https://b81a71185ea7.ngrok-free.app';
const String cashfreeOrderUrl = '$ngrokBaseUrl/cashfree-create-session.php';
const String verifyOrderUrl = '$ngrokBaseUrl/cashfree-verify-order.php';
const String savePaymentUrl = '$ngrokBaseUrl/save_payment.php';
```

### Cashfree Configuration (`cashfree_config.php`)
```php
define('CF_ENVIRONMENT', 'TEST');  // Change to 'PRODUCTION' for live
define('CF_CLIENT_ID', 'your_client_id');
define('CF_CLIENT_SECRET', 'your_client_secret');
```

## 🚀 Implementation Details

### 1. Session Creation
- **Endpoint**: `cashfree-create-session.php`
- **Method**: POST
- **API Version**: 2023-08-01
- **Response**: `order_id`, `payment_session_id`, `checkout_url`

### 2. Payment Processing
- **URL Format**: `https://sandbox.cashfree.com/pg/checkout/{payment_session_id}`
- **Launch Mode**: `LaunchMode.inAppWebView`
- **User Experience**: In-app WebView for seamless payment

### 3. Payment Verification
- **Endpoint**: `cashfree-verify-order.php`
- **Method**: GET with query parameter
- **Response**: Payment status, order details, customer info

### 4. Webhook Handling
- **Endpoint**: `cashfree_webhook.php`
- **Purpose**: Real-time payment status updates
- **Database**: Updates order and payment records

## 🔄 Payment Flow Steps

### Step 1: Checkout Form
```dart
// User fills form and clicks "Proceed to Payment"
final sessionResponse = await http.post(
  Uri.parse(ApiConfig.cashfreeOrderUrl),
  headers: {'Content-Type': 'application/json'},
  body: json.encode({
    'order_amount': widget.grandTotal,
    'customer_id': 'cust_${widget.userId}',
    'customer_name': _nameController.text.trim(),
    'customer_email': _emailController.text.trim(),
    'customer_phone': _phoneController.text.trim(),
  }),
);
```

### Step 2: Payment Session Creation
```php
// Backend creates Cashfree order
$orderData = [
    'order_id' => 'CF_' . time() . '_' . substr(sha1(uniqid('', true)), 0, 8),
    'order_amount' => (float)number_format($orderAmount, 2, '.', ''),
    'order_currency' => 'INR',
    'customer_details' => [...],
    'order_meta' => [
        'return_url' => 'https://b81a71185ea7.ngrok-free.app/cashfree_return_url.php'
    ]
];
```

### Step 3: Payment Gateway
```dart
// Open Cashfree checkout in WebView
final checkoutUrl = 'https://sandbox.cashfree.com/pg/checkout/$paymentSessionId';
final Uri uri = Uri.parse(checkoutUrl);
await launchUrl(uri, mode: LaunchMode.inAppWebView);
```

### Step 4: Payment Verification
```dart
// Verify payment status
final response = await http.get(
  Uri.parse('${ApiConfig.verifyOrderUrl}?order_id=${widget.orderId}'),
);
```

### Step 5: Order Success
```dart
// Display success screen with order details
OrderSuccessScreen(
  orderId: cashfreeOrderId,
  paymentSessionId: paymentSessionId,
)
```

## 🛠️ Testing

### Test Environment
- **Environment**: Sandbox
- **Base URL**: `https://sandbox.cashfree.com`
- **Test Cards**: Use Cashfree test card numbers

### Test Flow
1. Add items to cart
2. Proceed to checkout
3. Fill customer details
4. Click "Proceed to Payment"
5. Complete payment on Cashfree page
6. Return to app
7. Verify order success screen

## 🔒 Security Features

### 1. HTTPS Only
- All API calls use HTTPS
- Secure payment processing

### 2. Input Validation
- Form validation on frontend
- Server-side validation on backend

### 3. Error Handling
- Comprehensive error messages
- Graceful fallbacks
- User-friendly error display

## 📱 User Experience

### 1. Seamless Integration
- In-app WebView for payment
- No external browser redirects
- Consistent UI/UX

### 2. Real-time Updates
- Payment status verification
- Automatic order confirmation
- Webhook-based updates

### 3. Error Recovery
- Retry mechanisms
- Clear error messages
- Fallback options

## 🚨 Troubleshooting

### Common Issues

1. **Payment Session Creation Failed**
   - Check Cashfree credentials
   - Verify API version (2023-08-01)
   - Check network connectivity

2. **Payment Verification Failed**
   - Wait for Cashfree processing
   - Check order ID format
   - Verify backend endpoint

3. **WebView Not Opening**
   - Check URL format
   - Verify LaunchMode.inAppWebView
   - Test on physical device

### Debug Steps
1. Check console logs
2. Verify API responses
3. Test with Cashfree dashboard
4. Check webhook logs

## 📋 Production Checklist

- [ ] Change environment to PRODUCTION
- [ ] Update Cashfree credentials
- [ ] Test with real payment methods
- [ ] Configure webhook URLs
- [ ] Set up SSL certificates
- [ ] Test error scenarios
- [ ] Monitor payment logs

## 🔗 Related Files

- `sunshine_website/sunshine_marketing/` - Reference website implementation
- `CASHFREE_NEW_API_INTEGRATION.md` - API integration details
- `PAYMENT_ISSUE_SOLUTION.md` - Troubleshooting guide
- `CHECKOUT_SYSTEM_SUMMARY.md` - System overview

## 📞 Support

For issues or questions:
1. Check this documentation
2. Review error logs
3. Test with Cashfree sandbox
4. Contact development team

---

**Last Updated**: December 2024
**Version**: 1.0
**Status**: Production Ready
