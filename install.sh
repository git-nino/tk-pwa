#!/data/data/com.termux/files/usr/bin/bash
set -e

### ================= CONFIG =================
APP_NAME="app3"
APP_DIR="$HOME/app_volumes/$APP_NAME"
REPO_URL="https://github.com/git-nino/tk-pwa.git"
VENV_DIR="$APP_DIR/venv"
PYTHON_BIN="python3"
SERVICE_DIR="$HOME/.service/$APP_NAME"
RUNSVDIR="$PREFIX/var/service"

### ================= COLORS =================
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
RESET="\033[0m"

echo -e "${GREEN}🚀 Installing TK-PWA (${APP_NAME}) on Termux${RESET}"

### 1️⃣ Ensure Termux environment
if [[ -z "${PREFIX:-}" || ! -d "$PREFIX" ]]; then
  echo -e "${RED}❌ This installer must be run inside Termux${RESET}"
  exit 1
fi

### 2️⃣ Update packages
echo "📦 Updating Termux packages..."
pkg update -y && pkg upgrade -y

### 3️⃣ Install required system packages
REQUIRED_PKGS=(
  git
  python
  python-pip
  termux-services
  clang
  make
  cmake
  libjpeg-turbo
  freetype
  libpng
)

echo "🔍 Checking system dependencies..."
for pkg in "${REQUIRED_PKGS[@]}"; do
  if ! command -v "${pkg%%-*}" >/dev/null 2>&1; then
    echo "➕ Installing missing package: $pkg"
    pkg install -y "$pkg"
  else
    echo "✔ $pkg already installed"
  fi
done

### 4️⃣ Enable Termux services directory
mkdir -p "$RUNSVDIR"

### 5️⃣ Create app directory
echo "📂 Creating app directory..."
mkdir -p "$APP_DIR"
cd "$APP_DIR"

### 6️⃣ Clone or update repo
if [ -d ".git" ]; then
  echo "🔄 Updating repository..."
  git pull
else
  echo "⬇️ Cloning repository..."
  git clone "$REPO_URL" .
fi

### 7️⃣ Create virtual environment (with system packages)
echo "🐍 Creating Python virtual environment..."
$PYTHON_BIN -m venv --system-site-packages "$VENV_DIR"
source "$VENV_DIR/bin/activate"

### 8️⃣ Install Python dependencies from requirements.txt
if [ ! -f requirements.txt ]; then
  echo -e "${RED}❌ requirements.txt not found${RESET}"
  exit 1
fi

echo "📚 Installing Python dependencies..."
pip install --upgrade pip setuptools wheel
# Use --no-build-isolation to avoid compilation issues in Termux
pip install --no-build-isolation -r requirements.txt
deactivate

### 9️⃣ Create run script
echo "▶️ Creating run script..."
cat > "$APP_DIR/run.sh" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
cd "$APP_DIR"
source "$VENV_DIR/bin/activate"
exec python app.py
EOF
chmod +x "$APP_DIR/run.sh"

### 🔟 Create Termux service
echo "⚙️ Creating Termux service: $APP_NAME"
mkdir -p "$SERVICE_DIR"
cat > "$SERVICE_DIR/run" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
cd "$APP_DIR"
source "$VENV_DIR/bin/activate"
exec python app.py
EOF
chmod +x "$SERVICE_DIR/run"

### 1️⃣1️⃣ Enable and start service if runsvdir is running
if [[ -d "$RUNSVDIR" && -x "$PREFIX/bin/sv-enable" ]]; then
  echo "🔁 Enabling and starting service..."
  sv-enable "$APP_NAME" || true
  sv up "$APP_NAME" || true
  echo "✅ Service started"
else
  echo "ℹ️ Services not active yet (Termux restart required)"
fi

### ✅ Done
echo ""
echo "✅ Installation completed successfully!"
echo ""
echo "📌 NEXT STEP:"
echo "⚠️ Close Termux completely (swipe away) and reopen it."
echo "👉 After reopening, the service will start automatically."
echo ""
echo "📥 Commands available after restart:"
echo "   sv status $APP_NAME"
echo ""
