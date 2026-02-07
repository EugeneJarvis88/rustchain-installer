# RustChain Miner Installer

One-line installer for RustChain miner on Ubuntu/Debian/macOS.

## Quick Install

```bash
curl -sSL https://raw.githubusercontent.com/EugeneJarvis88/rustchain-installer/main/install-miner.sh | bash
```

## Features

- ✅ Auto-detects OS (Ubuntu, Debian, macOS, Raspberry Pi)
- ✅ Installs Python 3.8+ if missing
- ✅ Creates isolated virtualenv
- ✅ Downloads miner scripts
- ✅ Prompts for wallet name
- ✅ Sets up systemd (Linux) or launchd (macOS) service
- ✅ Tests network connection
- ✅ `--dry-run` flag for preview

## Supported Platforms

| Platform | Status |
|----------|--------|
| Ubuntu 20.04/22.04/24.04 | ✅ |
| Debian 11/12 | ✅ |
| macOS (Intel) | ✅ |
| macOS (Apple Silicon) | ✅ |
| Raspberry Pi (ARM64) | ✅ |

## Usage

### Dry Run (preview without installing)
```bash
curl -sSL https://raw.githubusercontent.com/EugeneJarvis88/rustchain-installer/main/install-miner.sh | bash -s -- --dry-run
```

### After Installation

**Linux:**
```bash
systemctl --user start rustchain-miner
systemctl --user status rustchain-miner
journalctl --user -u rustchain-miner -f
```

**macOS:**
```bash
launchctl load ~/Library/LaunchAgents/com.rustchain.miner.plist
launchctl list | grep rustchain
```

## Bounty

[Bounty #63](https://github.com/Scottcjn/rustchain-bounties/issues/63) - 50 RTC

Wallet: `zARG9WZCiRRzghuCzx1kqSynhYanBnGdjfz4kjSjvin`
