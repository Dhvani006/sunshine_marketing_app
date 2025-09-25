# 🔐 Security Configuration Guide

## API Key Management

This project uses secure configuration management to protect sensitive API keys from being committed to version control.

### Files Structure

```
├── .env                    # ⚠️ NEVER COMMIT - Contains actual API keys
├── env.template           # ✅ Safe template for new developers
├── config.php             # ✅ Loads configuration from environment
├── lib/config/
│   └── cashfree_config.dart # ✅ Flutter secure configuration
└── .gitignore             # ✅ Excludes sensitive files
```

### Setup Instructions

#### 1. **Backend (PHP) Setup**

```bash
# Copy the template
cp env.template .env

# Edit .env with your actual API keys
nano .env
```

**Required Environment Variables:**
```env
CASHFREE_APP_ID=your_actual_app_id
CASHFREE_SECRET_KEY=your_actual_secret_key
CASHFREE_ENVIRONMENT=sandbox
SERVER_URL=http://192.168.27.5/sunshine_marketing_app_backend
NGROK_URL=https://your-ngrok-url.ngrok-free.app/sunshine_marketing_app_backend
```

#### 2. **Flutter Setup**

**Option A: Build-time Environment Variables**
```bash
flutter run --dart-define=CASHFREE_APP_ID=your_app_id --dart-define=CASHFREE_SECRET_KEY=your_secret_key
```

**Option B: Development Fallback**
The `CashfreeConfig` class includes fallback values for development.

#### 3. **Production Deployment**

**For Production Servers:**
```bash
# Set environment variables
export CASHFREE_APP_ID=your_production_app_id
export CASHFREE_SECRET_KEY=your_production_secret_key
export CASHFREE_ENVIRONMENT=production
```

**For CI/CD:**
- Use secret management systems (GitHub Secrets, Azure Key Vault, etc.)
- Never hardcode secrets in deployment scripts

### Security Best Practices

#### ✅ **DO:**
- Use environment variables for all secrets
- Keep `.env` files out of version control
- Use different keys for development/production
- Rotate API keys regularly
- Use least-privilege access

#### ❌ **DON'T:**
- Commit API keys to Git
- Hardcode secrets in source code
- Share API keys in chat/email
- Use production keys in development
- Store secrets in client-side code

### Verification

#### Check if Configuration is Working:

**PHP Backend:**
```php
// Test in any PHP file
$config = include 'config.php';
var_dump($config['cashfree']); // Should show your actual keys
```

**Flutter App:**
```dart
// Test in Flutter
print('App ID: ${CashfreeConfig.appId}');
print('Is Configured: ${CashfreeConfig.isConfigured}');
```

### Troubleshooting

#### Common Issues:

1. **"API keys not configured" error**
   - Check if `.env` file exists
   - Verify environment variables are loaded
   - Ensure no typos in variable names

2. **"Push protection blocked" error**
   - Remove hardcoded keys from code
   - Use environment variables instead
   - Check `.gitignore` includes `.env`

3. **Flutter build errors**
   - Ensure `CashfreeConfig` is imported correctly
   - Check fallback values are valid
   - Verify environment variable syntax

### Emergency Procedures

#### If API Keys are Compromised:

1. **Immediately rotate keys** in Cashfree Dashboard
2. **Update all environments** with new keys
3. **Review access logs** for suspicious activity
4. **Notify team members** to update their local `.env` files

### Support

For security-related questions or issues:
- Check Cashfree documentation
- Review this guide
- Contact development team
