package com.example.brainrot

import android.accessibilityservice.AccessibilityService
import android.content.ComponentName
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class AppDetectionService : AccessibilityService() {
    
    companion object {
        private const val TAG = "AppDetectionService"
    }
    
    private var lastPackageName: String? = null
    private var blockingService: AppBlockingService? = null
    
    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "AppDetectionService connected")
        
        // Start the blocking service
        AppBlockingService.startService(this)
    }
    
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                handleWindowStateChanged(event)
            }
        }
    }
    
    private fun handleWindowStateChanged(event: AccessibilityEvent) {
        val packageName = event.packageName?.toString()
        val className = event.className?.toString()
        
        if (packageName == null || className == null) return
        
        // Skip system UI and our own app
        if (packageName == "com.android.systemui" || 
            packageName == "com.brainrot.nguyentrung" ||
            packageName == applicationContext.packageName) {
            return
        }
        
        // Skip if it's the same app as before
        if (packageName == lastPackageName) return
        
        lastPackageName = packageName
        
        Log.d(TAG, "App opened: $packageName")
        
        // Check if this app should be blocked
        checkAndBlockApp(packageName)
    }
    
    private fun checkAndBlockApp(packageName: String) {
        try {
            // Use static method to check blocking without creating new instance
            val shouldBlock = shouldBlockPackage(packageName)
            
            if (shouldBlock.first) {
                Log.d(TAG, "Blocking app: $packageName - ${shouldBlock.second}")
                showBlockScreen(packageName, shouldBlock.second, shouldBlock.third)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking if app should be blocked", e)
        }
    }
    
    private fun shouldBlockPackage(packageName: String): Triple<Boolean, String, Boolean> {
        try {
            // Read blocking data from SharedPreferences directly
            val prefs = getSharedPreferences("flutter.com.brainrot.nguyentrung", MODE_PRIVATE)
            
            Log.d(TAG, "Checking if package should be blocked: $packageName")
            
            // Check focus modes first
            val focusModesJson = prefs.getString("flutter.focus_modes", null)
            Log.d(TAG, "Focus modes JSON: $focusModesJson")
            
            if (focusModesJson != null) {
                val focusModesArray = org.json.JSONArray(focusModesJson)
                for (i in 0 until focusModesArray.length()) {
                    val focusModeJson = focusModesArray.getJSONObject(i)
                    if (focusModeJson.optBoolean("isActive", false)) {
                        Log.d(TAG, "Found active focus mode: ${focusModeJson.getString("name")}")
                        // Check if this focus mode blocks the package
                        val blockedPackagesArray = focusModeJson.optJSONArray("blockedPackages")
                        if (blockedPackagesArray != null) {
                            for (j in 0 until blockedPackagesArray.length()) {
                                if (blockedPackagesArray.getString(j) == packageName) {
                                    Log.d(TAG, "Package blocked by focus mode")
                                    return Triple(
                                        true,
                                        "Blocked by ${focusModeJson.getString("name")}",
                                        focusModeJson.optBoolean("allowEmergency", true)
                                    )
                                }
                            }
                        }
                    }
                }
            }
            
            // Check blocking rules
            val rulesJson = prefs.getString("flutter.blocking_rules", null)
            Log.d(TAG, "Blocking rules JSON: $rulesJson")
            
            if (rulesJson != null) {
                val rulesArray = org.json.JSONArray(rulesJson)
                Log.d(TAG, "Found ${rulesArray.length()} blocking rules")
                
                for (i in 0 until rulesArray.length()) {
                    val ruleJson = rulesArray.getJSONObject(i)
                    val ruleStatus = ruleJson.getString("status")
                    val ruleName = ruleJson.getString("name")
                    
                    Log.d(TAG, "Rule: $ruleName, Status: $ruleStatus")
                    
                    if (ruleStatus == "active") {
                        val targetPackagesArray = ruleJson.optJSONArray("targetPackages")
                        if (targetPackagesArray != null) {
                            Log.d(TAG, "Rule has ${targetPackagesArray.length()} target packages")
                            for (j in 0 until targetPackagesArray.length()) {
                                val targetPackage = targetPackagesArray.getString(j)
                                Log.d(TAG, "Checking target package: $targetPackage")
                                if (targetPackage == packageName) {
                                    Log.d(TAG, "Package blocked by rule: $ruleName")
                                    return Triple(
                                        true,
                                        ruleJson.optString("customBlockMessage", "Blocked by $ruleName"),
                                        ruleJson.optBoolean("allowEmergencyBypass", false)
                                    )
                                }
                            }
                        }
                    }
                }
            }
            
            Log.d(TAG, "Package not blocked: $packageName")
            return Triple(false, "", false)
        } catch (e: Exception) {
            Log.e(TAG, "Error checking blocking rules", e)
            return Triple(false, "", false)
        }
    }
    
    private fun showBlockScreen(packageName: String, reason: String, canBypass: Boolean) {
        try {
            val intent = Intent(this, BlockOverlayActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra("blocked_package", packageName)
                putExtra("block_reason", reason)
                putExtra("can_bypass", canBypass)
            }
            
            startActivity(intent)
            
            // Also try to go back to home screen
            goToHomeScreen()
        } catch (e: Exception) {
            Log.e(TAG, "Error showing block screen", e)
        }
    }
    
    private fun goToHomeScreen() {
        try {
            val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(homeIntent)
        } catch (e: Exception) {
            Log.e(TAG, "Error going to home screen", e)
        }
    }
    
    override fun onInterrupt() {
        Log.d(TAG, "AppDetectionService interrupted")
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "AppDetectionService destroyed")
    }
}
