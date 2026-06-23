README.md

```markdown
# 🏦 Ninurta Bank ATM

**Bitcoin → Thai other currency Bridge**  
*No Pier to pier, No Middlemen. Just Value.*

---

## 📋 Overview

Ninurta Bank ATM is a **terminal-based Bitcoin ATM simulator** that bridges cryptocurrency to any currency (BDT, indian rupees, THB etc). It provides a simple, secure interface for checking BTC balances, generating PromptPay QR codes, and simulating withdrawals to Thai banks.

> ⚠️ **Disclaimer:** This is a **simulation/game** for educational and entertainment purposes. No real financial transactions occur. All balances and rates are for demonstration only.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔐 **PIN Protection** | Secure vault with 6-digit PIN (default: XXXXXX) |
| 💰 **Real BTC Balance** | Fetches live BTC balance from blockchain.info |
| 📊 **Live Exchange Rate** | Real-time BTC/THB rate from CoinGecko |
| 📱 **PromptPay QR** | Generate QR codes for  bank transfers |
| 🏦 **Bank Withdrawal** | Simulated withdrawal guide to Thai banks |
| 📜 **MIT License** | Open-source with clear terms |
| 🎮 **Fun Game Mode** | Interactive terminal experience |

---

## 🚀 Quick Start

### Prerequisites
- Linux/macOS/WSL (Windows Subsystem for Linux)
- `bash` 4.0+
- `curl` for API calls
- `qrencode` for QR generation (optional)

### Installation

```bash
# Clone the repository
git clone https://github.com/Khan-Amit/ninurta_bank.git

# Navigate to directory
cd ninurta_bank

# Make executable
chmod +x ninurta_bank.sh

# Run the ATM
./ninurta_bank.sh
```

Default PIN

```
🔑 PIN:  XXXXXX
```

---

📖 Usage Guide

Main Menu Options

```
🏦 NINURTA BANK ATM
═══════════════════════════════
[1] Send Crypto → Bank
[2] Send Crypto → Crypto
[3] Receive Money (QR)
[4] Receive Crypto
[5] Refresh Balance
[6] Settings
[7] Transaction History
[8] Exit
```

Commands

Command Action
1 Sell BTC for BDT , INDIAN RUPEES ETC. (simulated)
2 Transfer BTC to another wallet
3 Generate PromptPay QR code
4 Display your BTC address
5 Refresh balance and rates
6 Update bank/crypto settings
7 View transaction history
8 Exit the ATM

---

🔧 Configuration

First-Time Setup

The ATM will prompt you for:

· Bank name (Kasikorn/SCB/Bangkok Bank)
· Bank account number
· Phone number (for PromptPay)
· Bitkub API keys (optional)

Configuration File

Settings are stored in:

```bash
~/.marduk_atm/user.conf
```

Change PIN

Edit line 192 in ninurta_bank.sh:

```bash
VAULT_PASSWORD="197328"  # Change to your own 6-digit PIN
```

---

🛠️ Technical Details

Architecture

```
┌──────────────────────────────────────────────┐
│           Ninurta Bank ATM                   │
│  ┌────────────────────────────────────────┐  │
│  │         Password Vault (PIN)           │  │
│  └────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────┐  │
│  │      Balance & Rate APIs               │  │
│  │  • blockchain.info (BTC balance)       │  │
│  │  • CoinGecko (BTC/THB rate)            │  │
│  └────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────┐  │
│  │         Transaction Engine             │  │
│  │  • Buy/Sell simulation                 │  │
│  │  • QR generation                       │  │
│  │  • History logging                     │  │
│  └────────────────────────────────────────┘  │
└──────────────────────────────────────────────┘
```

API Endpoints

Service Endpoint Purpose
Bitcoin Balance blockchain.info/q/addressbalance/{ADDR} Get BTC balance
Exchange Rate api.coingecko.com/api/v3/simple/price Get BTC/THB rate
PromptPay promptpay.io/{PHONE}/{AMOUNT} QR code generation

---

📁 File Structure

```
ninurta_bank/
├── ninurta_bank.sh          # Main ATM script
├── README.md                # This file
├── LICENSE                  #  License
├── .gitignore               # Git ignore rules
└── docs/
    └── user_guide.md        # Detailed documentation
```

---

🤝 Contributing

We welcome contributions! Please ASK THE OWNER.
SELIIM AHMED 
Email amit.khanna.1082@gmail.com



Coding Standards

· Use bash best practices
· Add comments for complex logic
· Test on Linux and macOS
· Update documentation accordingly

---


