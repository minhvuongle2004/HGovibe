plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.smart_travel_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.smart_travel_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Facebook Login placeholders - thay bằng giá trị thật trong quá trình cấu hình
        resValue("string", "facebook_app_id", "2700557443660865")
        resValue("string", "facebook_client_token", "b8b466e81639fa7bde01a744921c7bdb")
        resValue("string", "fb_login_protocol_scheme", "fb2700557443660865")

        manifestPlaceholders["facebookAppId"] = "2700557443660865"
        manifestPlaceholders["facebookClientToken"] = "b8b466e81639fa7bde01a744921c7bdb"
        manifestPlaceholders["fbLoginProtocolScheme"] = "fb2700557443660865"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    configurations.all {
        resolutionStrategy {
            force("com.google.android.gms:play-services-location:17.0.0")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Mapbox 9.x yêu cầu Play Services Location <= 17 để tương thích kiểu class
    implementation("com.google.android.gms:play-services-location:17.0.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
}