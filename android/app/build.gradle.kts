import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 1. قراءة ملف key.properties (يمكنك تركه احتياطياً أو حذفه طالما تكتب الباسوورد مباشرة)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.tas3eera.app"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true  
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.tas3eera.app"
        minSdk = 23
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    // ✅ التعديل الحاسم: تم إدخال التوقيع داخل الـ android block بشكل صحيح
    signingConfigs {
        // إعادة تهيئة الـ debug وإجباره على استخدام ملف الـ jks الفعلي الخاص بك
        getByName("debug") {
            keyAlias = "upload"
            keyPassword = "1597532684+aA@#$"
            storePassword = "1597532684+aA@#$"
            storeFile = file("./upload-keystore.jks")
            
            enableV1Signing = true
            enableV2Signing = true
            enableV3Signing = true
        }
    }

    buildTypes {
        release {
            // إجبار التوقيع المعدل
            signingConfig = signingConfigs.getByName("debug")
            
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
} // 🔹 هنا تم إغلاق قوس الـ android الفعلي بعد احتواء كل العناصر السابقة بشكل سليم

flutter {
    source = "../.."
}

dependencies {
    // ✅ Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.1.0"))

    // ✅ Firebase Analytics & Messaging
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}