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
val releaseStorePassword = signingValue("storePassword", "ONAIR_UPLOAD_KEYSTORE_PASSWORD")
val releaseKeyAlias = signingValue("keyAlias", "ONAIR_UPLOAD_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "ONAIR_UPLOAD_KEY_PASSWORD")
val hasReleaseKeystore =
    listOf(releaseStoreFile, releaseStorePassword, releaseKeyAlias, releaseKeyPassword)
        .all { !it.isNullOrBlank() }

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
            if (hasReleaseKeystore) {
                storeFile = file(requireNotNull(releaseStoreFile))
                storePassword = requireNotNull(releaseStorePassword)
                keyAlias = requireNotNull(releaseKeyAlias)
                keyPassword = requireNotNull(releaseKeyPassword)
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
            // Every release artifact (including Staging) uses the stable upload
            // key. Debug variants continue to use Android's separate debug key.
            signingConfig = signingConfigs.getByName("release")
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
    val buildsRelease =
        allTasks.any { task ->
            task.project == project &&
                task.name.contains("Release") &&
                (task.name.startsWith("assemble") || task.name.startsWith("bundle"))
        }
    if (buildsRelease && !hasReleaseKeystore) {
        throw GradleException(
            "Release builds need the stable upload key: add android/key.properties " +
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
