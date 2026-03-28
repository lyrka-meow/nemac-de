#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

NEMAC_REPO="lyrka-meow/nemac-de"
NEMAC_VERSION="3.4"
GITHUB_API="https://api.github.com/repos/$NEMAC_REPO/releases/latest"
NEMAC_BIN="/usr/local/bin/nemac"
NEMAC_DEV_BIN="/usr/local/bin/nemac-dev"
START_CMD="exec nemac-session"

RUNTIME_DEPS=(
    qt5-base qt5-declarative qt5-quickcontrols2 qt5-x11extras qt5-svg qt5-graphicaleffects
    qt5-sensors
    kwin kwin-x11 kdecoration
    kwindowsystem5 kidletime5 kcoreaddons5
    libkscreen5 kio5 solid5
    polkit polkit-qt5
    networkmanager-qt5
    libqt5xdg libdbusmenu-qt5
    libcanberra
    libxcb xcb-util xcb-util-wm xcb-util-keysyms
    libpulse
    bluez bluez-qt5
    xdg-utils
    freetype2 fontconfig
    syntax-highlighting5
    libxcrypt icu
    xclip
)

print_header() {
    clear
    echo -e "${CYAN}"
    echo '  _   _                            ____  _____ '
    echo ' | \ | | ___ _ __ ___   __ _  ___ |  _ \| ____|'
    echo ' |  \| |/ _ \ '\''_ ` _ \ / _` |/ __|| | | |  _|  '
    echo ' | |\  |  __/ | | | | | (_| | (__ | |_| | |___ '
    echo ' |_| \_|\___|_| |_| |_|\__,_|\___||____/|_____|'
    echo -e "${NC}"
    echo ""
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}  Запустите установщик с sudo:${NC}"
        echo -e "  ${YELLOW}sudo bash installer.sh${NC}"
        exit 1
    fi
}

check_arch() {
    if ! command -v pacman &> /dev/null; then
        echo -e "${RED}  Nemac DE работает только на Arch Linux.${NC}"
        exit 1
    fi
}

install_dependencies() {
    echo ""
    echo -e "  ${BLUE}[1/4]${NC} Устанавливаю зависимости..."

    local deps=("${RUNTIME_DEPS[@]}")

    if ! pacman -Qi xorg-server &>/dev/null; then
        deps+=(xorg-server)
    fi
    if ! pacman -Qi xorg-xinit &>/dev/null; then
        deps+=(xorg-xinit)
    fi
    if ! pacman -Qi xorg-xrdb &>/dev/null; then
        deps+=(xorg-xrdb)
    fi
    if ! pacman -Qi pipewire-pulse &>/dev/null && ! pacman -Qi pulseaudio &>/dev/null; then
        deps+=(pipewire-pulse)
    fi

    pacman -S --needed --noconfirm "${deps[@]}" > /tmp/nemac-deps.log 2>&1
    echo -e "  ${GREEN}[1/4]${NC} Зависимости установлены  ${GREEN}✓${NC}"
}

download_and_install() {
    echo -e "  ${BLUE}[2/4]${NC} Скачиваю Nemac DE..."

    local release_info download_url remote_tag

    release_info=$(curl -fsSL "$GITHUB_API" 2>/dev/null) || true

    if [ -z "$release_info" ]; then
        echo -e "  ${RED}[2/4]${NC} Не удалось получить информацию о релизе  ${RED}✗${NC}"
        echo -e "         ${YELLOW}Проверьте интернет или установите из исходников: nemac-dev build${NC}"
        exit 1
    fi

    remote_tag=$(echo "$release_info" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
    download_url=$(echo "$release_info" | grep '"browser_download_url"' | grep '\.tar\.gz"' | head -1 | sed 's/.*"\(https[^"]*\)".*/\1/')

    if [ -z "$download_url" ]; then
        echo -e "  ${RED}[2/4]${NC} Бинарный пакет не найден в релизе $remote_tag  ${RED}✗${NC}"
        echo -e "         ${YELLOW}Разработчик ещё не опубликовал бинарники.${NC}"
        echo -e "         ${YELLOW}Установите из исходников: nemac-dev build${NC}"
        exit 1
    fi

    echo -ne "         Скачиваю $remote_tag...\r"
    local tmpfile="/tmp/nemac-install-${remote_tag}.tar.gz"

    if ! curl -fSL "$download_url" -o "$tmpfile" 2>/dev/null; then
        echo -e "  ${RED}[2/4]${NC} Ошибка скачивания  ${RED}✗${NC}"
        exit 1
    fi

    echo -ne "         Устанавливаю...\r"
    tar xzf "$tmpfile" -C /
    rm -f "$tmpfile"

    echo -e "  ${GREEN}[2/4]${NC} Nemac DE $remote_tag установлен  ${GREEN}✓${NC}"
}

install_config() {
    echo -e "  ${BLUE}[3/4]${NC} Настраиваю систему..."

    rm -f /usr/share/applications/cutefish-*.desktop 2>/dev/null

    # Ensure management scripts from repo are available
    local repo_dir="/opt/nemac-de"
    if [ -d "$repo_dir" ]; then
        [ -f "$repo_dir/nemac" ] && cp "$repo_dir/nemac" "$NEMAC_BIN" && chmod +x "$NEMAC_BIN"
        [ -f "$repo_dir/nemac-dev" ] && cp "$repo_dir/nemac-dev" "$NEMAC_DEV_BIN" && chmod +x "$NEMAC_DEV_BIN"
    fi

    # Config might already be in tarball, but ensure it's correct
    cat > /etc/nemac << CONF
[General]
Version=$NEMAC_VERSION
CONF

    cat > /etc/nemacde << CONF
[General]
NemacDE=true
CONF

    echo -e "  ${GREEN}[3/4]${NC} Конфигурация готова  ${GREEN}✓${NC}"
}

setup_xinitrc() {
    echo -e "  ${BLUE}[4/4]${NC} Настраиваю автозапуск..."

    local real_user="${SUDO_USER:-$USER}"
    local real_home
    real_home=$(eval echo "~$real_user")
    local target="$real_home/.xinitrc"

    if [ ! -f "$target" ]; then
        echo "$START_CMD" > "$target"
        chown "$real_user":"$real_user" "$target"
    else
        if ! grep -q "nemac-session" "$target"; then
            sed -i 's/^exec /#exec /g' "$target"
            echo "$START_CMD" >> "$target"
        fi
    fi

    echo -e "  ${GREEN}[4/4]${NC} Файл ~/.xinitrc настроен  ${GREEN}✓${NC}"
}

uninstall_nemac() {
    print_header
    echo -e "  ${RED}Удаление Nemac DE...${NC}"
    echo ""

    # Binaries
    local bins=(
        nemac-session nemac-settings-daemon nemac-statusbar nemac-dock
        nemac-launcher nemac-filemanager nemac-notificationd nemac-powerman
        nemac-clipboard nemac-xembedsniproxy nemac-gmenuproxy chotkeys
        cupdatecursor nemac-screenshot nemac-terminal nemac-settings
        nemac-screenlocker nemac-shutdown nemac-screen-brightness
        nemac-cpufreq nemac-polkit-agent nemac-texteditor nemac-calculator
        ccheckpass nemac-updator
    )
    for bin in "${bins[@]}"; do
        rm -f "/usr/bin/$bin" 2>/dev/null
    done

    rm -f "$NEMAC_BIN" "$NEMAC_DEV_BIN"
    rm -f /etc/nemac /etc/nemacde
    rm -rf /usr/share/backgrounds/nemacde
    rm -rf /usr/share/icons/nemac-light /usr/share/icons/nemac-dark
    rm -rf /usr/share/icons/Crule /usr/share/icons/Crule-dark
    rm -rf /usr/share/themes/Nemac /usr/share/themes/Nemac-light /usr/share/themes/Nemac-dark
    rm -f /usr/share/xsessions/nemac.desktop
    rm -f /usr/share/applications/nemac-*.desktop
    rm -rf /usr/share/nemac-*
    rm -rf /usr/share/kwin/scripts/nemaclauncher
    rm -rf /usr/share/kwin/effects/nemac_*
    rm -rf /usr/share/kwin/tabbox/nemac_*
    rm -f /etc/xdg/autostart/nemac-polkit-agent.desktop
    rm -f /usr/lib/systemd/user/nemac-gmenuproxy.service
    rm -f /etc/nemac-dock-list.conf
    rm -rf /opt/nemac-de

    # QML plugins
    local qml_dir
    qml_dir=$(qmake -query QT_INSTALL_QML 2>/dev/null || echo "/usr/lib/qt/qml")
    rm -rf "$qml_dir/Nemac" "$qml_dir/NemacUI"
    rm -rf "$qml_dir/QtQuick/Controls.2/fish-style"

    # Qt plugins
    local qt_plugins
    qt_plugins=$(qmake -query QT_INSTALL_PLUGINS 2>/dev/null || echo "/usr/lib/qt/plugins")
    rm -f "$qt_plugins/styles/libnemacstyle.so"
    rm -f "$qt_plugins/platformthemes/libnemacplatformtheme.so"
    rm -f "$qt_plugins/kwin/effects/plugins/libroundedwindow.so"
    rm -f "$qt_plugins/org.kde.kdecoration2/libnemacdecoration.so"

    rm -rf /usr/lib/cmake/NemacUI

    # xinitrc
    local real_user="${SUDO_USER:-$USER}"
    local real_home
    real_home=$(eval echo "~$real_user")
    local target="$real_home/.xinitrc"

    if [ -f "$target" ]; then
        sed -i '/nemac-session/d' "$target"
        sed -i 's/^#exec /exec /g' "$target"
    fi

    echo -e "  ${GREEN}Nemac DE полностью удалён.${NC}"
    echo ""
}

do_install() {
    check_root
    check_arch

    print_header
    echo -e "  ${BOLD}Установка Nemac DE v${NEMAC_VERSION}${NC}"
    echo -e "  ${CYAN}—————————————————————————————————${NC}"

    install_dependencies
    download_and_install
    install_config
    setup_xinitrc

    echo ""
    echo -e "  ${CYAN}—————————————————————————————————${NC}"
    echo -e "  ${GREEN}${BOLD}Готово! Nemac DE установлен.${NC}"
    echo ""
    echo -e "  Для запуска выполните:"
    echo -e "  ${YELLOW}${BOLD}startx${NC}"
    echo ""
    echo -e "  Для управления (обновить, удалить):"
    echo -e "  ${YELLOW}nemac${NC}"
    echo ""
}

if [ "$1" = "--uninstall" ]; then
    check_root
    uninstall_nemac
    exit 0
fi

do_install
