import com.google.firebase.crashlytics.buildtools.gradle.CrashlyticsExtension
import java.io.FileInputStream
import java.nio.charset.StandardCharsets
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
val requestedReleaseBuild = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
val skipCrashlyticsMappingUpload =
    providers.environmentVariable("SKIP_CRASHLYTICS_MAPPING_UPLOAD")
        .orNull
        ?.equals("true", ignoreCase = true) == true

fun decodedDartDefines(): Map<String, String> {
    return providers.gradleProperty("dart-defines").orNull.orEmpty()
        .split(",")
        .mapNotNull { encoded ->
            runCatching {
                String(
                    Base64.getDecoder().decode(encoded),
                    StandardCharsets.UTF_8,
                )
            }.getOrNull()
        }
        .mapNotNull { define ->
            val parts = define.split("=", limit = 2)
            if (parts.size == 2) parts[0] to parts[1] else null
        }
        .toMap()
}

if (requestedReleaseBuild && !hasReleaseKeystore) {
    throw GradleException(
        "Release signing is not configured. Add android/key.properties and the release keystore."
    )
}

if (requestedReleaseBuild) {
    val releaseDefines = decodedDartDefines()
    val apiBaseUrl = releaseDefines["API_BASE_URL"].orEmpty()
    val mapTilerApiKey = releaseDefines["MAPTILER_API_KEY"].orEmpty()
    if (!apiBaseUrl.startsWith("https://")) {
        throw GradleException(
            "Release requires an HTTPS API_BASE_URL dart define."
        )
    }
    if (mapTilerApiKey.isBlank()) {
        throw GradleException(
            "Release requires a non-empty MAPTILER_API_KEY dart define."
        )
    }
}

if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.yallamarket.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.yallamarket.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            }
            configure<CrashlyticsExtension> {
                mappingFileUploadEnabled = !skipCrashlyticsMappingUpload
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
