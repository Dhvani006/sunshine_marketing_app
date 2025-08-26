# Cashfree Checkout Flow - Sunshine Marketing App

## Overview
This document explains the new Cashfree in-app checkout implementation that replaces the problematic WebView approach.

## File Structure

### 1. `checkout_screen.dart` (Main Checkout Form)
- **Purpose**: Collects customer details (name, email, phone, address)
- **Function**: Creates a local order and navigates to Cashfree payment
- **Navigation**: Goes to `CashfreeInAppCheckoutScreen`

### 2. `cashfree_inapp_checkout_screen.dart` (NEW - Cashfree SDK Integration)
- **Purpose**: Handles Cashfree payment using the official SDK
- **Function**: Creates payment session and processes payment in-app
- **Advantages**: 
  - No WebView issues
  - Native app experience
  - Better error handling
  - Automatic payment status updates

### 3. `cashfree_web_checkout_screen.dart` (Legacy - WebView Approach)
- **Purpose**: WebView-based Cashfree checkout
- **Status**: Currently not in use (kept for reference)
- **Issues**: WebView navigation problems, external browser dependency

### 4. `direct_payment_screen.dart` (Legacy - Custom Form)
- **Purpose**: Custom payment form as workaround
- **Status**: Currently not in use (kept for reference)

## New Navigation Flow

```
Cart → CheckoutScreen → CashfreeInAppCheckoutScreen → PaymentSuccessScreen
```

## Setup Instructions

### 1. Update pubspec.yaml
The `flutter_cashfree_pg_sdk` dependency has been re-enabled:
```yaml
flutter_cashfree_pg_sdk: ^2.2.9+47
```

### 2. Configure Cashfree Credentials
Edit `lib/cashfree_config.dart`:
```dart
// Replace these with your actual Cashfree credentials
static const String testAppId = 'YOUR_TEST_APP_ID';
static const String testClientId = 'YOUR_TEST_CLIENT_ID';
static const String testClientSecret = 'YOUR_TEST_CLIENT_SECRET';

// For production
static const String productionAppId = 'YOUR_PROD_APP_ID';
static const String productionClientId = 'YOUR_PROD_CLIENT_ID';
static const String productionClientSecret = 'YOUR_PROD_CLIENT_SECRET';
```

### 3. Environment Configuration
Change the environment in `lib/cashfree_config.dart`:
```dart
// Change to 'PROD' for production
static const String environment = 'TEST';
```

## How It Works

### 1. Order Creation
- User fills checkout form in `CheckoutScreen`
- Local order is created with generated order ID
- User is navigated to `CashfreeInAppCheckoutScreen`

### 2. Payment Session Creation
- `CashfreeInAppCheckoutScreen` calls your backend (`cashfree_order.php`)
- Backend creates payment session with Cashfree
- Returns payment session ID

### 3. Payment Processing
- Cashfree SDK is initialized
- Payment parameters are prepared
- `CashfreePGSDK.doPayment()` is called
- User sees native Cashfree payment UI

### 4. Payment Result Handling
- Payment result is received from SDK
- Payment status is checked
- Payment details are saved to database
- User is redirected to success screen

## Backend Requirements

Your backend needs these endpoints:

### 1. `cashfree_order.php`
Creates a payment session with Cashfree:
```json
POST /cashfree_order.php
{
  "orderId": "ORDER_123",
  "orderAmount": "100.00",
  "orderCurrency": "INR",
  "customerName": "John Doe",
  "customerPhone": "9876543210",
  "customerEmail": "john@example.com"
}
```

Response:
```json
{
  "status": "SUCCESS",
  "payment_session_id": "session_abc123"
}
```

### 2. `save_payment.php`
Saves payment details after successful payment:
```json
POST /save_payment.php
{
  "user_id": 123,
  "order_id": 456,
  "payment_method": "Cashfree",
  "amount": 100.00,
  "payment_status": "Success",
  "transaction_id": "CF_789"
}
```

## Testing

### Test Environment
- Use test credentials from Cashfree
- Test with small amounts (₹1)
- Use test UPI IDs and card numbers

### Production Environment
- Change environment to 'PROD' in config
- Use production credentials
- Test with real payment methods

## Troubleshooting

### Common Issues

1. **SDK Initialization Failed**
   - Check Cashfree credentials
   - Verify app permissions
   - Check internet connection

2. **Payment Session Creation Failed**
   - Verify backend endpoint
   - Check Cashfree API credentials
   - Verify request format

3. **Payment Processing Failed**
   - Check payment parameters
   - Verify session ID
   - Check Cashfree account status

### Debug Information
The app provides extensive logging:
- Check console for detailed logs
- Look for "===" sections in logs
- Verify each step completion

## Migration from Old Flow

If you want to use the old WebView approach:

1. Update `checkout_screen.dart` to navigate to `CashfreeWebCheckoutScreen`
2. Ensure WebView dependencies are properly configured
3. Test WebView functionality on target devices

## Benefits of New Approach

1. **No WebView Issues**: Native SDK integration
2. **Better UX**: Seamless in-app experience
3. **Reliable**: Official SDK with proper error handling
4. **Maintainable**: Cleaner code structure
5. **Scalable**: Easy to add new payment methods

## Next Steps

1. **Get Cashfree Credentials**: Contact Cashfree for test/production credentials
2. **Update Configuration**: Replace placeholder values in `cashfree_config.dart`
3. **Test Integration**: Test with test credentials
4. **Backend Setup**: Ensure backend endpoints are working
5. **Go Live**: Switch to production environment when ready
