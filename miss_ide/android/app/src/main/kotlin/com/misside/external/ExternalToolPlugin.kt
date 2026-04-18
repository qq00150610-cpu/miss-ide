// android/app/src/main/kotlin/com/misside/external/ExternalToolPlugin.kt - 外部工具集成 Android 原生实现
package com.misside.external

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*

class ExternalToolPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.misside/external_tools")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }
    
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "checkPackage" -> {
                val packageName = call.argument<String>("packageName")
                if (packageName == null) {
                    result.error("INVALID_ARGS", "Package name required", null)
                    return
                }
                checkPackage(packageName, result)
            }
            
            "launchApp" -> {
                val packageName = call.argument<String>("packageName")
                val filePath = call.argument<String>("filePath")
                val action = call.argument<String>("action")
                
                if (packageName == null) {
                    result.error("INVALID_ARGS", "Package name required", null)
                    return
                }
                
                launchApp(packageName, filePath, action, call.argument("extras"), result)
            }
            
            "checkShizuku" -> {
                checkShizuku(result)
            }
            
            "requestShizukuPermission" -> {
                requestShizukuPermission(result)
            }
            
            "executeWithShizuku" -> {
                val command = call.argument<String>("command")
                if (command == null) {
                    result.error("INVALID_ARGS", "Command required", null)
                    return
                }
                executeWithShizuku(command, result)
            }
            
            "isPackageVisible" -> {
                val packageName = call.argument<String>("packageName")
                if (packageName == null) {
                    result.error("INVALID_ARGS", "Package name required", null)
                    return
                }
                result.success(isPackageVisible(packageName))
            }
            
            else -> {
                result.notImplemented()
            }
        }
    }
    
    private fun checkPackage(packageName: String, result: Result) {
        try {
            val pm = context.packageManager
            val packageInfo = pm.getPackageInfo(packageName, PackageManager.GET_ACTIVITIES)
            
            result.success(mapOf(
                "installed" to true,
                "version" to packageInfo.versionName,
                "versionCode" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    packageInfo.longVersionCode
                } else {
                    @Suppress("DEPRECATION")
                    packageInfo.versionCode
                }
            ))
        } catch (e: PackageManager.NameNotFoundException) {
            result.success(mapOf(
                "installed" to false,
                "version" to null
            ))
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        }
    }
    
    private fun launchApp(
        packageName: String,
        filePath: String?,
        action: String?,
        extras: Map<String, Any>?,
        result: Result
    ) {
        try {
            val launchIntent = pm.getLaunchIntentForPackage(packageName)
            
            if (launchIntent == null) {
                result.success(mapOf(
                    "success" to false,
                    "error" to "无法启动应用"
                ))
                return
            }
            
            // 添加文件路径
            if (filePath != null) {
                val fileUri = Uri.parse("file://$filePath")
                launchIntent.data = fileUri
                
                // 根据工具类型设置 Intent
                when (packageName) {
                    "bin.mt.plus" -> {
                        // MT Manager
                        launchIntent.action = when (action) {
                            "decompile" -> "bin.mt.plus.DECOMPILE"
                            "edit" -> "bin.mt.plus.EDIT"
                            else -> Intent.ACTION_VIEW
                        }
                        launchIntent.setDataAndType(fileUri, "application/vnd.android.package-archive")
                    }
                    
                    "com.mod.apt" -> {
                        // APK Editor Pro
                        launchIntent.action = Intent.ACTION_VIEW
                        launchIntent.setDataAndType(fileUri, "application/vnd.android.package-archive")
                    }
                    
                    "com.termux" -> {
                        // Termux
                        if (extras?.containsKey("command") == true) {
                            launchIntent.action = "com.termux.RUN_COMMAND"
                            launchIntent.putExtra("com.termux.RUN_COMMAND", extras["command"] as String)
                        }
                    }
                    
                    else -> {
                        launchIntent.action = Intent.ACTION_VIEW
                        launchIntent.setDataAndType(fileUri, "*/*")
                    }
                }
            }
            
            // 添加额外参数
            extras?.forEach { (key, value) ->
                when (value) {
                    is String -> launchIntent.putExtra(key, value)
                    is Boolean -> launchIntent.putExtra(key, value)
                    is Int -> launchIntent.putExtra(key, value)
                    is Long -> launchIntent.putExtra(key, value)
                }
            }
            
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            
            context.startActivity(launchIntent)
            
            result.success(mapOf("success" to true))
        } catch (e: Exception) {
            result.success(mapOf(
                "success" to false,
                "error" to (e.message ?: "启动失败"))
            )
        }
    }
    
    private val pm: PackageManager
        get() = context.packageManager
    
    private fun checkShizuku(result: Result) {
        try {
            val shizukuPkg = "rikka.shizuku"
            pm.getPackageInfo(shizukuPkg, PackageManager.GET_ACTIVITIES)
            
            // 检查 Shizuku 是否运行
            // 需要通过 Shizuku API 检查，这里简化处理
            result.success(mapOf(
                "status" to "not_running",
                "version" to "unknown"
            ))
        } catch (e: PackageManager.NameNotFoundException) {
            result.success(mapOf(
                "status" to "not_installed"
            ))
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        }
    }
    
    private fun requestShizukuPermission(result: Result) {
        try {
            // 尝试启动 Shizuku 并请求权限
            val intent = Intent("rikka.shizuku.permission.RUN_AS_REQUEST")
            intent.setPackage("rikka.shizuku")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            
            context.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.success(false)
        }
    }
    
    private fun executeWithShizuku(command: String, result: Result) {
        // 注意：实际使用 Shizuku 需要通过 Binder API
        // 这里只是一个示例实现
        scope.launch {
            try {
                // 由于 Shizuku API 需要特殊处理，这里返回模拟结果
                // 实际实现需要使用 Shizuku 的 Java API
                result.success("// Shizuku execution requires additional setup\n$command")
            } catch (e: Exception) {
                result.error("SHIZUKU_ERROR", e.message, null)
            }
        }
    }
    
    private fun isPackageVisible(packageName: String): Boolean {
        return try {
            pm.getApplicationInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }
    
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        scope.cancel()
    }
}
