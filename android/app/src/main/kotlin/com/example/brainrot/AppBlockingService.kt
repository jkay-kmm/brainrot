package com.example.brainrot

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import org.json.JSONArray
import org.json.JSONObject

class AppBlockingService : Service() {
    
    companion object {
        private const val TAG = "AppBlockingService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "app_blocking_channel"
        private const val PREFS_NAME = "flutter.brainrot"
        private const val KEY_BLOCKING_RULES = "flutter.blocking_rules"
        private const val KEY_FOCUS_MODES = "flutter.focus_modes"
        
        fun startService(context: Context) {
            val intent = Intent(context, AppBlockingService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
        
        fun stopService(context: Context) {
            val intent = Intent(context, AppBlockingService::class.java)
            context.stopService(intent)
        }
    }
    
    private lateinit var prefs: SharedPreferences
    private var serviceJob = SupervisorJob()
    private val serviceScope = CoroutineScope(Dispatchers.Main + serviceJob)
    
    private var blockingRules = mutableListOf<BlockingRule>()
    private var focusModes = mutableListOf<FocusMode>()
    private var activeFocusMode: FocusMode? = null
    
    private var lastRuleCount = 0
    private var lastFocusModeCount = 0
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "AppBlockingService created")
        
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        createNotificationChannel()
        loadBlockingData()
        
        // Start monitoring
        startMonitoring()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "AppBlockingService started")
        
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "AppBlockingService destroyed")
        serviceJob.cancel()
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                getString(R.string.notification_channel_name),
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = getString(R.string.notification_channel_description)
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(getString(R.string.notification_service_title))
            .setContentText(getString(R.string.notification_service_content))
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .build()
    }
    
    private fun loadBlockingData() {
        try {
            // Load blocking rules
            val rulesJson = prefs.getString(KEY_BLOCKING_RULES, null)
            if (rulesJson != null) {
                val rulesArray = JSONArray(rulesJson)
                blockingRules.clear()
                for (i in 0 until rulesArray.length()) {
                    val ruleJson = rulesArray.getJSONObject(i)
                    blockingRules.add(BlockingRule.fromJson(ruleJson))
                }
            }
            
            // Load focus modes
            val focusModesJson = prefs.getString(KEY_FOCUS_MODES, null)
            if (focusModesJson != null) {
                val focusModesArray = JSONArray(focusModesJson)
                focusModes.clear()
                for (i in 0 until focusModesArray.length()) {
                    val focusModeJson = focusModesArray.getJSONObject(i)
                    val focusMode = FocusMode.fromJson(focusModeJson)
                    focusModes.add(focusMode)
                    
                    if (focusMode.isActive) {
                        activeFocusMode = focusMode
                    }
                }
            }
            
            // Only log if count changed
            if (blockingRules.size != lastRuleCount || focusModes.size != lastFocusModeCount) {
                Log.d(TAG, "Loaded ${blockingRules.size} rules and ${focusModes.size} focus modes")
                lastRuleCount = blockingRules.size
                lastFocusModeCount = focusModes.size
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error loading blocking data", e)
        }
    }
    
    private fun startMonitoring() {
        serviceScope.launch {
            while (isActive) {
                try {
                    // Reload data periodically to sync with Flutter app
                    loadBlockingData()
                    
                    // Check if any focus mode has expired
                    checkFocusModeExpiry()
                    
                    delay(5000) // Check every 5 seconds
                } catch (e: Exception) {
                    Log.e(TAG, "Error in monitoring loop", e)
                    delay(10000) // Wait longer on error
                }
            }
        }
    }
    
    private fun checkFocusModeExpiry() {
        activeFocusMode?.let { focusMode ->
            if (focusMode.endTime != null && System.currentTimeMillis() > focusMode.endTime) {
                Log.d(TAG, "Focus mode ${focusMode.name} expired")
                activeFocusMode = null
                
                // Update the focus mode in storage
                val updatedFocusMode = focusMode.copy(isActive = false)
                updateFocusModeInStorage(updatedFocusMode)
            }
        }
    }
    
    private fun updateFocusModeInStorage(updatedFocusMode: FocusMode) {
        try {
            val index = focusModes.indexOfFirst { it.id == updatedFocusMode.id }
            if (index != -1) {
                focusModes[index] = updatedFocusMode
                
                val focusModesArray = JSONArray()
                focusModes.forEach { focusMode ->
                    focusModesArray.put(focusMode.toJson())
                }
                
                prefs.edit()
                    .putString(KEY_FOCUS_MODES, focusModesArray.toString())
                    .apply()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error updating focus mode in storage", e)
        }
    }
    
    fun shouldBlockApp(packageName: String): BlockResult {
        try {
            // Check active focus mode first
            activeFocusMode?.let { focusMode ->
                if (focusMode.shouldBlockPackage(packageName)) {
                    return BlockResult(
                        shouldBlock = true,
                        reason = "Blocked by ${focusMode.name}",
                        canBypass = focusMode.allowEmergency
                    )
                }
            }
            
            // Check blocking rules
            for (rule in blockingRules) {
                if (rule.isActive && rule.shouldBlockPackage(packageName)) {
                    return BlockResult(
                        shouldBlock = true,
                        reason = rule.customBlockMessage ?: "Blocked by ${rule.name}",
                        canBypass = rule.allowEmergencyBypass
                    )
                }
            }
            
            return BlockResult(shouldBlock = false)
        } catch (e: Exception) {
            Log.e(TAG, "Error checking if app should be blocked", e)
            return BlockResult(shouldBlock = false)
        }
    }
    
    data class BlockResult(
        val shouldBlock: Boolean,
        val reason: String = "",
        val canBypass: Boolean = false
    )
    
    // Data classes for blocking rules and focus modes
    data class BlockingRule(
        val id: String,
        val name: String,
        val type: String,
        val targetPackages: List<String>,
        val isActive: Boolean,
        val customBlockMessage: String?,
        val allowEmergencyBypass: Boolean,
        val startTime: String?,
        val endTime: String?,
        val daysOfWeek: List<Int>?
    ) {
        companion object {
            fun fromJson(json: JSONObject): BlockingRule {
                val targetPackagesArray = json.optJSONArray("targetPackages")
                val targetPackages = mutableListOf<String>()
                targetPackagesArray?.let {
                    for (i in 0 until it.length()) {
                        targetPackages.add(it.getString(i))
                    }
                }
                
                val daysOfWeekArray = json.optJSONArray("daysOfWeek")
                val daysOfWeek = mutableListOf<Int>()
                daysOfWeekArray?.let {
                    for (i in 0 until it.length()) {
                        daysOfWeek.add(it.getInt(i))
                    }
                }
                
                return BlockingRule(
                    id = json.getString("id"),
                    name = json.getString("name"),
                    type = json.getString("type"),
                    targetPackages = targetPackages,
                    isActive = json.getString("status") == "active",
                    customBlockMessage = json.optString("customBlockMessage", null),
                    allowEmergencyBypass = json.optBoolean("allowEmergencyBypass", false),
                    startTime = json.optString("startTime", null),
                    endTime = json.optString("endTime", null),
                    daysOfWeek = if (daysOfWeek.isEmpty()) null else daysOfWeek
                )
            }
        }
        
        fun shouldBlockPackage(packageName: String): Boolean {
            if (!targetPackages.contains(packageName)) return false
            
            return when (type) {
                "allDayBlock" -> true
                "schedule" -> isInScheduledTime()
                "timeLimit" -> true // Would need additional logic for time tracking
                else -> false
            }
        }
        
        private fun isInScheduledTime(): Boolean {
            if (startTime == null || endTime == null) return true
            
            // Check if today is in the allowed days
            daysOfWeek?.let { days ->
                val today = java.util.Calendar.getInstance().get(java.util.Calendar.DAY_OF_WEEK)
                val mondayBasedToday = if (today == 1) 7 else today - 1 // Convert to Monday=1 format
                if (!days.contains(mondayBasedToday)) return false
            }
            
            // Check time range
            try {
                val now = java.util.Calendar.getInstance()
                val currentMinutes = now.get(java.util.Calendar.HOUR_OF_DAY) * 60 + now.get(java.util.Calendar.MINUTE)
                
                val startParts = startTime.split(":")
                val startMinutes = startParts[0].toInt() * 60 + startParts[1].toInt()
                
                val endParts = endTime.split(":")
                val endMinutes = endParts[0].toInt() * 60 + endParts[1].toInt()
                
                return if (startMinutes <= endMinutes) {
                    currentMinutes in startMinutes..endMinutes
                } else {
                    currentMinutes >= startMinutes || currentMinutes <= endMinutes
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error parsing time", e)
                return true
            }
        }
    }
    
    data class FocusMode(
        val id: String,
        val name: String,
        val allowedPackages: List<String>,
        val blockedPackages: List<String>,
        val isActive: Boolean,
        val endTime: Long?,
        val allowEmergency: Boolean
    ) {
        companion object {
            fun fromJson(json: JSONObject): FocusMode {
                val allowedPackagesArray = json.optJSONArray("allowedPackages")
                val allowedPackages = mutableListOf<String>()
                allowedPackagesArray?.let {
                    for (i in 0 until it.length()) {
                        allowedPackages.add(it.getString(i))
                    }
                }
                
                val blockedPackagesArray = json.optJSONArray("blockedPackages")
                val blockedPackages = mutableListOf<String>()
                blockedPackagesArray?.let {
                    for (i in 0 until it.length()) {
                        blockedPackages.add(it.getString(i))
                    }
                }
                
                val endTimeString = json.optString("endTime", null)
                val endTime = endTimeString?.let {
                    try {
                        java.time.Instant.parse(it).toEpochMilli()
                    } catch (e: Exception) {
                        null
                    }
                }
                
                return FocusMode(
                    id = json.getString("id"),
                    name = json.getString("name"),
                    allowedPackages = allowedPackages,
                    blockedPackages = blockedPackages,
                    isActive = json.optBoolean("isActive", false),
                    endTime = endTime,
                    allowEmergency = json.optBoolean("allowEmergency", true)
                )
            }
        }
        
        fun shouldBlockPackage(packageName: String): Boolean {
            // If there are allowed packages, only allow those
            if (allowedPackages.isNotEmpty()) {
                return !allowedPackages.contains(packageName)
            }
            
            // Otherwise, block packages in the blocked list
            return blockedPackages.contains(packageName)
        }
        
        fun toJson(): JSONObject {
            val json = JSONObject()
            json.put("id", id)
            json.put("name", name)
            json.put("isActive", isActive)
            json.put("allowEmergency", allowEmergency)
            
            val allowedArray = JSONArray()
            allowedPackages.forEach { allowedArray.put(it) }
            json.put("allowedPackages", allowedArray)
            
            val blockedArray = JSONArray()
            blockedPackages.forEach { blockedArray.put(it) }
            json.put("blockedPackages", blockedArray)
            
            endTime?.let {
                json.put("endTime", java.time.Instant.ofEpochMilli(it).toString())
            }
            
            return json
        }
    }
}
