import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.projectDir.resolve("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}


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
    namespace = "com.example.new_project_1"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.spore.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 9
        versionName = "1.0.7"
    }

    signingConfigs {
    create("release") {
        keyAlias = keystoreProperties.getProperty("keyAlias") 
        keyPassword = keystoreProperties.getProperty("keyPassword")
        storePassword = keystoreProperties.getProperty("storePassword")
        
        val stFile = keystoreProperties.getProperty("storeFile")
        if (stFile != null) {
            // 이 코드가 app 폴더 안에 있는 uploadKey.jks를 찾게 됩니다.
            storeFile = file(stFile)
        }
    }
}

    buildTypes {
        getByName("release") {
            
            signingConfig = signingConfigs.getByName("release")
            
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
