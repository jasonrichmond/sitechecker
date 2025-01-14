package com.example.sitechecker;

import android.content.Context;
import androidx.annotation.NonNull;
import androidx.work.Worker;
import androidx.work.WorkerParameters;

public class InitializeWorker extends Worker {
    public InitializeWorker(@NonNull Context context, @NonNull WorkerParameters params) {
        super(context, params);
    }

    @NonNull
    @Override
    public Result doWork() {
        // Add any logic you need to initialize WorkManager tasks here
        return Result.success();
    }
}
