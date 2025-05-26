plugins {
    id("com.android.application") version "8.3.0"
    id("org.jetbrains.kotlin.android") version "1.9.10"
    id("dev.flutter.flutter-gradle-plugin") // 🔥 버전 X (자동 관리됨)
    id("com.google.gms.google-services") version "4.4.0"
}

android {
    namespace = "com.conststd.app"
    compileSdk = 33

    defaultConfig {
        applicationId = "com.conststd.app"
        minSdk = 21
        targetSdk = 33
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }
}

dependencies {
    implementation("com.google.firebase:firebase-analytics-ktx")
}
