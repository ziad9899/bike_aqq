import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // ✅ Firebase
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.caoital55.market"  // ✅ الاسم الجديد
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.caoital55.market" // ✅ الاسم الجديد
        minSdk = 23              // ✅ عدلنا من 21 إلى 23
        targetSdk = flutter.targetSdkVersion

        // 🔹 رقم الإصدار الجديد
        versionCode = 3       // يجب أن يزيد كل رفع
        versionName = "1.3"   // يظهر للمستخدم في المتجر
    }

    signingConfigs {
        create("release") {
            val keystoreProperties = Properties()
            val keystoreFile = rootProject.file("key.properties")
            if (keystoreFile.exists()) {
                keystoreProperties.load(FileInputStream(keystoreFile))
            }
            storeFile = file(keystoreProperties["storeFile"]!!)
            storePassword = keystoreProperties["storePassword"] as String
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

apply(plugin = "com.google.gms.google-services")
