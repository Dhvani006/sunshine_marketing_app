# 🚀 Cashfree Integration Setup Guide

## 📋 **What You Need to Do:**

### 1. **Copy PHP Files to Backend**
Copy these files to `C:\xampp\htdocs\sunshine_marketing_app_backend\`:
- ✅ `create_order.php` - Creates orders in your database
- ✅ `save_payment.php` - Saves payment details
- ✅ `cashfree_order.php` - Creates orders in Cashfree
- ✅ `cashfree_verify_order.php` - Verifies order status
- ✅ `cashfree_webhook.php` - Handles Cashfree webhooks
- ✅ `cashfree_config.php` - Cashfree configuration

### 2. **Set Up Webhook in Cashfree Dashboard**

#### **Step 1: Go to Cashfree Dashboard**
- Login to your Cashfree merchant dashboard
- Go to **Settings** → **Webhooks**

#### **Step 2: Add Webhook URL**
- **Webhook URL**: `http://your-domain.com/sunshine_marketing_app_backend/cashfree_webhook.php`
- **Events to Subscribe**:
  - ✅ `ORDER_PAID`
  - ✅ `ORDER_FAILED`
  - ✅ `PAYMENT_SUCCESS`
  - ✅ `PAYMENT_FAILED`

#### **Step 3: Get Webhook Secret**
- Copy the webhook secret from Cashfree dashboard
- Update `cashfree_webhook.php` line 25:
```php
$webhookSecret = 'your_actual_webhook_secret_here';
```

### 3. **Test the Integration**

#### **Test Order Creation:**
1. Add items to cart in your Flutter app
2. Go to checkout
3. Fill customer details
4. Click "Proceed to Payment"
5. Check your database - orders should be created

#### **Test Payment Processing:**
1. Complete payment in Cashfree
2. Check your database - payment details should be saved
3. Check Cashfree dashboard - order status should update

## 🔧 **Database Schema Updates**

Your current schema is perfect! The integration will:
- ✅ Create orders in `orders` table
- ✅ Save payments in `payments` table
- ✅ Link orders with payments via `Payment_id`
- ✅ Clear cart items after successful order

## 📱 **Flutter App Updates**

The Flutter app is already updated with:
- ✅ Platform-aware Cashfree service
- ✅ Proper error handling
- ✅ Database integration
- ✅ Payment success/failure callbacks

## 🌐 **Webhook Benefits**

With webhooks set up:
- ✅ **Automatic Updates**: Cashfree automatically updates your database
- ✅ **Real-time Sync**: Payment status changes are reflected immediately
- ✅ **Reliable**: Even if user closes app, data is still saved
- ✅ **Scalable**: Works for multiple concurrent payments

## 🚨 **Important Notes**

### **For Testing:**
- Use **TEST environment** in Cashfree
- Test with small amounts
- Check database after each payment

### **For Production:**
- Switch to **PRODUCTION environment**
- Enable webhook signature verification
- Use HTTPS for webhook URLs
- Monitor webhook logs

## 📊 **Expected Database Results**

After successful integration, you should see:

#### **Orders Table:**
```sql
Order_id | User_id | Ecomm_product_id | Quantity | Total_amount | Payment_id | address | city | state | pincode
1        | 2       | 1                | 3        | 42480.00    | 1          | gsudhcnks| cgdhj| gcdhw| 789456
```

#### **Payments Table:**
```sql
Payment_id | User_id | Order_id | Payment_method | Amount | Payment_status | Transaction_id
1          | 2       | 1        | Cashfree       | 42480.00| Success       | CF_1234567890
```

## 🔍 **Troubleshooting**

### **If Orders Not Saving:**
1. Check database connection in PHP files
2. Verify database credentials
3. Check PHP error logs
4. Ensure tables exist with correct structure

### **If Payments Not Saving:**
1. Check webhook URL is accessible
2. Verify webhook secret is correct
3. Check webhook logs in Cashfree dashboard
4. Ensure `cashfree_webhook.php` is in backend folder

### **If Flutter App Crashes:**
1. Check Cashfree SDK is properly installed
2. Verify API endpoints are accessible
3. Check network connectivity
4. Review Flutter console logs

## 🎯 **Next Steps**

1. **Copy all PHP files** to your backend folder
2. **Set up webhook** in Cashfree dashboard
3. **Test complete flow** from cart to payment
4. **Verify data** is saved in your database
5. **Go live** when everything works perfectly!

## 📞 **Support**

If you encounter issues:
1. Check PHP error logs
2. Check Flutter console logs
3. Verify database connectivity
4. Test webhook endpoints manually

---

**🎉 Your Cashfree integration is now complete and ready for testing!**



