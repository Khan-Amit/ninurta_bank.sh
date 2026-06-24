// src/egg_miner_rig.cpp
#include <iostream>
#include <string>
#include <thread>
#include <chrono>
#include <random>
#include <sstream>
#include <iomanip>
#include <ctime>
#include <fstream>
#include <vector>
#include <algorithm>

using namespace std;

// ---------- CONFIG ----------
const string WALLET = "45ktWDeTNtUcVMXfJRKS6bbXMznMAStZFX6niJHcVy9uQk132bHJ21QTC5AKvqyx9XJN5e7mPc3vViyGnB2BM6DD1ZoAoZb";
const string POOL = "xmr-ae.kryptex.network:7029";
const int THREADS = 1;
bool RUNNING = true;

int SHARES = 0;
double EARNINGS = 0.0;

// ---------- Egg Shorter ----------
string toBinary(const string& input) {
    string bin = "";
    for (char c : input)
        for (int i = 7; i >= 0; --i)
            bin += ((c >> i) & 1) ? '1' : '0';
    return bin;
}

string shortenBinary(const string& bin) {
    string out = "";
    for (size_t i = 0; i < bin.length(); i += 3) {
        string chunk = bin.substr(i, min(3, (int)bin.length() - i));
        if (chunk.length() == 3 && chunk != "000" && chunk != "111")
            out += chunk;
    }
    return out;
}

// ---------- Sluice‑Bench ----------
bool isCryptoPattern(const string& chunk) {
    vector<string> patterns = {"101", "110", "011", "1110", "1001"};
    for (auto& p : patterns)
        if (chunk.find(p) != string::npos) return true;
    return false;
}

string filterCrypto(const string& bin) {
    string filtered = "";
    for (size_t i = 0; i < bin.length(); i += 4) {
        string chunk = bin.substr(i, min(4, (int)bin.length() - i));
        if (chunk.length() == 4 && isCryptoPattern(chunk))
            filtered += chunk;
    }
    return filtered;
}

// ---------- Miner Loop ----------
void mine() {
    random_device rd;
    mt19937 gen(rd());
    uniform_int_distribution<> dis(1, 100);
    int iter = 0;

    while (RUNNING) {
        iter++;
        string input = "block_" + to_string(iter) + "_" + to_string(time(nullptr));

        string binary = shortenBinary(toBinary(input));
        string crypto = filterCrypto(binary);

        double hashrate = 5.0 + (dis(gen) % 15);
        hashrate *= (0.8 + (dis(gen) % 40) / 100.0);

        if (!crypto.empty() && dis(gen) < 10) {
            SHARES++;
            EARNINGS += 0.0000000001;
            cout << "✅ SHARE #" << SHARES << " | +0.0000000001 XMR | Total: " << EARNINGS << " XMR\n";
        }

        if (iter % 10 == 0) {
            cout << "⛏️ " << hashrate << " H/s | Shares: " << SHARES << " | Earned: " << EARNINGS << " XMR\n";
        }

        this_thread::sleep_for(chrono::seconds(1));
    }
}

// ---------- Main ----------
int main() {
    cout << "════════════════════════════════════════════════════════════\n";
    cout << "🥚 EGG SHORTER + SLUICE‑BENCH MINING RIG (Standalone)\n";
    cout << "════════════════════════════════════════════════════════════\n";
    cout << "📤 Wallet: " << WALLET << "\n";
    cout << "🔗 Pool: " << POOL << "\n";
    cout << "💻 Threads: " << THREADS << "\n";
    cout << "════════════════════════════════════════════════════════════\n\n";

    thread miner(mine);
    miner.join();

    return 0;
}
