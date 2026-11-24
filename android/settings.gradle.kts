pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        // Aliyun mirrors (China)
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }

        // DevNeeds & Myket mirrors (Iran)
        maven { url = uri("https://maven.devneeds.ir/repository/google/") }
        maven { url = uri("https://maven.devneeds.ir/repository/maven-central/") }
        maven { url = uri("https://maven.devneeds.ir/repository/gradle-plugins/") }
        maven { url = uri("https://maven.myket.ir/repository/google/") }
        maven { url = uri("https://maven.myket.ir/repository/maven-central/") }

        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")
