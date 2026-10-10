package com.farmermarket.farmer_market_app

import android.content.Intent
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
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath.isNullOrEmpty()) {
                        Log.e(tag, "installApk failed: filePath is null or empty")
                        result.error("INVALID_PATH", "File path cannot be null or empty", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val file = File(filePath)
                        if (!file.exists()) {
                            Log.e(tag, "installApk failed: APK file does not exist at $filePath")
                            result.error("FILE_NOT_FOUND", "APK file does not exist at path: $filePath", null)
                            return@setMethodCallHandler
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !packageManager.canRequestPackageInstalls()) {
                            Log.w(tag, "installApk failed: canRequestPackageInstalls is false")
                            result.error("PERMISSION_DENIED", "Install unknown apps permission is not granted", null)
                            return@setMethodCallHandler
                        }

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
}
