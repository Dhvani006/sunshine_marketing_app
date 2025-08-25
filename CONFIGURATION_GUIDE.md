# Configuration Guide for Cashfree Payment Integration

## ⚠️ IMPORTANT SECURITY NOTICE
**Never commit actual API keys to version control!** This will cause GitHub to block your pushes and expose your credentials.

## Setup Instructions

### 1. Create Environment Variables

You need to set these environment variables on your server:

```bash
# Environment: TEST for sandbox, PRODUCTION for live
export CF_ENVIRONMENT=TEST

# Your Cashfree App ID (Client ID) from Cashfree Dashboard
export CF_CLIENT_ID=your_actual_client_id_here

# Your Cashfree Secret Key (Client Secret) from Cashfree Dashboard  
export CF_CLIENT_SECRET=your_actual_client_secret_here
```

### 2. For Apache/Nginx (using .htaccess)

Create a `.htaccess` file in your web root:

```apache
# Set environment variables
SetEnv CF_ENVIRONMENT "TEST"
SetEnv CF_CLIENT_ID "your_actual_client_id_here"
SetEnv CF_CLIENT_SECRET "your_actual_client_secret_here"
```

### 3. For PHP-FPM

Add to your `php.ini` or `www.conf`:

```ini
env[CF_ENVIRONMENT] = TEST
env[CF_CLIENT_ID] = your_actual_client_id_here
env[CF_CLIENT_SECRET] = your_actual_client_secret_here
```

### 4. Alternative: Create a Local Config File

If environment variables don't work, create a `local_config.php` file (NOT tracked by Git):

```php
<?php
// local_config.php - DO NOT COMMIT THIS FILE!
define('CF_ENVIRONMENT', 'TEST');
define('CF_CLIENT_ID', 'your_actual_client_id_here');
define('CF_CLIENT_SECRET', 'your_actual_client_secret_here');
?>
```

Then modify `cashfree_config.php` to include this file:

```php
// Include local config if it exists
if (file_exists('local_config.php')) {
    require_once 'local_config.php';
}
```

## Testing Your Configuration

1. Set your environment variables
2. Restart your web server
3. Test the configuration by calling any Cashfree endpoint
4. Check the error logs for configuration validation messages

## Production Deployment

1. Change `CF_ENVIRONMENT` to `PRODUCTION`
2. Use your production API credentials
3. Ensure your server has proper security measures
4. Set up webhook endpoints for production

## Troubleshooting

- **"Configuration not set" error**: Check environment variables are properly set
- **API authentication failed**: Verify Client ID and Secret are correct
- **Environment mismatch**: Ensure `CF_ENVIRONMENT` matches your credentials

## Security Best Practices

1. ✅ Use environment variables
2. ✅ Never commit API keys to Git
3. ✅ Use different credentials for test/production
4. ✅ Regularly rotate your API keys
5. ✅ Monitor API usage and logs
