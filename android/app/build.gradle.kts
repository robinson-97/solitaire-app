plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.hopstone.hopstone"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.hopstone.hopstone"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Test builds from GitHub: one fixed key, so a new test build installs over
        // the old one and keeps your progress. Not secret, never used for the store.
        create("test") {
            storeFile = file("../test-signing.jks")
            storePassword = "hopstone-test"
            keyAlias = "test"
            keyPassword = "hopstone-test"
        }
        // The real upload key for Google Play, given through the environment by the
        // "Release bundle" workflow (secrets on GitHub). It is never stored in the code.
        val uploadStore = System.getenv("HOP_KEYSTORE")
        if (uploadStore != null) {
            create("upload") {
                storeFile = file(uploadStore)
                storePassword = System.getenv("HOP_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("HOP_KEY_ALIAS")
                keyPassword = System.getenv("HOP_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("upload") ?: signingConfigs.getByName("test")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
