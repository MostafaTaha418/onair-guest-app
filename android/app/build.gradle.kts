import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Upload key for store builds, from android/key.properties (git-ignored) or
// CI environment variables. Never committed (Constitution IV).
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

fun signingValue(property: String, environment: String): String? =
    keystoreProperties.getProperty(property) ?: System.getenv(environment)

val releaseStoreFile = signingValue("storeFile", "ONAIR_UPLOAD_KEYSTORE")
val hasReleaseKeystore = releaseStoreFile != null

android {
    namespace = "com.onair.guest"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        resValues = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.onair.guest"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["linkDomain"] =
            providers.gradleProperty("onAirLinkDomain").orElse("on-air.website").get()
    }

    signingConfigs {
        create("release") {
            if (releaseStoreFile != null) {
                storeFile = file(releaseStoreFile)
                storePassword =
                    signingValue("storePassword", "ONAIR_UPLOAD_KEYSTORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "ONAIR_UPLOAD_KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "ONAIR_UPLOAD_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            isDebuggable = false
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            // Upload key when available. Without it only Staging may fall back
            // to the debug key (internal Firebase distribution); production
            // release builds fail below instead of shipping a debug signature.
            signingConfig =
                if (hasReleaseKeystore) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
        }
    }

    flavorDimensions += "environment"
    productFlavors {
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            resValue("string", "app_name", "OnAir (Staging)")
        }
        create("production") {
            dimension = "environment"
            resValue("string", "app_name", "OnAir")
        }
    }
}

gradle.taskGraph.whenReady {
    val buildsProductionRelease =
        allTasks.any { task ->
            task.project == project &&
                task.name.contains("ProductionRelease") &&
                (task.name.startsWith("assemble") || task.name.startsWith("bundle"))
        }
    if (buildsProductionRelease && !hasReleaseKeystore) {
        throw GradleException(
            "Production release builds need the upload key: add android/key.properties " +
                "or set ONAIR_UPLOAD_KEYSTORE, ONAIR_UPLOAD_KEYSTORE_PASSWORD, " +
                "ONAIR_UPLOAD_KEY_ALIAS, and ONAIR_UPLOAD_KEY_PASSWORD.",
        )
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
