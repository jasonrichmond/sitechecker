package com.example.sitechecker; // Replace this with your actual package name

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import androidx.work.OneTimeWorkRequest;
import androidx.work.WorkManager;

public class BootBroadcastReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())) {
            // Enqueue a one-time work request to ensure WorkManager gets initialized
            WorkManager.getInstance(context).enqueue(OneTimeWorkRequest.from(InitializeWorker.class));
        }
    }
}
