---
name: environment-manager
description: Inspect, maintain, repair, and upgrade system environment packages, python venv libraries, node packages, and disk space for Aether.
---

# Environment Manager Skill Guidelines

Use this skill whenever Aether needs to inspect system resources, install packages, check dependencies, or maintain the environment.

## 🛠️ Power Desktop Commands & Tools

1. **Python Quantitative & ML Stack**:
   - Pre-installed: `ccxt`, `pandas`, `numpy`, `ta`, `pandas-ta`, `polars`, `duckdb`, `yfinance`, `scipy`, `scikit-learn`, `statsmodels`, `playwright`, `selenium`, `pytesseract`.
   - Install new Python packages: `/opt/hermes-venv/bin/uv pip install <package>`
   - List installed packages: `/opt/hermes-venv/bin/uv pip list`

2. **System & Compiler Package Management**:
   - Compilers & Dev Tools pre-installed: `gcc`, `g++`, `gfortran`, `make`, `cmake`, `ninja-build`, `pkg-config`, `libssl-dev`, `libffi-dev`.
   - Install system binaries (full passwordless sudo): `sudo apt-get update && sudo apt-get install -y <package>`

3. **Browser Automation & Playwright**:
   - Run Playwright headlessly via Xvfb (`DISPLAY=:99`).
   - Re-install / update browsers: `/opt/hermes-venv/bin/python -m playwright install chromium` or `npx playwright install chromium`.
   - Global CLI tool: `agent-browser`

4. **Background Tasks & Terminal Session Managers**:
   - Launch background sessions: `tmux new -s session_name` or `screen -S session_name`
   - Process supervision & tree inspection: `htop`, `tree`, `ncdu`, `ps aux`, `lsof -i :3000`

5. **System & Diagnostic Monitoring**:
   - Check Hermes health: `hermes doctor --check system`
   - Check disk space & inodes: `df -h /app`
   - Check RAM & memory usage: `free -h`
   - Check active network sockets: `netstat -tulnp` or `ss -tulnp`
