#!/bin/sh
GRADLE_VERSION="8.9"
APP_HOME="$(cd "$(dirname "$0")" && pwd -P)"

# Termux compatible paths
if [ -d "/data/data/com.termux/files/usr" ]; then
    export PATH="/data/data/com.termux/files/usr/bin:$PATH"
    GRADLE_BASE="/data/data/com.termux/files/home/.gradle_home"
else
    GRADLE_BASE="$HOME/.gradle_home"
fi

[ -e "$GRADLE_BASE" ] && [ ! -d "$GRADLE_BASE" ] && rm -f "$GRADLE_BASE"

GRADLE_DIR="$GRADLE_BASE/wrapper/dists/gradle-${GRADLE_VERSION}-bin/gradle-${GRADLE_VERSION}"
GRADLE_CMD="$GRADLE_DIR/bin/gradle"

if [ ! -f "$GRADLE_CMD" ]; then
    echo "Baixando Gradle ${GRADLE_VERSION}..."
    mkdir -p "$GRADLE_BASE/wrapper/dists/gradle-${GRADLE_VERSION}-bin"
    cd "$GRADLE_BASE/wrapper/dists/gradle-${GRADLE_VERSION}-bin"
    URL="https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"
    if command -v wget >/dev/null 2>&1; then
        wget -q --show-progress "$URL" -O g.zip
    elif command -v curl >/dev/null 2>&1; then
        curl -L --progress-bar "$URL" -o g.zip
    fi
    unzip -q g.zip && rm -f g.zip
    echo "Gradle pronto!"
fi

JAVACMD="${JAVA_HOME:+$JAVA_HOME/bin/}java"
exec "$JAVACMD" -Xmx512m -Xms64m \
    "-Dgradle.user.home=$GRADLE_BASE" \
    "-Dorg.gradle.appname=gradlew" \
    -jar "$GRADLE_DIR/lib/gradle-launcher-${GRADLE_VERSION}.jar" \
    --project-dir "$APP_HOME" \
    "$@"
