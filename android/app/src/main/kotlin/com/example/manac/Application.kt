package com.example.manac

import android.app.Application
import androidx.work.Configuration
import androidx.work.WorkManager

class Application : Application(), Configuration.Provider {
    override fun onCreate() {
        super.onCreate()
        // Initialize WorkManager with default configuration
        WorkManager.initialize(this, workManagerConfiguration)
    }

    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder()
            .setMinimumLoggingLevel(android.util.Log.INFO)
            .build()
}
