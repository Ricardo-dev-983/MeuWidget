#!/bin/sh
##############################################################
# setup.sh — Roda no Termux e compila o Photo Widgets APK
##############################################################
set -e

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   Photo Widgets — Setup Termux       ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── 1. Atualizar pacotes ─────────────────────────────────
echo "[ 1/5 ] Atualizando pacotes..."
pkg update -y -q

# ── 2. Instalar Java 17 ──────────────────────────────────
echo "[ 2/5 ] Instalando Java 17..."
pkg install -y -q openjdk-17
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
echo "Java: $(java -version 2>&1 | head -1)"

# ── 3. Instalar ferramentas ──────────────────────────────
echo "[ 3/5 ] Instalando wget e unzip..."
pkg install -y -q wget unzip

# ── 4. Instalar Android SDK via sdkmanager ───────────────
echo "[ 4/5 ] Configurando Android SDK..."

SDK_DIR="$HOME/android-sdk"
CMDTOOLS="$SDK_DIR/cmdline-tools/latest"

if [ ! -f "$CMDTOOLS/bin/sdkmanager" ]; then
    echo "Baixando Android Command Line Tools..."
    mkdir -p "$SDK_DIR/cmdline-tools"
    wget -q --show-progress \
        "https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip" \
        -O /tmp/cmdtools.zip
    unzip -q /tmp/cmdtools.zip -d /tmp/cmdtools_tmp
    mv /tmp/cmdtools_tmp/cmdline-tools "$CMDTOOLS"
    rm -rf /tmp/cmdtools.zip /tmp/cmdtools_tmp
fi

export ANDROID_HOME="$SDK_DIR"
export ANDROID_SDK_ROOT="$SDK_DIR"
export PATH="$CMDTOOLS/bin:$SDK_DIR/platform-tools:$PATH"

echo "Aceitando licenças e instalando SDK 33..."
yes | sdkmanager --licenses > /dev/null 2>&1 || true
sdkmanager "platforms;android-33" "build-tools;33.0.2" > /dev/null 2>&1

# Salvar variáveis no ~/.bashrc para sessões futuras
grep -q "ANDROID_HOME" ~/.bashrc 2>/dev/null || cat >> ~/.bashrc << 'EOF'
export ANDROID_HOME="$HOME/android-sdk"
export ANDROID_SDK_ROOT="$HOME/android-sdk"
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
EOF

# ── 5. Compilar o APK ────────────────────────────────────
echo "[ 5/5 ] Compilando APK..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Criar local.properties com o caminho do SDK
echo "sdk.dir=$SDK_DIR" > local.properties

chmod +x gradlew
./gradlew assembleDebug --no-daemon

APK="$SCRIPT_DIR/app/build/outputs/apk/debug/app-debug.apk"

echo ""
if [ -f "$APK" ]; then
    echo "╔══════════════════════════════════════╗"
    echo "║   ✅  APK GERADO COM SUCESSO!        ║"
    echo "╚══════════════════════════════════════╝"
    echo ""
    echo "APK: $APK"
    SIZE=$(du -h "$APK" | cut -f1)
    echo "Tamanho: $SIZE"
    echo ""
    echo "Para instalar direto pelo Termux:"
    echo "  termux-open $APK"
    echo ""
    # Copy to Downloads for easy access
    cp "$APK" "$HOME/storage/downloads/PhotoWidgets.apk" 2>/dev/null && \
        echo "Copiado para: Downloads/PhotoWidgets.apk" || true
else
    echo "❌ Falha na compilação. Veja os erros acima."
    exit 1
fi
