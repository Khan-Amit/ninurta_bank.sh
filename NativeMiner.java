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
    private String currentCrypto = "XMR";
    
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
    public native void setWallet(String wallet);
    public native void setPool(String pool);
    
    // Interface for UI updates
    public interface MiningListener {
        void onStatsUpdate(String stats);
        void onLogUpdate(String message);
        void onEarningsUpdate(double earnings);
    }
    
    private NativeMiner() {
        handler = new Handler(Looper.getMainLooper());
        initMiner();
        // ✅ NEW WALLET ADDRESS
        setWallet("45ktWDeTNtUcVMXfJRKS6bbXMznMAStZFX6niJHcVy9uQk132bHJ21QTC5AKvqyx9XJN5e7mPc3vViyGnB2BM6DD1ZoAoZb");
        setPool("pool.supportxmr.com:443");
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
        if (isMining) {
            log("⛏️ Already mining!");
            return;
        }
        isMining = true;
        startMining();
        startStatsUpdate();
        log("⛏️ Mining started!");
        log("📤 Wallet: 45ktWDeTNtUc...ZoAoZb");
        log("🔗 Pool: pool.supportxmr.com:443");
        log("⏳ Waiting for shares... (24-48 hrs for first)");
    }
    
    public void stop() {
        if (!isMining) {
            log("⛏️ Mining not active!");
            return;
        }
        isMining = false;
        stopMining();
        log("⏹️ Mining stopped!");
    }
    
    public void changeCrypto(String crypto) {
        currentCrypto = crypto;
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
                    double hashrate = stats.getDouble("hashrate");
                    int shares = stats.getInt("shares");
                    double earnings = stats.getDouble("earnings");
                    String crypto = stats.getString("crypto");
                    
                    if (hashrate > 0) {
                        log(String.format("⛏️ %.0f H/s | Shares: %d | %.8f %s",
                                hashrate, shares, earnings, crypto));
                    } else {
                        log("⏳ Connecting to pool... (hashrate: 0 H/s)");
                    }
                    
                    if (listener != null) {
                        listener.onEarningsUpdate(earnings);
                    }
                    
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
    
    public String getWallet() {
        return "45ktWDeTNtUcVMXfJRKS6bbXMznMAStZFX6niJHcVy9uQk132bHJ21QTC5AKvqyx9XJN5e7mPc3vViyGnB2BM6DD1ZoAoZb";
    }
    
    public String getPool() {
        return "pool.supportxmr.com:443";
    }
}
