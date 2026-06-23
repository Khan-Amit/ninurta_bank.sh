package com.marduk.miner;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import org.json.JSONObject;

public class NativeMiner {
    private static final String TAG = "NativeMiner";
    private static NativeMiner instance;
    private Handler handler;
    private MiningListener listener;
    private boolean isMining = false;
    
    // Native methods
    static {
        System.loadLibrary("marduk_miner");
    }
    
    public native void initMiner();
    public native void startMining();
    public native void stopMining();
    public native void setCrypto(String crypto);
    public native String getStats();
    public native void cleanup();
    
    // Interface for UI updates
    public interface MiningListener {
        void onStatsUpdate(String stats);
        void onLogUpdate(String message);
    }
    
    private NativeMiner() {
        handler = new Handler(Looper.getMainLooper());
        initMiner();
    }
    
    public static NativeMiner getInstance() {
        if (instance == null) {
            instance = new NativeMiner();
        }
        return instance;
    }
    
    public void setListener(MiningListener listener) {
        this.listener = listener;
    }
    
    public void start() {
        if (isMining) return;
        isMining = true;
        startMining();
        startStatsUpdate();
        log("⛏️ Mining started!");
    }
    
    public void stop() {
        if (!isMining) return;
        isMining = false;
        stopMining();
        log("⏹️ Mining stopped!");
    }
    
    public void changeCrypto(String crypto) {
        setCrypto(crypto);
        log("🔄 Switched to " + crypto);
    }
    
    private void startStatsUpdate() {
        handler.post(new Runnable() {
            @Override
            public void run() {
                if (!isMining) return;
                
                try {
                    String statsJson = getStats();
                    if (listener != null) {
                        listener.onStatsUpdate(statsJson);
                    }
                    
                    // Parse and log stats
                    JSONObject stats = new JSONObject(statsJson);
                    log(String.format("⛏️ %.0f H/s | Shares: %d | %.8f %s",
                            stats.getDouble("hashrate"),
                            stats.getInt("shares"),
                            stats.getDouble("earnings"),
                            stats.getString("crypto")));
                    
                } catch (Exception e) {
                    Log.e(TAG, "Error updating stats", e);
                }
                
                // Update every 5 seconds
                handler.postDelayed(this, 5000);
            }
        });
    }
    
    private void log(String message) {
        if (listener != null) {
            handler.post(() -> listener.onLogUpdate(message));
        }
        Log.d(TAG, message);
    }
    
    public void destroy() {
        stop();
        cleanup();
        instance = null;
    }
}
