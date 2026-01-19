#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

APP_NAME="app3"
APP_DIR="$HOME/app_volumes/$APP_NAME"
REPO_URL="https://github.com/git-nino/tk-pwa.git"
VENV_DIR="$APP_DIR/venv"
PYTHON_BIN="python3"
SERVICE_DIR="$HOME/.service/$APP_NAME"
RUNSVDIR="$PREFIX/var/service"

GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
RESET="\033[0m"

echo -e "${GREEN}🚀 Installing TK-PWA (${APP_NAME}) on Termux${RESET}"

### 1️⃣ Update packages
pkg update -y && pkg upgrade -y

### 2️⃣ Install system dependencies
REQUIRED_PKGS=(git python python-pip termux-services clang make cmake libjpeg-turbo freetype libpng)
for pkg in "${REQUIRED_PKGS[@]}"; do
  if ! command -v "${pkg%%-*}" >/dev/null 2>&1; then
    echo "➕ Installing missing package: $pkg"
    pkg install -y "$pkg"
  else
    echo "✔ $pkg already installed"
  fi
done

mkdir -p "$RUNSVDIR"
mkdir -p "$APP_DIR"
cd "$APP_DIR"

### 3️⃣ Clone or update repo
if [ -d ".git" ]; then
  git pull
else
  git clone "$REPO_URL" .
fi

### 4️⃣ Create Python virtual environment
$PYTHON_BIN -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

### 5️⃣ Upgrade pip, setuptools, wheel
pip install --upgrade pip setuptools wheel

### 6️⃣ Preinstall numeric libraries from wheels ONLY
pip install --only-binary=:all: numpy==1.24.6 pandas==2.1.1 openpyxl==3.1.2 Flask==3.0.0

### 7️⃣ Install any remaining small packages from requirements.txt
# Only install packages not already handled
pip install --no-build-isolation -r requirements.txt || true
deactivate

### 8️⃣ Create run script
cat > "$APP_DIR/run.sh" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
cd "$APP_DIR"
source "$VENV_DIR/bin/activate"
exec python app.py
EOF
chmod +x "$APP_DIR/run.sh"

### 9️⃣ Create Termux service
mkdir -p "$SERVICE_DIR"
cat > "$SERVICE_DIR/run" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
cd "$APP_DIR"
source "$VENV_DIR/bin/activate"
exec python app.py
EOF
chmod +x "$SERVICE_DIR/run"

### 🔟 Enable service
if [[ -d "$RUNSVDIR" && -x "$PREFIX/bin/sv-enable" ]]; then
  sv-enable "$APP_NAME" || true
  sv up "$APP_NAME" || true
  echo -e "${GREEN}✅ Service started${RESET}"
else
  echo -e "${YELLOW}ℹ️ Service will start after Termux restart${RESET}"
fi

echo -e "\n${GREEN}✅ Installation completed successfully!${RESET}"
echo "Close Termux completely and reopen it."
echo "Check service status with: sv status $APP_NAME"
