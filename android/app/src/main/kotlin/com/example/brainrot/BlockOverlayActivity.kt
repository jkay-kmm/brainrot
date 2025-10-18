package com.example.brainrot

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView

class BlockOverlayActivity : Activity() {
    
    companion object {
        private const val TAG = "BlockOverlayActivity"
    }
    
    private var blockedPackage: String? = null
    private var blockReason: String? = null
    private var canBypass: Boolean = false
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Make this activity appear over other apps
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        
        // Get intent data
        blockedPackage = intent.getStringExtra("blocked_package")
        blockReason = intent.getStringExtra("block_reason")
        canBypass = intent.getBooleanExtra("can_bypass", false)
        
        Log.d(TAG, "Showing block screen for: $blockedPackage")
        
        setupUI()
    }
    
    private fun setupUI() {
        // Create a simple layout programmatically
        val layout = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            setPadding(64, 64, 64, 64)
            setBackgroundColor(android.graphics.Color.parseColor("#FFE4B5"))
        }
        
        // App blocked icon/image
        val iconView = android.widget.ImageView(this).apply {
            setImageResource(android.R.drawable.ic_dialog_alert)
            layoutParams = android.widget.LinearLayout.LayoutParams(
                200, 200
            ).apply {
                gravity = android.view.Gravity.CENTER_HORIZONTAL
                bottomMargin = 32
            }
        }
        layout.addView(iconView)
        
        // Title
        val titleView = TextView(this).apply {
            text = getString(R.string.block_message_title)
            textSize = 24f
            setTextColor(android.graphics.Color.parseColor("#333333"))
            gravity = android.view.Gravity.CENTER
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 16
            }
        }
        layout.addView(titleView)
        
        // Message
        val messageView = TextView(this).apply {
            text = blockReason ?: getString(R.string.block_message_default)
            textSize = 16f
            setTextColor(android.graphics.Color.parseColor("#666666"))
            gravity = android.view.Gravity.CENTER
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 32
            }
        }
        layout.addView(messageView)
        
        // Buttons container
        val buttonsLayout = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.HORIZONTAL
            gravity = android.view.Gravity.CENTER
        }
        
        // OK Button
        val okButton = Button(this).apply {
            text = getString(R.string.block_button_ok)
            setBackgroundColor(android.graphics.Color.parseColor("#FF6B35"))
            setTextColor(android.graphics.Color.WHITE)
            layoutParams = android.widget.LinearLayout.LayoutParams(
                0,
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
                1f
            ).apply {
                rightMargin = if (canBypass) 16 else 0
            }
            setOnClickListener {
                goToHomeScreen()
                finish()
            }
        }
        buttonsLayout.addView(okButton)
        
        // Emergency Access Button (if allowed)
        if (canBypass) {
            val emergencyButton = Button(this).apply {
                text = getString(R.string.block_button_emergency)
                setBackgroundColor(android.graphics.Color.parseColor("#FF9500"))
                setTextColor(android.graphics.Color.WHITE)
                layoutParams = android.widget.LinearLayout.LayoutParams(
                    0,
                    android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
                    1f
                )
                setOnClickListener {
                    showEmergencyAccessDialog()
                }
            }
            buttonsLayout.addView(emergencyButton)
        }
        
        layout.addView(buttonsLayout)
        
        setContentView(layout)
    }
    
    private fun showEmergencyAccessDialog() {
        val builder = android.app.AlertDialog.Builder(this)
        builder.setTitle("Emergency Access")
        builder.setMessage("Are you sure you need emergency access to this app? This will temporarily override your blocking rules.")
        
        builder.setPositiveButton("Yes, I need access") { _, _ ->
            // Grant temporary access (you could implement a time-limited bypass here)
            Log.d(TAG, "Emergency access granted for: $blockedPackage")
            finish() // Allow the app to continue
        }
        
        builder.setNegativeButton("Cancel") { dialog, _ ->
            dialog.dismiss()
        }
        
        builder.show()
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
    
    override fun onBackPressed() {
        // Prevent back button from bypassing the block
        goToHomeScreen()
        finish()
    }
    
    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        // Handle new intent if the activity is already running
        setIntent(intent)
        
        blockedPackage = intent?.getStringExtra("blocked_package")
        blockReason = intent?.getStringExtra("block_reason")
        canBypass = intent?.getBooleanExtra("can_bypass", false) ?: false
        
        setupUI() // Refresh UI with new data
    }
}
