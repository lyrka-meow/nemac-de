#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; ERRORS=$((ERRORS+1)); }
warn() { echo -e "  ${YELLOW}!${NC} $1"; }
info() { echo -e "  ${CYAN}→${NC} $1"; }

ERRORS=0

echo ""
echo -e "${BOLD}═══════════════════════════════════════${NC}"
echo -e "${BOLD}  Nemac DE — Диагностика системы${NC}"
echo -e "${BOLD}═══════════════════════════════════════${NC}"
echo ""

# ─── 1. Пакеты ───
echo -e "${CYAN}[1/7] Проверяю пакеты...${NC}"
REQUIRED_PKGS=(
    qt5-base qt5-declarative qt5-quickcontrols2 qt5-x11extras qt5-svg
    qt5-graphicaleffects qt5-sensors
    kwin kwindowsystem5 kidletime5 kcoreaddons5
    libkscreen5 kio5 solid5
    polkit polkit-qt5
    networkmanager-qt5 bluez-qt5
    libqt5xdg libdbusmenu-qt5
    libcanberra libpulse
    libxcb xcb-util xcb-util-wm xcb-util-keysyms
    extra-cmake-modules
)
MISSING_PKGS=()
for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! pacman -Qi "$pkg" &>/dev/null; then
        fail "Пакет НЕ установлен: $pkg"
        MISSING_PKGS+=("$pkg")
    fi
done
if [ ${#MISSING_PKGS[@]} -eq 0 ]; then
    ok "Все пакеты установлены (${#REQUIRED_PKGS[@]} шт.)"
else
    echo ""
    echo -e "  ${RED}Установить:${NC} sudo pacman -S ${MISSING_PKGS[*]}"
fi
echo ""

# ─── 2. Бинарники ───
echo -e "${CYAN}[2/7] Проверяю бинарники Nemac...${NC}"
BINARIES=(
    nemac-session
    nemac-settings-daemon
    nemac-statusbar
    nemac-dock
    nemac-launcher
    nemac-filemanager
    nemac-notificationd
    nemac-powerman
    nemac-clipboard
    nemac-xembedsniproxy
    nemac-gmenuproxy
    chotkeys
    cupdatecursor
    nemac-screenshot
    nemac-terminal
    nemac-settings
    nemac-screenlocker
)
for bin in "${BINARIES[@]}"; do
    path=$(which "$bin" 2>/dev/null)
    if [ -n "$path" ]; then
        ok "$bin → $path"
    else
        fail "$bin — НЕ НАЙДЕН в PATH"
    fi
done
echo ""

# ─── 3. Библиотеки (ldd) ───
echo -e "${CYAN}[3/7] Проверяю зависимости библиотек (ldd)...${NC}"
CRITICAL_BINS=(nemac-session nemac-settings-daemon nemac-statusbar nemac-dock nemac-launcher nemac-filemanager)
LDD_ISSUES=0
for bin in "${CRITICAL_BINS[@]}"; do
    path=$(which "$bin" 2>/dev/null)
    if [ -n "$path" ]; then
        missing=$(ldd "$path" 2>/dev/null | grep "not found")
        if [ -n "$missing" ]; then
            fail "$bin — не хватает .so:"
            echo "$missing" | while read -r line; do
                echo -e "       ${RED}$line${NC}"
            done
            LDD_ISSUES=$((LDD_ISSUES+1))
        fi
    fi
done
if [ $LDD_ISSUES -eq 0 ]; then
    ok "Все критичные бинарники — зависимости в порядке"
fi
echo ""

# ─── 4. QML-модули Nemac (libnemac) ───
echo -e "${CYAN}[4/7] Проверяю QML-плагины Nemac (libnemac)...${NC}"
QML_DIR=$(qmake -query QT_INSTALL_QML 2>/dev/null || echo "/usr/lib/qt/qml")
NEMAC_QML_MODULES=(Audio Bluez Mpris NetworkManagement Screen System Accounts)
QML_MISSING=0

if [ ! -d "$QML_DIR/Nemac" ]; then
    fail "Папка $QML_DIR/Nemac НЕ СУЩЕСТВУЕТ — libnemac не установлен!"
    QML_MISSING=99
else
    for mod in "${NEMAC_QML_MODULES[@]}"; do
        mod_dir="$QML_DIR/Nemac/$mod"
        if [ -d "$mod_dir" ]; then
            so_file=$(find "$mod_dir" -name "*.so" 2>/dev/null | head -1)
            if [ -n "$so_file" ]; then
                so_missing=$(ldd "$so_file" 2>/dev/null | grep "not found")
                if [ -n "$so_missing" ]; then
                    fail "Nemac/$mod — .so есть, но не хватает библиотек:"
                    echo "$so_missing" | while read -r line; do
                        echo -e "       ${RED}$line${NC}"
                    done
                    QML_MISSING=$((QML_MISSING+1))
                else
                    ok "Nemac/$mod"
                fi
            else
                fail "Nemac/$mod — папка есть, но .so отсутствует"
                QML_MISSING=$((QML_MISSING+1))
            fi
        else
            fail "Nemac/$mod — НЕ НАЙДЕН"
            QML_MISSING=$((QML_MISSING+1))
        fi
    done
fi

if [ $QML_MISSING -gt 0 ]; then
    echo ""
    echo -e "  ${RED}libnemac не установлен или установлен частично.${NC}"
    echo -e "  ${RED}Нужно пересобрать: cd /opt/nemac-de/libnemac/build && cmake .. && make && sudo make install${NC}"
fi
echo ""

# ─── 5. Системные QML-модули ───
echo -e "${CYAN}[5/7] Проверяю системные QML-модули...${NC}"
SYS_QML_MODULES=(
    "QtQuick.2"
    "QtQuick/Controls.2"
    "QtQuick/Layouts"
    "QtQuick/Window.2"
    "QtGraphicalEffects"
    "Qt/labs/platform"
    "Qt/labs/settings"
    "NemacUI"
)
SYS_QML_MISSING=0
for mod in "${SYS_QML_MODULES[@]}"; do
    if [ -d "$QML_DIR/$mod" ]; then
        ok "$mod"
    else
        fail "$mod — НЕ НАЙДЕН в $QML_DIR"
        SYS_QML_MISSING=$((SYS_QML_MISSING+1))
    fi
done
echo ""

# ─── 6. Файл сессии ───
echo -e "${CYAN}[6/7] Проверяю файл сессии для DM...${NC}"
if [ -f /usr/share/xsessions/nemac.desktop ]; then
    ok "/usr/share/xsessions/nemac.desktop существует"
    exec_line=$(grep "^Exec=" /usr/share/xsessions/nemac.desktop | cut -d= -f2)
    if which "$exec_line" &>/dev/null; then
        ok "Exec=$exec_line → найден"
    else
        fail "Exec=$exec_line → НЕ найден в PATH"
    fi
else
    fail "/usr/share/xsessions/nemac.desktop НЕ найден (LightDM/SDDM не увидит сессию)"
fi
echo ""

# ─── 7. Тест запуска компонентов ───
echo -e "${CYAN}[7/7] Тестирую запуск компонентов (по 3 сек каждый)...${NC}"
if [ -z "$DISPLAY" ]; then
    warn "DISPLAY не задан, пропускаю тест запуска"
    warn "Запустите скрипт так: DISPLAY=:0 bash nemac-diagnose.sh"
else
    TEST_BINS=(nemac-settings-daemon nemac-statusbar nemac-dock nemac-launcher)
    for bin in "${TEST_BINS[@]}"; do
        path=$(which "$bin" 2>/dev/null)
        if [ -z "$path" ]; then
            fail "$bin — не найден, пропускаю"
            continue
        fi
        output=$($bin 2>&1 & PID=$!; sleep 3; kill $PID 2>/dev/null; wait $PID 2>/dev/null)
        errors=$(echo "$output" | grep -iE "error|fatal|not found|not installed|cannot|failed to load|unavailable" | head -5)
        if [ -n "$errors" ]; then
            fail "$bin — ошибки при запуске:"
            echo "$errors" | while IFS= read -r line; do
                echo -e "       ${RED}$line${NC}"
            done
        else
            ok "$bin — запустился без критичных ошибок"
        fi
    done
fi

echo ""
echo -e "${BOLD}═══════════════════════════════════════${NC}"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}  Всё в порядке! Ошибок не обнаружено.${NC}"
else
    echo -e "${RED}  Найдено проблем: $ERRORS${NC}"
fi
echo -e "${BOLD}═══════════════════════════════════════${NC}"
echo ""
