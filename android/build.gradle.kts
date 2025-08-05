// Top-level build.gradle.kts (Project-level)

plugins {
    // ✅ إضافة Google Services Gradle Plugin بدون تطبيق مباشر هنا
    id("com.google.gms.google-services") version "4.4.1" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ إذا كنت تستخدم Tasks أو إعدادات إضافية ممكن إضافتها هنا لاحقاً
