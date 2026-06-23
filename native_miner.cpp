// ============================================================
// 📱 ANDROID NATIVE MINER - JNI Wrapper
// "Connecting C++ to Android UI"
// ============================================================

#include <jni.h>
#include <string>
#include <thread>
#include <chrono>
#include "miner_engine.cpp"

extern "C" {

// Global mining engine instance
static CryptoEngine* g_engine = nullptr;

// Initialize the miner
JNIEXPORT void JNICALL
Java_com_marduk_miner_NativeMiner_initMiner(JNIEnv* env, jobject /* this */) {
    if (g_engine == nullptr) {
        g_engine = new CryptoEngine();
    }
}

// Start mining
JNIEXPORT void JNICALL
Java_com_marduk_miner_NativeMiner_startMining(JNIEnv* env, jobject /* this */) {
    if (g_engine != nullptr) {
        g_engine->startMining();
    }
}

// Stop mining
JNIEXPORT void JNICALL
Java_com_marduk_miner_NativeMiner_stopMining(JNIEnv* env, jobject /* this */) {
    if (g_engine != nullptr) {
        g_engine->stopMining();
    }
}

// Switch crypto
JNIEXPORT void JNICALL
Java_com_marduk_miner_NativeMiner_setCrypto(JNIEnv* env, jobject /* this */, jstring crypto) {
    if (g_engine != nullptr) {
        const char* cryptoStr = env->GetStringUTFChars(crypto, nullptr);
        g_engine->setCrypto(std::string(cryptoStr));
        env->ReleaseStringUTFChars(crypto, cryptoStr);
    }
}

// Get stats as JSON string
JNIEXPORT jstring JNICALL
Java_com_marduk_miner_NativeMiner_getStats(JNIEnv* env, jobject /* this */) {
    if (g_engine == nullptr) {
        return env->NewStringUTF("{}");
    }
    
    auto stats = g_engine->getStats();
    std::string json = "{";
    json += "\"timestamp\":\"" + stats.timestamp + "\",";
    json += "\"hashrate\":" + std::to_string(stats.currentHashrate) + ",";
    json += "\"shares\":" + std::to_string(stats.totalShares) + ",";
    json += "\"earnings\":" + std::to_string(stats.totalEarnings) + ",";
    json += "\"crypto\":\"" + stats.crypto + "\",";
    json += "\"temperature\":" + std::to_string(stats.temperature) + ",";
    json += "\"battery\":" + std::to_string(stats.batteryLevel);
    json += "}";
    
    return env->NewStringUTF(json.c_str());
}

// Clean up
JNIEXPORT void JNICALL
Java_com_marduk_miner_NativeMiner_cleanup(JNIEnv* env, jobject /* this */) {
    if (g_engine != nullptr) {
        g_engine->stopMining();
        delete g_engine;
        g_engine = nullptr;
    }
}

} // extern "C"
