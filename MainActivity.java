package com.marduk.miner;

import android.os.Bundle;
import android.os.Handler;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.ScrollView;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.ProgressBar;
import androidx.appcompat.app.AppCompatActivity;
import org.json.JSONObject;

public class MainActivity extends AppCompatActivity 
        implements NativeMiner.MiningListener {
    
    private TextView statsTextView;
    private TextView logTextView;
    private ScrollView logScrollView;
    private Button startButton;
    private Button stopButton;
    private Button checkButton;
    private Spinner cryptoSpinner;
    private ProgressBar miningProgress;
    private TextView earningsTextView;
    private TextView statusTextView;
    private NativeMiner miner;
    private StringBuilder logBuilder = new StringBuilder();
    private Handler uiHandler = new Handler();
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        
        // Initialize UI
        statsTextView = findViewById(R.id.stats_text);
        logTextView = findViewById(R.id.log_text);
        logScrollView = findViewById(R.id.log_scroll);
        startButton = findViewById(R.id.start_button);
        stopButton = findViewById(R.id.stop_button);
        checkButton = findViewById(R.id.check_button);
        cryptoSpinner = findViewById(R.id.crypto_spinner);
        miningProgress = findViewById(R.id.mining_progress);
        earningsTextView = findViewById(R.id.earnings_text);
        statusTextView = findViewById(R.id.status_text);
        
        // Setup crypto spinner
        String[] cryptos = {"Monero (XMR)", "Litecoin (LTC)", "Dogecoin (DOGE)"};
        ArrayAdapter<String> adapter = new ArrayAdapter<>(this, 
                android.R.layout.simple_spinner_item, cryptos);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        cryptoSpinner.setAdapter(adapter);
        
        // Initialize miner
        miner = NativeMiner.getInstance();
        miner.setListener(this);
        
        // Set initial status
        statusTextView.setText("⏳ Ready to mine");
        statusTextView.setTextColor(getColor(R.color.status_waiting));
        
        // Button listeners
        startButton.setOnClickListener(v -> {
            String crypto = cryptoSpinner.getSelectedItem().toString();
            String cryptoCode = crypto.substring(crypto.indexOf("(") + 1, crypto.indexOf(")"));
            miner.changeCrypto(cryptoCode);
            miner.start();
            startButton.setEnabled(false);
            stopButton.setEnabled(true);
            statusTextView.setText("⛏️ Mining active");
            statusTextView.setTextColor(getColor(R.color.status_active));
            miningProgress.setIndeterminate(true);
            addLog("▶️ Mining started!");
            addLog("📤 Wallet: 44osUR6e9Uje...WKTx7YZ");
            addLog("🔗 Pool: pool.supportxmr.com:443");
            addLog("⏳ First share takes 24-48 hours");
        });
        
        stopButton.setOnClickListener(v -> {
            miner.stop();
            startButton.setEnabled(true);
            stopButton.setEnabled(false);
            statusTextView.setText("⏹️ Stopped");
            statusTextView.setTextColor(getColor(R.color.status_stopped));
            miningProgress.setIndeterminate(false);
            addLog("⏹️ Mining stopped!");
        });
        
        checkButton.setOnClickListener(v -> {
            addLog("🔍 Checking miner status...");
            updateStatsDisplay();
            addLog("✅ Status checked!");
        });
        
        // Show initial wallet info
        addLog("📱 NINURTA MINER v2.0");
        addLog("📬 Wallet: 44osUR6e9Uje...WKTx7YZ");
        addLog("🔗 Pool: pool.supportxmr.com:443");
        addLog("💡 Press START to begin mining!");
    }
    
    @Override
    public void onStatsUpdate(String statsJson) {
        try {
            JSONObject stats = new JSONObject(statsJson);
            String display = "📊 MINING STATS\n";
            display += "⏰ Time: " + stats.getString("timestamp") + "\n";
            display += "⛏️ Crypto: " + stats.getString("crypto") + "\n";
            display += "📊 Hashrate: " + stats.getDouble("hashrate") + " H/s\n";
            display += "📈 Shares: " + stats.getInt("shares") + "\n";
            display += "💰 Earnings: " + stats.getDouble("earnings") + "\n";
            display += "🔥 Temp: " + stats.getDouble("temperature") + "°C\n";
            display += "🔋 Battery: " + stats.getDouble("battery") + "%";
            
            statsTextView.setText(display);
            
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    
    @Override
    public void onLogUpdate(String message) {
        addLog(message);
    }
    
    @Override
    public void onEarningsUpdate(double earnings) {
        runOnUiThread(() -> {
            earningsTextView.setText(String.format("💰 %.8f XMR", earnings));
        });
    }
    
    private void addLog(String message) {
        runOnUiThread(() -> {
            logBuilder.append("> ").append(message).append("\n");
            logTextView.setText(logBuilder.toString());
            
            // Auto-scroll
            logScrollView.post(() -> logScrollView.fullScroll(View.FOCUS_DOWN));
        });
    }
    
    private void updateStatsDisplay() {
        runOnUiThread(() -> {
            try {
                String statsJson = miner.getStats();
                JSONObject stats = new JSONObject(statsJson);
                String display = "📊 MINING STATS\n";
                display += "⏰ Time: " + stats.getString("timestamp") + "\n";
                display += "⛏️ Crypto: " + stats.getString("crypto") + "\n";
                display += "📊 Hashrate: " + stats.getDouble("hashrate") + " H/s\n";
                display += "📈 Shares: " + stats.getInt("shares") + "\n";
                display += "💰 Earnings: " + stats.getDouble("earnings") + "\n";
                display += "🔥 Temp: " + stats.getDouble("temperature") + "°C\n";
                display += "🔋 Battery: " + stats.getDouble("battery") + "%";
                
                statsTextView.setText(display);
                
            } catch (Exception e) {
                e.printStackTrace();
            }
        });
    }
    
    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (miner != null) {
            miner.destroy();
        }
    }
}
