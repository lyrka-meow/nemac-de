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
echo -e "${BOLD}═══════════════════════════════════════════${NC}"
echo -e "${BOLD}  Nemac DE — Диагностика системы${NC}"
echo -e "${BOLD}═══════════════════════════════════════════${NC}"
echo ""

# ─── 1. Пакеты ───
echo -e "${CYAN}[1/8] Проверяю пакеты...${NC}"
REQUIRED_PKGS=(
    qt5-base qt5-declarative qt5-quickcontrols2 qt5-x11extras qt5-svg
    qt5-graphicaleffects qt5-sensors
    kwin kwin-x11 kdecoration
    kwindowsystem5 kidletime5 kcoreaddons5
    libkscreen5 kio5 solid5
    polkit polkit-qt5
    networkmanager-qt5 bluez-qt5
    libqt5xdg libdbusmenu-qt5
    libcanberra libpulse
    libxcb xcb-util xcb-util-wm xcb-util-keysyms
    extra-cmake-modules
    freetype2 fontconfig
    xdg-utils xclip
    syntax-highlighting5
    libxcrypt icu
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
    echo -e "  ${RED}Установить:${NC} sudo pacman -S --needed ${MISSING_PKGS[*]}"
fi
echo ""

# ─── 2. Критичные внешние программы ───
echo -e "${CYAN}[2/8] Проверяю внешние программы (WM, X11, DBus)...${NC}"
EXTERNAL_BINS=(
    "kwin_x11:Оконный менеджер (обязателен! без него окна не работают):sudo pacman -S kwin-x11"
    "kwin_wayland:Wayland WM (не критично для X11):"
    "Xorg:X-сервер:sudo pacman -S xorg-server"
    "dbus-update-activation-environment:DBus обновление окружения:sudo pacman -S dbus"
    "xrdb:X resources (настройки DPI/курсора):sudo pacman -S xorg-xrdb"
    "xdg-user-dirs-update:XDG каталоги:sudo pacman -S xdg-user-dirs"
    "polkit-kde-authentication-agent-1:Polkit агент (запрос пароля для sudo-операций):"
)
EXT_MISSING=()
for entry in "${EXTERNAL_BINS[@]}"; do
    IFS=: read -r bin desc fix <<< "$entry"
    path=$(which "$bin" 2>/dev/null)
    if [ -n "$path" ]; then
        ok "$bin — $desc"
    else
        if [[ "$desc" == *"не критично"* ]]; then
            warn "$bin — $desc (не найден, но необязателен)"
        else
            fail "$bin — $desc — НЕ НАЙДЕН"
            [ -n "$fix" ] && echo -e "       ${YELLOW}Исправить: $fix${NC}"
        fi
    fi
done
echo ""

# ─── 3. Бинарники Nemac ───
echo -e "${CYAN}[3/8] Проверяю бинарники Nemac...${NC}"
BINARIES=(
    "nemac-session:Сессия (главный процесс)"
    "nemac-settings-daemon:Демон настроек (запускает рабочий стол)"
    "nemac-statusbar:Верхняя панель"
    "nemac-dock:Док-панель"
    "nemac-launcher:Лаунчер приложений"
    "nemac-filemanager:Файловый менеджер / рабочий стол"
    "nemac-notificationd:Уведомления"
    "nemac-powerman:Управление питанием"
    "nemac-clipboard:Буфер обмена"
    "nemac-xembedsniproxy:Системный трей (SNI)"
    "nemac-gmenuproxy:Глобальное меню"
    "chotkeys:Горячие клавиши"
    "cupdatecursor:Обновление курсора"
    "nemac-screenshot:Скриншоты"
    "nemac-terminal:Терминал"
    "nemac-settings:Настройки"
    "nemac-screenlocker:Блокировка экрана"
)
NEMAC_MISSING=0
for entry in "${BINARIES[@]}"; do
    IFS=: read -r bin desc <<< "$entry"
    path=$(which "$bin" 2>/dev/null)
    if [ -n "$path" ]; then
        ok "$bin — $desc"
    else
        fail "$bin — $desc — НЕ НАЙДЕН"
        NEMAC_MISSING=$((NEMAC_MISSING+1))
    fi
done
if [ $NEMAC_MISSING -gt 0 ]; then
    echo ""
    echo -e "  ${YELLOW}Пересоберите: cd /opt/nemac-de && sudo bash installer.sh${NC}"
fi
echo ""

# ─── 4. Библиотеки (ldd) ───
echo -e "${CYAN}[4/8] Проверяю зависимости библиотек (ldd)...${NC}"
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
    ok "Все критичные бинарники — зависимости библиотек в порядке"
fi
echo ""

# ─── 5. QML-модули Nemac (libnemac) ───
echo -e "${CYAN}[5/8] Проверяю QML-плагины Nemac (libnemac)...${NC}"
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
    echo -e "  ${RED}Пересобрать: cd /opt/nemac-de/libnemac/build && cmake .. && make && sudo make install${NC}"
fi
echo ""

# ─── 6. Системные QML-модули ───
echo -e "${CYAN}[6/8] Проверяю системные QML-модули...${NC}"
SYS_QML_MODULES=(
    "QtQuick.2:qt5-declarative"
    "QtQuick/Controls.2:qt5-quickcontrols2"
    "QtQuick/Layouts:qt5-declarative"
    "QtQuick/Window.2:qt5-declarative"
    "QtGraphicalEffects:qt5-graphicaleffects"
    "Qt/labs/platform:qt5-quickcontrols2"
    "Qt/labs/settings:qt5-quickcontrols2"
    "NemacUI:nemacui (сборка из /opt/nemac-de/nemacui)"
)
SYS_QML_MISSING=0
for entry in "${SYS_QML_MODULES[@]}"; do
    IFS=: read -r mod pkg <<< "$entry"
    if [ -d "$QML_DIR/$mod" ]; then
        ok "$mod"
    else
        fail "$mod — НЕ НАЙДЕН в $QML_DIR"
        [ -n "$pkg" ] && echo -e "       ${YELLOW}Пакет: $pkg${NC}"
        SYS_QML_MISSING=$((SYS_QML_MISSING+1))
    fi
done
echo ""

# ─── 7. Файл сессии и конфиги ───
echo -e "${CYAN}[7/8] Проверяю файл сессии и конфиги...${NC}"
if [ -f /usr/share/xsessions/nemac.desktop ]; then
    ok "/usr/share/xsessions/nemac.desktop — сессия для LightDM/SDDM/GDM"
    exec_line=$(grep "^Exec=" /usr/share/xsessions/nemac.desktop | cut -d= -f2)
    if which "$exec_line" &>/dev/null; then
        ok "Exec=$exec_line → найден"
    else
        fail "Exec=$exec_line → НЕ найден в PATH"
    fi
else
    fail "/usr/share/xsessions/nemac.desktop НЕ найден (DM не увидит Nemac)"
fi

if [ -f /etc/nemac ]; then
    ver=$(grep "Version" /etc/nemac 2>/dev/null | cut -d= -f2)
    ok "/etc/nemac — версия $ver"
else
    warn "/etc/nemac не найден (не критично)"
fi

real_user="${SUDO_USER:-$USER}"
real_home=$(eval echo "~$real_user")
if [ -f "$real_home/.xinitrc" ]; then
    if grep -q "nemac-session" "$real_home/.xinitrc" 2>/dev/null; then
        ok "~/.xinitrc содержит nemac-session (startx готов)"
    else
        warn "~/.xinitrc есть, но nemac-session в нём нет (startx не запустит Nemac)"
    fi
else
    warn "~/.xinitrc не найден (startx не настроен, но LightDM работает без него)"
fi

# KWin конфиг
kwinrc="$real_home/.config/kwinrc"
if [ -f "$kwinrc" ]; then
    if grep -q "org.nemac.decoration" "$kwinrc" 2>/dev/null; then
        ok "kwinrc — декорация Nemac настроена"
    else
        warn "kwinrc — декорация Nemac НЕ настроена (будет Breeze по умолчанию)"
    fi
else
    warn "kwinrc не найден (будет создан при первом запуске)"
fi
echo ""

# ─── 8. Тест запуска компонентов ───
echo -e "${CYAN}[8/8] Тестирую запуск компонентов (по 3 сек каждый)...${NC}"
if [ -z "$DISPLAY" ]; then
    warn "DISPLAY не задан, пропускаю тест запуска"
    info "Запустите: DISPLAY=:0 nemac diagnose"
else
    TEST_BINS=(nemac-settings-daemon nemac-statusbar nemac-dock nemac-launcher nemac-filemanager)
    for bin in "${TEST_BINS[@]}"; do
        path=$(which "$bin" 2>/dev/null)
        if [ -z "$path" ]; then
            fail "$bin — не найден, пропускаю"
            continue
        fi
        output=$($bin 2>&1 & PID=$!; sleep 3; kill $PID 2>/dev/null; wait $PID 2>/dev/null)
        errors=$(echo "$output" | grep -iE "error|fatal|not found|not installed|cannot load|failed to load|unavailable|module.*is not" | grep -iv "sniproxy\|dbus service\|global menu" | head -5)
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

# ─── Итог ───
echo ""
echo -e "${BOLD}═══════════════════════════════════════════${NC}"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}  Всё в порядке! Ошибок не обнаружено.${NC}"
else
    echo -e "${RED}  Найдено проблем: $ERRORS${NC}"
    echo ""
    echo -e "  ${YELLOW}Быстрый фикс — переустановить:${NC}"
    echo -e "  ${CYAN}cd /opt/nemac-de && sudo git pull && sudo bash installer.sh${NC}"
fi
echo -e "${BOLD}═══════════════════════════════════════════${NC}"
echo ""
