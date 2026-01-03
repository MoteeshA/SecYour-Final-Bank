plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.sms"

    // ✅ Fix: Use SDK 35 because shared_preferences requires it
    compileSdk = 35

    // ✅ Fix: Required for telephony, shared_preferences, flutter_tts
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Recommended for modern Flutter
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.sms"

        // ✅ Fix: telephony requires minSdk 23
        minSdk = 23

        // Target latest stable SDK
        targetSdk = 35

        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
