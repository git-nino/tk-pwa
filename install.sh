#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "🚀 Installing TK-PWA (app3) on Termux..."

### VARIABLES
APP_NAME="app3"
REPO_URL="https://github.com/git-nino/tk-pwa.git"
APP_BASE="$HOME/app_volumes"
APP_DIR="$APP_BASE/$APP_NAME"
VENV_DIR="$APP_DIR/venv"
PYTHON="$VENV_DIR/bin/python"
BIN_DIR="$PREFIX/bin"
SERVICE_DIR="$PREFIX/var/service/$APP_NAME"
RUNSVDIR="$PREFIX/var/service"

### 1️⃣ Verify Termux environment
if [[ -z "${PREFIX:-}" || ! -d "$PREFIX" ]]; then
  echo "❌ This installer must be run inside Termux"
  exit 1
fi

### 2️⃣ Storage permission (non-fatal)
echo "📂 Setting up storage access..."
termux-setup-storage >/dev/null 2>&1 || true

### 3️⃣ Update Termux packages
echo "🔄 Updating Termux packages..."
pkg update -y && pkg upgrade -y

### 4️⃣ Check system dependencies
deps=(git python python-pip clang make cmake termux-services libjpeg-turbo freetype libpng)
for pkg_name in "${deps[@]}"; do
    if ! command -v "$pkg_name" >/dev/null 2>&1 && ! pkg list-installed | grep -q "$pkg_name"; then
        echo "➕ Installing missing package: $pkg_name"
        pkg install -y "$pkg_name"
    else
        echo "✔ $pkg_name already installed"
    fi
done

### 5️⃣ Create app directory
echo "📁 Creating app directory..."
mkdir -p "$APP_DIR"

### 6️⃣ Clone/update repository
if [[ ! -d "$APP_DIR/.git" ]]; then
    echo "🌱 Cloning repository..."
    git clone "$REPO_URL" "$APP_DIR"
else
    echo "🔄 Updating repository..."
    git -C "$APP_DIR" pull
fi

### 7️⃣ Create Python virtual environment
echo "🐍 Creating Python virtual environment..."
python -m venv "$VENV_DIR"

### 8️⃣ Upgrade pip, setuptools, wheel
echo "⚡ Upgrading pip and build tools..."
"$PYTHON" -m pip install --upgrade pip setuptools wheel

### 9️⃣ Install Python dependencies
echo "📦 Installing Python dependencies..."
"$PYTHON" -m pip install -r "$APP_DIR/requirements.txt"

### 🔟 Create Termux service
echo "🔧 Creating Termux service..."
mkdir -p "$SERVICE_DIR"
cat > "$SERVICE_DIR/run" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
source "$VENV_DIR/bin/activate"
cd "$APP_DIR"
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
