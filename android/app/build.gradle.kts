import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release imza bilgileri: android/key.properties
//
// Bu dosya ve anahtar (.jks) GIT'E GİRMEZ (android/.gitignore). İçinde
// parola var; biri ele geçirirse uygulama adına sahte güncelleme imzalayabilir.
// Şablon: android/key.properties.example
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val releaseKeyVar = keystorePropertiesFile.exists()
if (releaseKeyVar) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    // Uygulama kimliği. Play Store'da yayınlandıktan sonra DEĞİŞTİRİLEMEZ.
    namespace = "com.iylabs.minikasif"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.iylabs.minikasif"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // pubspec.yaml'daki "version: 1.0.0+1" -> versionName 1.0.0, versionCode 1.
        // Play Store'a her yüklemede versionCode (+ sonrası) artırılmalı.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (releaseKeyVar) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (releaseKeyVar) {
                signingConfigs.getByName("release")
            } else {
                // Anahtar yoksa derleme yine çalışsın (telefonda denemek için),
                // ama bu dosya Play Store'a YÜKLENEMEZ.
                logger.warn(
                    "UYARI: android/key.properties bulunamadı. Release DEBUG " +
                        "anahtarıyla imzalanıyor; Play Store bu dosyayı kabul etmez."
                )
                signingConfigs.getByName("debug")
            }
        }
    }
}

// .aab, Play Store'a YÜKLENEN dosya. Anahtar yoksa derlemeyi açık bir hatayla
// durduruyoruz. Neden uyarı değil de hata? Flutter, Gradle uyarılarını ekranda
// göstermiyor; uyarı gözden kaçıyor ve debug imzalı dosya yüklenmeye
// çalışılıyordu. .apk (telefonda denemek için) debug imzasıyla çalışmaya devam eder.
gradle.taskGraph.whenReady {
    if (!releaseKeyVar && allTasks.any { it.name == "bundleRelease" }) {
        // Önceki bir derlemeden kalan .aab varsa SİL. Derleme hata verse bile
        // dosya yerinde kalıyordu; klasörde duran eski (debug imzalı) paket
        // yanlışlıkla Play Console'a yüklenebilir. Bir kez yaşandı.
        val eski = layout.buildDirectory
            .file("outputs/bundle/release/app-release.aab").get().asFile
        val silindi = eski.exists() && eski.delete()
        throw GradleException(
            "Play Store paketi (.aab) için imza anahtarı gerekli: " +
                "android/key.properties bulunamadı. " +
                "Şablon: android/key.properties.example" +
                if (silindi) " (Önceki derlemeden kalan app-release.aab silindi.)" else ""
        )
    }
}

flutter {
    source = "../.."
}
