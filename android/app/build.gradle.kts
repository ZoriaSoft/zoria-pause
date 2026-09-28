import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release imzası (Faz 6): android/key.properties VARSA kendi imzamızla,
// YOKSA debug fallback — CI ve `flutter run --release` kırılmaz.
// key.properties asla commit'lenmez (anayasa #5); kalıp: key.properties.example.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "com.zoriasoft.zoriapause"
    compileSdk = flutter.compileSdkVersion
    // Literal pin — Flutter 3.44 şablon default'u (FlutterExtension.kt:
    // ndkVersion = "28.2.13676358"); `flutter.ndkVersion` toolchain'e göre
    // yüzer (android-audit FAIL, fleet review 2026-09-21).
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    buildFeatures {
        // Shizuku UserService AIDL arayüzü (IPauseGrantService)
        aidl = true
    }

    defaultConfig {
        // Play'de kalıcı (kullanıcı kararı 2026-09-05) — değiştirilmez.
        applicationId = "com.zoriasoft.zoriapause"
        // Zoria Version Matrix: minSdk 24 hardcode (flutter.minSdkVersion kullanma).
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                // storeFile, key.properties'in bulunduğu android/ dizinine göre çözülür.
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    testImplementation("junit:junit:4.13.2")
    // Shizuku API (MVP+1, kullanıcı kararı 2026-09-05): yalnızca KURULUM anında
    // tek dokunuşla WRITE_SECURE_SETTINGS grant'i için; izin kalıcı, runtime
    // bağımlılığı yok. Lisans: MIT-tarzı permissive (Shizuku-API reposu).
    implementation("dev.rikka.shizuku:api:13.1.5")
    implementation("dev.rikka.shizuku:provider:13.1.5")
}
