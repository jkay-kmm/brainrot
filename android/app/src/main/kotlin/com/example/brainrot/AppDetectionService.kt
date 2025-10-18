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
            packageName == "com.example.brainrot" ||
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
            // Get blocking service instance (in a real implementation, you'd use proper service binding)
            val blockingService = AppBlockingService()
            val blockResult = blockingService.shouldBlockApp(packageName)
            
            if (blockResult.shouldBlock) {
                Log.d(TAG, "Blocking app: $packageName - ${blockResult.reason}")
                showBlockScreen(packageName, blockResult.reason, blockResult.canBypass)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking if app should be blocked", e)
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
