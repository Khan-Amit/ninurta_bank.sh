package com.marduk.miner;

import android.os.Bundle;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.ScrollView;
import android.widget.Spinner;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import org.json.JSONObject;

public class MainActivity extends AppCompatActivity 
        implements NativeMiner.MiningListener {
    
    private TextView statsTextView;
    private TextView logTextView;
    private ScrollView logScrollView;
    private Button startButton;
    private Button stopButton;
    private Spinner cryptoSpinner;
    private NativeMiner miner;
    private StringBuilder logBuilder = new StringBuilder();
    
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
        cryptoSpinner = findViewById(R.id.crypto_spinner);
        
        // Setup crypto spinner
        ArrayAdapter<CharSequence> adapter = ArrayAdapter.createFromResource(this,
                R.array.crypto_array, android.R.layout.simple_spinner_item);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        cryptoSpinner.setAdapter(adapter);
        
        // Initialize miner
        miner = NativeMiner.getInstance();
        miner.setListener(this);
        
        // Button listeners
        startButton.setOnClickListener(v -> {
            String crypto = cryptoSpinner.getSelectedItem().toString();
            miner.changeCrypto(crypto);
            miner.start();
            startButton.setEnabled(false);
            stopButton.setEnabled(true);
        });
        
        stopButton.setOnClickListener(v -> {
            miner.stop();
            startButton.setEnabled(true);
            stopButton.setEnabled(false);
        });
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
        logBuilder.append("> ").append(message).append("\n");
        logTextView.setText(logBuilder.toString());
        
        // Auto-scroll
        logScrollView.post(() -> logScrollView.fullScroll(View.FOCUS_DOWN));
    }
    
    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (miner != null) {
            miner.destroy();
        }
    }
}
