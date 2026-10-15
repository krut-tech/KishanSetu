package com.farmermarket.farmer_market_app

import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    private val channelName = "com.farmermarket.farmer_market_app/apk_installer"
    private val tag = "KisanSetu_ApkInstaller"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "canRequestPackageInstalls" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val canInstall = packageManager.canRequestPackageInstalls()
                        Log.i(tag, "canRequestPackageInstalls: $canInstall")
                        result.success(canInstall)
                    } else {
                        result.success(true)
                    }
                }
                "openInstallPermissionSettings" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            Log.i(tag, "Opening install permission settings for package: $packageName")
                            val intent = Intent(
                                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                Uri.parse("package:$packageName")
                            ).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        Log.e(tag, "Failed to open install permission settings", e)
                        result.error("SETTINGS_ERROR", e.localizedMessage ?: e.toString(), null)
                    }
                }
                "verifyApk" -> {
                    val filePath = call.argument<String>("filePath")
                    try {
                        val verificationResult = verifyApkInternal(filePath)
                        result.success(verificationResult)
                    } catch (e: Exception) {
                        Log.e(tag, "Failed to verify APK", e)
                        result.error("VERIFY_ERROR", e.localizedMessage ?: e.toString(), null)
                    }
                }
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath.isNullOrEmpty()) {
                        Log.e(tag, "installApk failed: filePath is null or empty")
                        result.error("INVALID_PATH", "File path cannot be null or empty", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val verification = verifyApkInternal(filePath)
                        val isValid = verification["valid"] as? Boolean ?: false
                        if (!isValid) {
                            val errorCode = verification["errorCode"] as? String ?: "VERIFICATION_FAILED"
                            val errorMessage = verification["errorMessage"] as? String ?: "APK verification failed"
                            Log.w(tag, "installApk pre-verification failed: code=$errorCode, message=$errorMessage")
                            result.error(errorCode, errorMessage, verification)
                            return@setMethodCallHandler
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !packageManager.canRequestPackageInstalls()) {
                            Log.w(tag, "installApk failed: canRequestPackageInstalls is false")
                            result.error("PERMISSION_DENIED", "Install unknown apps permission is not granted", null)
                            return@setMethodCallHandler
                        }

                        val file = File(filePath)
                        val authority = "$packageName.fileprovider"
                        Log.i(tag, "Generating FileProvider URI with authority: $authority for file: ${file.absolutePath}")
                        val apkUri: Uri = FileProvider.getUriForFile(
                            this,
                            authority,
                            file
                        )

                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(apkUri, "application/vnd.android.package-archive")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }

                        Log.i(tag, "Starting package installer intent for URI: $apkUri")
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(tag, "Error during installApk execution", e)
                        result.error("INSTALL_ERROR", e.localizedMessage ?: e.toString(), null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun verifyApkInternal(filePath: String?): Map<String, Any?> {
        if (filePath.isNullOrEmpty()) {
            return mapOf("valid" to false, "errorCode" to "INVALID_PATH", "errorMessage" to "File path is null or empty.")
        }

        val file = File(filePath)
        if (!file.exists() || !file.isFile) {
            return mapOf("valid" to false, "errorCode" to "FILE_NOT_FOUND", "errorMessage" to "APK file does not exist at path: $filePath")
        }

        val fileLength = file.length()
        if (fileLength < 1_000_000) {
            return mapOf("valid" to false, "errorCode" to "CORRUPTED_APK", "errorMessage" to "Downloaded file is too small ($fileLength bytes) to be a valid APK.")
        }

        val usableSpace = file.usableSpace
        if (usableSpace in 1 until fileLength) {
            return mapOf("valid" to false, "errorCode" to "INSUFFICIENT_STORAGE", "errorMessage" to "Insufficient storage space on device to install update.")
        }

        val installedPkgInfo = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, 0)
            }
        } catch (e: Exception) {
            Log.e(tag, "Failed to get installed package info", e)
            null
        }

        val installedVersionCode = if (installedPkgInfo != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                installedPkgInfo.longVersionCode
            } else {
                @Suppress("DEPRECATION")
                installedPkgInfo.versionCode.toLong()
            }
        } else null

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            PackageManager.GET_SIGNING_CERTIFICATES
        } else {
            @Suppress("DEPRECATION")
            PackageManager.GET_SIGNATURES
        }

        val apkPkgInfo = packageManager.getPackageArchiveInfo(filePath, flags)
        if (apkPkgInfo == null) {
            return mapOf("valid" to false, "errorCode" to "CORRUPTED_APK", "errorMessage" to "Downloaded file could not be parsed as a valid Android APK.")
        }

        apkPkgInfo.applicationInfo?.let {
            it.sourceDir = filePath
            it.publicSourceDir = filePath
        }

        val apkPackageName = apkPkgInfo.packageName
        if (!apkPackageName.isNullOrEmpty() && apkPackageName != packageName) {
            return mapOf(
                "valid" to false,
                "errorCode" to "PACKAGE_NAME_MISMATCH",
                "errorMessage" to "Package name mismatch: installed is '$packageName', downloaded is '$apkPackageName'."
            )
        }

        val apkVersionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            apkPkgInfo.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            apkPkgInfo.versionCode.toLong()
        }

        if (installedVersionCode != null && apkVersionCode < installedVersionCode) {
            return mapOf(
                "valid" to false,
                "errorCode" to "VERSION_DOWNGRADE",
                "errorMessage" to "Downloaded APK version code ($apkVersionCode) is older than installed version code ($installedVersionCode)."
            )
        }

        val installedCerts = getPackageCertificatesSha256(packageName, isApkFile = false, archiveInfo = null)
        val apkCerts = getPackageCertificatesSha256(packageName, isApkFile = true, archiveInfo = apkPkgInfo)

        val installedCertSha256 = installedCerts.firstOrNull() ?: ""
        val apkCertSha256 = apkCerts.firstOrNull() ?: ""

        Log.i(tag, "Installed cert SHA-256: $installedCertSha256")
        Log.i(tag, "APK cert SHA-256: $apkCertSha256")

        if (installedCerts.isNotEmpty() && apkCerts.isNotEmpty()) {
            val matches = installedCerts.any { installed -> apkCerts.contains(installed) }
            if (!matches) {
                return mapOf(
                    "valid" to false,
                    "errorCode" to "SIGNATURE_MISMATCH",
                    "errorMessage" to "Signing key mismatch: The downloaded APK is signed with a different key than this installed build (e.g. Release key vs local Debug key). Uninstall the current app or install a matching release build.",
                    "installedVersionCode" to installedVersionCode,
                    "apkVersionCode" to apkVersionCode,
                    "installedCertSha256" to installedCertSha256,
                    "apkCertSha256" to apkCertSha256
                )
            }
        }

        return mapOf(
            "valid" to true,
            "errorCode" to "NONE",
            "errorMessage" to null,
            "installedVersionCode" to installedVersionCode,
            "apkVersionCode" to apkVersionCode,
            "installedCertSha256" to installedCertSha256,
            "apkCertSha256" to apkCertSha256
        )
    }

    private fun getPackageCertificatesSha256(
        pkgName: String,
        isApkFile: Boolean,
        archiveInfo: PackageInfo?
    ): List<String> {
        val certs = mutableListOf<ByteArray>()
        try {
            if (isApkFile && archiveInfo != null) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    val signingInfo = archiveInfo.signingInfo
                    if (signingInfo != null) {
                        val signers = if (signingInfo.hasMultipleSigners()) {
                            signingInfo.apkContentsSigners
                        } else {
                            signingInfo.signingCertificateHistory
                        }
                        signers?.forEach { certs.add(it.toByteArray()) }
                    }
                } else {
                    @Suppress("DEPRECATION")
                    archiveInfo.signatures?.forEach { certs.add(it.toByteArray()) }
                }
            } else {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    val pkgInfo = packageManager.getPackageInfo(
                        pkgName,
                        PackageManager.GET_SIGNING_CERTIFICATES
                    )
                    val signingInfo = pkgInfo.signingInfo
                    if (signingInfo != null) {
                        val signers = if (signingInfo.hasMultipleSigners()) {
                            signingInfo.apkContentsSigners
                        } else {
                            signingInfo.signingCertificateHistory
                        }
                        signers?.forEach { certs.add(it.toByteArray()) }
                    }
                } else {
                    @Suppress("DEPRECATION")
                    val pkgInfo = packageManager.getPackageInfo(
                        pkgName,
                        PackageManager.GET_SIGNATURES
                    )
                    @Suppress("DEPRECATION")
                    pkgInfo.signatures?.forEach { certs.add(it.toByteArray()) }
                }
            }
        } catch (e: Exception) {
            Log.e(tag, "Error reading package certificates (isApkFile=$isApkFile): $e")
        }

        return certs.map { computeSha256(it) }.filter { it.isNotEmpty() }
    }

    private fun computeSha256(bytes: ByteArray): String {
        return try {
            val md = MessageDigest.getInstance("SHA-256")
            val digest = md.digest(bytes)
            digest.joinToString(":") { "%02X".format(it) }
        } catch (e: Exception) {
            ""
        }
    }
}
