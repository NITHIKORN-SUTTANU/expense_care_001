# Security Best Practices for ExpenseCare

## ⚠️ CRITICAL: Firebase Configuration Security

### Current Situation
The project contains Firebase API keys and configuration in the following files:
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

### Important Notes

1. **Firebase API Keys in `firebase_options.dart` are NOT secrets**
   - These are client-side API keys that are meant to identify your Firebase project
   - They are embedded in your app and sent with every request
   - Firebase security is enforced through Firestore Security Rules, not through key secrecy

2. **Security is Enforced Through Firestore Rules**
   - Your actual security comes from `firestore.rules` (already in the project)
   - These rules determine who can read/write data
   - Always test your security rules thoroughly

3. **If This is a Public Repository**
   - Consider rotating your Firebase API keys as a precaution
   - Add application restrictions in Firebase Console:
     - For web: Add authorized domains
     - For Android: Add SHA-256 fingerprints
     - For iOS: Add bundle identifiers
   - Set up Firebase App Check for additional security

### Recommended Actions

#### 1. Application Restrictions
Go to [Firebase Console](https://console.firebase.google.com) → Your Project → Project Settings → General:
- **Web API Key**: Restrict to authorized domains
- **Android API Key**: Restrict to SHA-256 fingerprints
- **iOS API Key**: Restrict to bundle IDs

#### 2. Enable Firebase App Check
App Check helps protect your backend resources from abuse:
```bash
# In Firebase Console
1. Go to Build → App Check
2. Register your apps
3. Enable enforcement for Cloud Firestore
```

#### 3. Review Firestore Security Rules
Make sure your `firestore.rules` are properly configured:
- Users can only access their own data
- Proper authentication checks are in place
- No open read/write access

## Git Best Practices

### Files to Consider for .gitignore

While Firebase config files can be committed (they're not secrets), you may want to add these to `.gitignore` for environment-specific configurations:

```gitignore
# Optional: Environment-specific files
# .env
# .env.local
# .env.production

# Optional: If using multiple Firebase environments
# lib/firebase_options.dart
# android/app/google-services.json
# ios/Runner/GoogleService-Info.plist

# Sensitive local development files
*.log
*.private
.DS_Store
```

## Development vs Production

Consider setting up separate Firebase projects for:
- Development environment
- Staging environment
- Production environment

This allows you to:
- Test changes safely
- Avoid mixing development and production data
- Use different security rules for testing

## Additional Security Measures

1. **Keep Dependencies Updated**
   ```bash
   flutter pub upgrade
   ```

2. **Code Obfuscation for Release Builds**
   ```bash
   flutter build apk --obfuscate --split-debug-info=<directory>
   ```

3. **Enable Two-Factor Authentication**
   - For your Firebase account
   - For your Google account
   - For your GitHub account

4. **Regular Security Audits**
   - Review Firestore rules monthly
   - Check Firebase Console for unusual activity
   - Monitor authentication logs

## Resources

- [Firebase Security Best Practices](https://firebase.google.com/docs/rules/basics)
- [Firebase App Check](https://firebase.google.com/docs/app-check)
- [Flutter Security Guidelines](https://docs.flutter.dev/security)
