// Fix for AGP AndroidLocationsException when both ANDROID_PREFS_ROOT and ANDROID_USER_HOME are set
try {
    val peClass = Class.forName("java.lang.ProcessEnvironment")
    try {
        val f1 = peClass.getDeclaredField("theUnmodifiableEnvironment")
        f1.isAccessible = true
        val uMap = f1.get(null)
        val mF = uMap.javaClass.getDeclaredField("m")
        mF.isAccessible = true
        (mF.get(uMap) as? MutableMap<*, *>)?.remove("ANDROID_PREFS_ROOT")
    } catch (_: Exception) {}
    try {
        val f2 = peClass.getDeclaredField("theEnvironment")
        f2.isAccessible = true
        (f2.get(null) as? MutableMap<*, *>)?.remove("ANDROID_PREFS_ROOT")
    } catch (_: Exception) {}
} catch (_: Exception) {}

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
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
