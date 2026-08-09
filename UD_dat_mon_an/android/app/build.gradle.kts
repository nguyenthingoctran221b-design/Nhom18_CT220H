import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.nhom18.ud_dat_mon_an"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.nhom18.ud_dat_mon_an"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeType = "PKCS12"

            val envKeyAlias = System.getenv("KEY_ALIAS")?.trim()
            val envKeyPassword = System.getenv("KEY_PASSWORD")?.trim()
            val envKeystorePath = System.getenv("KEYSTORE_PATH")?.trim()
            val envKeystorePassword = System.getenv("KEYSTORE_PASSWORD")?.trim()

            val sPass = if (!envKeystorePassword.isNullOrEmpty()) envKeystorePassword else keystoreProperties.getProperty("storePassword")
            val alias = if (!envKeyAlias.isNullOrEmpty()) envKeyAlias else keystoreProperties.getProperty("keyAlias")

            keyAlias = alias
            storePassword = sPass
            keyPassword = sPass

            val keystorePath = if (!envKeystorePath.isNullOrEmpty()) envKeystorePath else keystoreProperties.getProperty("storeFile")
            if (!keystorePath.isNullOrEmpty()) {
                storeFile = file(keystorePath)
            }

            println("Release Signing Config -> Alias: '$keyAlias', StoreFile: '${storeFile?.name}'")
        }
    }

    buildTypes {
        release {
            val releaseSigning = signingConfigs.getByName("release")
            signingConfig = if (releaseSigning.storeFile != null && releaseSigning.storeFile!!.exists()) {
                releaseSigning
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

