
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.Waychaser"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.13113456"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }
    dependencies {
    // This goes here — inside dependencies in the app-level file!
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    implementation("androidx.core:core-ktx:1.10.1")
    // your other dependencies...
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.Waychaser"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
              // enable code shrinking (R8/ProGuard)
            isMinifyEnabled   = true
            // remove unused resources
            isShrinkResources = true

            // point to the default optimized ProGuard rules + your custom rules
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // if you still want to use the debug signing config for now:
            signingConfig = signingConfigs.getByName("debug")
        }
        debug {
            // typically you leave debug un-minified
            isMinifyEnabled = false
        }
    }
}

flutter {
    source = "../.."
}

apply(plugin = "com.google.gms.google-services")

