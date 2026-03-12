package com.example.brainrot

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall
import java.io.ByteArrayOutputStream
import java.util.*
import kotlin.collections.HashMap

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.brainrot/usage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Start the app blocking service
        AppBlockingService.startService(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasUsagePermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "requestUsagePermission" -> {
                    requestUsageStatsPermission()
                    result.success(true)
                }
                "getUsageStats" -> {
                    val usageData = getTodayUsageStats()
                    result.success(usageData)
                }
                "refreshUsageStats" -> {
                    // Force refresh by getting fresh data
                    val usageData = getTodayUsageStats()
                    result.success(usageData)
                }
                "getCurrentTimeInfo" -> {
                    val currentTime = System.currentTimeMillis()
                    val calendar = Calendar.getInstance()
                    calendar.timeInMillis = currentTime

                    result.success(mapOf(
                        "currentTime" to currentTime,
                        "hour" to calendar.get(Calendar.HOUR_OF_DAY),
                        "minute" to calendar.get(Calendar.MINUTE),
                        "day" to calendar.get(Calendar.DAY_OF_MONTH),
                        "month" to calendar.get(Calendar.MONTH) + 1,
                        "year" to calendar.get(Calendar.YEAR)
                    ))
                }
                "getAppIcon" -> {
                    getAppIcon(call, result)
                }
                "getMultipleAppIcons" -> {
                    getMultipleAppIcons(call, result)
                }
                "startBlockingService" -> {
                    AppBlockingService.startService(this)
                    result.success(true)
                }
                "stopBlockingService" -> {
                    AppBlockingService.stopService(this)
                    result.success(true)
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(true)
                }
                "hasOverlayPermission" -> {
                    result.success(hasOverlayPermission())
                }
                "requestAccessibilityPermission" -> {
                    requestAccessibilityPermission()
                    result.success(true)
                }
                "hasAccessibilityPermission" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsageStatsPermission() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.data = android.net.Uri.parse("package:$packageName")
        startActivity(intent)
    }

    private fun getTodayUsageStats(): List<Map<String, Any>> {
        if (!hasUsageStatsPermission()) {
            return emptyList()
        }

        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val packageManager = packageManager

        // Get today's start and end time
        val calendar = Calendar.getInstance()
        val currentTime = System.currentTimeMillis()

        // Reset to start of today (00:00:00)
        calendar.timeInMillis = currentTime
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis

        // ✅ GIẢI PHÁP 1: Dùng UsageEvents để tính chính xác
        // UsageEvents track từng event cụ thể, chính xác hơn UsageStats
        val appUsageMap = calculateUsageFromEvents(usageStatsManager, startTime, currentTime)

        // ✅ GIẢI PHÁP 2: Fallback dùng INTERVAL_BEST nếu UsageEvents không đủ data
        if (appUsageMap.isEmpty()) {
            Log.d("BRAINROT", "UsageEvents empty, using INTERVAL_BEST fallback")
            return getUsageStatsWithBestInterval(usageStatsManager, packageManager, startTime, currentTime)
        }

        val result = mutableListOf<Map<String, Any>>()

        for ((packageName, usageTime) in appUsageMap) {
            // ✅ GIẢI PHÁP 3: Giảm threshold xuống 10 giây (10000ms)
            if (usageTime > 10000) {
                try {
                    val appInfo = packageManager.getApplicationInfo(packageName, 0)
                    val appName = packageManager.getApplicationLabel(appInfo).toString()

                    result.add(mapOf(
                        "packageName" to packageName,
                        "appName" to appName,
                        "usageTimeMillis" to usageTime,
                        "lastTimeUsed" to currentTime,
                        "firstTimeStamp" to startTime
                    ))

                    Log.d("BRAINROT", "App: $appName, Usage: ${usageTime / 1000}s")
                } catch (e: PackageManager.NameNotFoundException) {
                    // App might be uninstalled, skip
                }
            }
        }

        Log.d("BRAINROT", "Total apps tracked: ${result.size}")

        // Sort by usage time descending
        return result.sortedByDescending { it["usageTimeMillis"] as Long }
    }

    /**
     * ✅ GIẢI PHÁP 1: Calculate usage time from UsageEvents (CHÍNH XÁC NHẤT)
     * Track từng ACTIVITY_RESUMED và ACTIVITY_PAUSED event
     */
    private fun calculateUsageFromEvents(
        usageStatsManager: UsageStatsManager,
        startTime: Long,
        endTime: Long
    ): MutableMap<String, Long> {
        val appUsageMap = mutableMapOf<String, Long>()
        val appSessionMap = mutableMapOf<String, Long>() // Track session start time

        try {
            val usageEvents = usageStatsManager.queryEvents(startTime, endTime)
            val event = UsageEvents.Event()

            while (usageEvents.hasNextEvent()) {
                usageEvents.getNextEvent(event)

                when (event.eventType) {
                    UsageEvents.Event.ACTIVITY_RESUMED -> {
                        // App moved to foreground
                        appSessionMap[event.packageName] = event.timeStamp
                        Log.v("BRAINROT_EVENTS", "${event.packageName} RESUMED at ${event.timeStamp}")
                    }
                    UsageEvents.Event.ACTIVITY_PAUSED,
                    UsageEvents.Event.ACTIVITY_STOPPED -> {
                        // App moved to background
                        val sessionStart = appSessionMap[event.packageName]
                        if (sessionStart != null && sessionStart >= startTime) {
                            val sessionDuration = event.timeStamp - sessionStart
                            if (sessionDuration > 0) {
                                val currentUsage = appUsageMap[event.packageName] ?: 0L
                                appUsageMap[event.packageName] = currentUsage + sessionDuration
                                Log.v("BRAINROT_EVENTS", "${event.packageName} PAUSED, session: ${sessionDuration}ms")
                            }
                            appSessionMap.remove(event.packageName)
                        }
                    }
                }
            }

            // Handle apps still in foreground (chưa có PAUSED event)
            val currentTime = System.currentTimeMillis()
            for ((packageName, sessionStart) in appSessionMap) {
                if (sessionStart >= startTime) {
                    val sessionDuration = currentTime - sessionStart
                    if (sessionDuration > 0) {
                        val currentUsage = appUsageMap[packageName] ?: 0L
                        appUsageMap[packageName] = currentUsage + sessionDuration
                        Log.v("BRAINROT_EVENTS", "$packageName still active, duration: ${sessionDuration}ms")
                    }
                }
            }

            Log.d("BRAINROT", "UsageEvents processed: ${appUsageMap.size} apps")

        } catch (e: Exception) {
            Log.e("BRAINROT", "Error processing UsageEvents: ${e.message}")
        }

        return appUsageMap
    }

    /**
     * ✅ GIẢI PHÁP 2: Fallback using INTERVAL_BEST (CÂN BẰNG)
     * Android tự chọn interval chính xác nhất
     */
    private fun getUsageStatsWithBestInterval(
        usageStatsManager: UsageStatsManager,
        packageManager: PackageManager,
        startTime: Long,
        endTime: Long
    ): List<Map<String, Any>> {
        // Dùng INTERVAL_BEST thay vì INTERVAL_DAILY
        val usageStats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_BEST,
            startTime,
            endTime
        )

        val result = mutableListOf<Map<String, Any>>()

        for (usageStat in usageStats) {
            // ✅ GIẢI PHÁP 3: Giảm threshold xuống 10 giây (10000ms)
            if (usageStat.totalTimeInForeground > 10000 && usageStat.lastTimeUsed >= startTime) {
                try {
                    val appInfo = packageManager.getApplicationInfo(usageStat.packageName, 0)
                    val appName = packageManager.getApplicationLabel(appInfo).toString()

                    result.add(mapOf(
                        "packageName" to usageStat.packageName,
                        "appName" to appName,
                        "usageTimeMillis" to usageStat.totalTimeInForeground,
                        "lastTimeUsed" to usageStat.lastTimeUsed,
                        "firstTimeStamp" to usageStat.firstTimeStamp
                    ))

                    Log.d("BRAINROT", "INTERVAL_BEST - $appName: ${usageStat.totalTimeInForeground / 1000}s")
                } catch (e: PackageManager.NameNotFoundException) {
                    // Skip
                }
            }
        }

        return result.sortedByDescending { it["usageTimeMillis"] as Long }
    }

    private fun getAppIcon(call: MethodCall, result: MethodChannel.Result) {
        try {
            val packageName = call.argument<String>("packageName")
            if (packageName == null) {
                result.error("INVALID_ARGUMENT", "Package name is required", null)
                return
            }

            val iconBytes = getAppIconBytes(packageName)
            if (iconBytes != null) {
                result.success(iconBytes.map { it.toInt() and 0xFF })
            } else {
                result.error("ICON_NOT_FOUND", "Could not get icon for $packageName", null)
            }
        } catch (e: Exception) {
            Log.e("BRAINROT", "Error getting app icon: ${e.message}")
            result.error("ERROR", "Error getting app icon: ${e.message}", null)
        }
    }

    private fun getMultipleAppIcons(call: MethodCall, result: MethodChannel.Result) {
        try {
            val packageNames = call.argument<List<String>>("packageNames")
            if (packageNames == null) {
                result.error("INVALID_ARGUMENT", "Package names list is required", null)
                return
            }

            val iconsMap = mutableMapOf<String, List<Int>?>()

            for (packageName in packageNames) {
                val iconBytes = getAppIconBytes(packageName)
                iconsMap[packageName] = iconBytes?.map { it.toInt() and 0xFF }
            }

            result.success(iconsMap)
        } catch (e: Exception) {
            Log.e("BRAINROT", "Error getting multiple app icons: ${e.message}")
            result.error("ERROR", "Error getting multiple app icons: ${e.message}", null)
        }
    }

    private fun getAppIconBytes(packageName: String): ByteArray? {
        return try {
            Log.d("BRAINROT", "Attempting to get icon for: $packageName")
            val packageManager = applicationContext.packageManager
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            val drawable = packageManager.getApplicationIcon(appInfo)

            Log.d("BRAINROT", "Got drawable for $packageName: ${drawable.javaClass.simpleName}")

            // Convert drawable to bitmap
            val bitmap = when (drawable) {
                is BitmapDrawable -> {
                    Log.d("BRAINROT", "Using BitmapDrawable for $packageName")
                    drawable.bitmap
                }
                else -> {
                    val width = drawable.intrinsicWidth.takeIf { it > 0 } ?: 128
                    val height = drawable.intrinsicHeight.takeIf { it > 0 } ?: 128
                    Log.d("BRAINROT", "Creating bitmap for $packageName: ${width}x${height}")

                    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                    val canvas = Canvas(bitmap)
                    drawable.setBounds(0, 0, canvas.width, canvas.height)
                    drawable.draw(canvas)
                    bitmap
                }
            }

            // Convert bitmap to byte array
            val outputStream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
            val bytes = outputStream.toByteArray()

            Log.d("BRAINROT", "Successfully converted icon for $packageName to ${bytes.size} bytes")
            bytes

        } catch (e: Exception) {
            Log.e("BRAINROT", "Error getting icon for $packageName: ${e.message}", e)
            null
        }
    }

    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                android.net.Uri.parse("package:$packageName")
            )
            startActivity(intent)
        }
    }

    private fun requestAccessibilityPermission() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        startActivity(intent)
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expectedComponentName = ComponentName(this, AppDetectionService::class.java)
        val enabledServicesSetting = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        val colonSplitter = TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabledServicesSetting)

        while (colonSplitter.hasNext()) {
            val componentNameString = colonSplitter.next()
            val enabledService = ComponentName.unflattenFromString(componentNameString)

            if (enabledService != null && enabledService == expectedComponentName) {
                return true
            }
        }

        return false
    }
}
