# Cashfree Payment Gateway Integration

This document provides step-by-step instructions for integrating Cashfree payment gateway into your Sunshine Marketing Flutter app.

## 🚀 Quick Start

### 1. Install Dependencies

Run the following command to install the Cashfree Flutter SDK:

```bash
flutter pub get
```

### 2. Backend Setup

#### Copy PHP Files to Your Backend
Copy these files to your backend folder (`C:\xampp\htdocs\sunshine_marketing_app_backend\`):

- `cashfree_order.php` - Creates orders in Cashfree
- `cashfree_verify_order.php` - Verifies payment status
- `cashfree_config.php` - Configuration file
- `create_order.php` - Creates orders in your database
- `save_payment.php` - Saves payment details to your database

#### Update API Credentials
1. Open `cashfree_config.php`
2. Replace the placeholder credentials with your actual Cashfree credentials:
   ```php
   define('CF_CLIENT_ID', 'YOUR_ACTUAL_CLIENT_ID');
   define('CF_CLIENT_SECRET', 'YOUR_ACTUAL_CLIENT_SECRET');
   define('CF_ENVIRONMENT', 'TEST'); // Change to 'PRODUCTION' for live
   ```

### 3. Flutter App Setup

#### iOS Configuration (if building for iOS)
Add the following to your `ios/Runner/Info.plist`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>phonepe</string>
    <string>tez</string>
    <string>paytmmp</string>
    <string>bhim</string>
    <string>amazonpay</string>
    <string>credpay</string>
</array>
```

#### Android Configuration
The Android configuration is automatically handled by the SDK.

## 📱 How to Use

### 1. Navigate to Checkout Screen

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CheckoutScreen(
      userId: 2, // User ID from your database
      cartItems: cartItems, // List of cart items
      subtotal: 1000.00, // Subtotal amount
      totalGst: 180.00, // GST amount (18%)
      grandTotal: 1180.00, // Total amount including GST
    ),
  ),
);
```

### 2. Payment Flow

1. **User fills customer details** (name, email, phone, address)
2. **Clicks "Proceed to Payment"**
3. **App creates order** in Cashfree backend
4. **Cashfree payment page** opens in WebView
5. **User completes payment** using various methods
6. **Payment verification** happens automatically
7. **Success screen** shows on completion

## 🔧 Configuration

### Environment Variables

- **TEST**: Use for development and testing
- **PRODUCTION**: Use for live transactions

### Supported Payment Methods

- UPI (PhonePe, Google Pay, Paytm, BHIM)
- Credit/Debit Cards
- Net Banking
- Wallets (Amazon Pay, Paytm, etc.)
- EMI

## 📋 API Endpoints

### Create Order in Database
```
POST /create_order.php
```

**Parameters:**
- `user_id`: User ID from your database
- `product_id`: Product ID from your database
- `quantity`: Quantity of items
- `total_amount`: Total amount including GST
- `address`: Delivery address
- `city`: City name
- `state`: State name
- `pincode`: Pincode

### Save Payment Details
```
POST /save_payment.php
```

**Parameters:**
- `user_id`: User ID from your database
- `order_id`: Order ID from your database
- `payment_method`: Payment method used
- `amount`: Payment amount
- `payment_status`: Payment status (Success/Failed/Pending)
- `transaction_id`: Cashfree transaction ID

### Create Cashfree Order
```
POST /cashfree_order.php
```

**Parameters:**
- `environment`: TEST/PRODUCTION
- `client_id`: Your Cashfree Client ID
- `client_secret`: Your Cashfree Client Secret
- `order_amount`: Order amount
- `order_currency`: Currency (INR)
- `customer_id`: Unique customer identifier
- `customer_name`: Customer's full name
- `customer_email`: Customer's email
- `customer_phone`: Customer's phone number
- `order_note`: Additional order notes

### Verify Order
```
POST /cashfree_verify_order.php
```

**Parameters:**
- `environment`: TEST/PRODUCTION
- `client_id`: Your Cashfree Client ID
- `client_secret`: Your Cashfree Client Secret
- `order_id`: Order ID to verify

## 🧪 Testing

### Test Credentials
Use these test credentials for development:

- **Card Number**: 4111 1111 1111 1111
- **Expiry**: Any future date
- **CVV**: Any 3 digits
- **OTP**: 123456

### Test Environment
- Use `CF_ENVIRONMENT = 'TEST'` in development
- All transactions are simulated
- No real money is charged

## 🚨 Error Handling

### Common Error Codes

| Error Code | Description | Solution |
|------------|-------------|----------|
| MISSING_CALLBACK | Callback not set | Set payment callbacks |
| ORDER_ID_MISSING | Order ID not provided | Provide valid order ID |
| INVALID_PAYMENT_OBJECT | Invalid payment mode | Check payment configuration |
| NETWORK_ERROR | Network connection failed | Check internet connection |

### Error Handling in Flutter

```dart
void onError(CFErrorResponse errorResponse, String orderId) {
  print("Payment failed: ${errorResponse.getMessage()}");
  // Handle error appropriately
}
```

## 🔒 Security Considerations

1. **Never expose credentials** in client-side code
2. **Use HTTPS** for all API calls
3. **Validate all inputs** on both client and server
4. **Implement proper error handling**
5. **Log all transactions** for audit purposes

## 📞 Support

### Cashfree Support
- **Documentation**: [https://www.cashfree.com/docs](https://www.cashfree.com/docs)
- **Developer Portal**: [https://developers.cashfree.com](https://developers.cashfree.com)
- **Support Email**: support@cashfree.com

### App Issues
For app-specific issues, check:
1. Network connectivity
2. API credentials
3. Backend server status
4. Flutter SDK version compatibility

## 🔄 Going Live

### 1. Update Environment
Change `CF_ENVIRONMENT` from `'TEST'` to `'PRODUCTION'`

### 2. Update Credentials
Replace test credentials with production credentials

### 3. Test Thoroughly
- Test all payment methods
- Verify webhook handling
- Check error scenarios
- Validate order flow

### 4. Monitor
- Track transaction success rates
- Monitor API response times
- Check error logs regularly

## 📱 Screenshots

The integration includes:

1. **Checkout Screen**: Customer details and order summary
2. **Payment Screen**: Cashfree WebView for payment
3. **Success Screen**: Payment confirmation and next steps

## 🎯 Next Steps

After successful integration:

1. **Add order tracking**
2. **Implement webhooks** for real-time updates
3. **Add payment analytics**
4. **Implement refund handling**
5. **Add multiple currency support**

---

**Note**: This integration follows Cashfree's official Flutter SDK documentation and best practices. Always refer to the [official documentation](https://www.cashfree.com/docs/payments/online/mobile/flutter) for the latest updates and features.
