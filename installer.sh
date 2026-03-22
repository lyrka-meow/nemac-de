#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

NEMAC_DIR="/opt/nemac-de"
NEMAC_BIN="/usr/local/bin/nemac"
NEMAC_REPO="https://github.com/lyrka-meow/nemac-de.git"
NEMAC_VERSION="0.8"
START_CMD="exec nemac-session"

BUILD_ORDER=(
    "libnemac"
    "nemacui"
    "core"
    "kwin-plugins"
    "qt-plugins"
    "dock"
    "statusbar"
    "launcher"
    "settings"
    "filemanager"
    "screenlocker"
    "screenshot"
    "terminal"
    "texteditor"
    "calculator"
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
    echo -e "  ${BLUE}[1/6]${NC} Устанавливаю зависимости..."

    local deps=(
        git cmake make gcc
        qt5-tools extra-cmake-modules
        qt5-base qt5-declarative qt5-quickcontrols2 qt5-x11extras qt5-svg
        kwin kwindowsystem kidletime kcoreaddons kdecoration
        polkit polkit-qt5
        networkmanager-qt
        libxcb xcb-util xcb-util-wm xcb-util-keysyms
        libpulse
        bluez bluez-qt
        solid kio
        xdg-utils
        freetype2 fontconfig
        xorg-server-devel
        syntax-highlighting5
        libxcrypt icu
        xclip
    )

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

    if ! pacman -Qi libcanberra &>/dev/null; then
        deps+=(libcanberra)
    fi

    pacman -S --needed --noconfirm "${deps[@]}" > /tmp/nemac-deps.log 2>&1
    echo -e "  ${GREEN}[1/6]${NC} Зависимости установлены  ${GREEN}✓${NC}"
}

download_sources() {
    echo -e "  ${BLUE}[2/6]${NC} Скачиваю исходники..."

    if [ -d "$NEMAC_DIR/.git" ]; then
        cd "$NEMAC_DIR" && git pull --quiet 2>/dev/null || true
    else
        rm -rf "$NEMAC_DIR"
        git clone --quiet "$NEMAC_REPO" "$NEMAC_DIR"
    fi

    echo -e "  ${GREEN}[2/6]${NC} Исходники скачаны  ${GREEN}✓${NC}"
}

build_sources() {
    echo -e "  ${BLUE}[3/6]${NC} Собираю компоненты (это может занять несколько минут)..."

    local total=${#BUILD_ORDER[@]}
    local current=0
    local failed=()

    for component in "${BUILD_ORDER[@]}"; do
        current=$((current + 1))
        local src_dir="$NEMAC_DIR/$component"

        if [ ! -d "$src_dir" ]; then
            continue
        fi

        echo -ne "         Собираю [$current/$total] $component...\r"
        rm -rf "$src_dir/build"
        mkdir -p "$src_dir/build"
        cd "$src_dir/build"

        if cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr .. > /tmp/nemac-cmake-$component.log 2>&1; then
            if make -j"$(nproc)" > /tmp/nemac-make-$component.log 2>&1; then
                make install > /dev/null 2>&1
            else
                failed+=("$component")
            fi
        else
            failed+=("$component")
        fi
    done

    if [ ${#failed[@]} -gt 0 ]; then
        echo -e "  ${YELLOW}[3/6]${NC} Собрано (ошибки: ${failed[*]})  ${YELLOW}!${NC}"
        echo -e "         ${YELLOW}Логи ошибок: /tmp/nemac-*.log${NC}"
    else
        echo -e "  ${GREEN}[3/6]${NC} Все компоненты собраны  ${GREEN}✓${NC}"
    fi
}

install_assets() {
    echo -e "  ${BLUE}[4/6]${NC} Устанавливаю обои, иконки, темы..."

    if [ -d "$NEMAC_DIR/wallpapers/sources" ]; then
        mkdir -p /usr/share/backgrounds/nemacde
        cp -f "$NEMAC_DIR/wallpapers/sources"/*.jpg /usr/share/backgrounds/nemacde/ 2>/dev/null || true
    fi

    if [ -d "$NEMAC_DIR/icons/Crule" ]; then
        cp -rf "$NEMAC_DIR/icons/Crule" /usr/share/icons/
        cp -rf "$NEMAC_DIR/icons/Crule-dark" /usr/share/icons/ 2>/dev/null || true
        gtk-update-icon-cache /usr/share/icons/Crule 2>/dev/null || true
    fi

    if [ -d "$NEMAC_DIR/cursor-themes/nemac-light" ]; then
        cp -rf "$NEMAC_DIR/cursor-themes/nemac-light" /usr/share/icons/
        cp -rf "$NEMAC_DIR/cursor-themes/nemac-dark" /usr/share/icons/ 2>/dev/null || true
    fi

    if [ -d "$NEMAC_DIR/gtk-themes/Nemac" ]; then
        mkdir -p /usr/share/themes
        cp -rf "$NEMAC_DIR/gtk-themes/Nemac" /usr/share/themes/
        cp -rf "$NEMAC_DIR/gtk-themes/Nemac-light" /usr/share/themes/ 2>/dev/null || true
        cp -rf "$NEMAC_DIR/gtk-themes/Nemac-dark" /usr/share/themes/ 2>/dev/null || true
    fi

    echo -e "  ${GREEN}[4/6]${NC} Ресурсы установлены  ${GREEN}✓${NC}"
}

install_config() {
    echo -e "  ${BLUE}[5/6]${NC} Настраиваю систему..."

    rm -f /usr/share/applications/cutefish-*.desktop 2>/dev/null

    cp "$NEMAC_DIR/nemac" "$NEMAC_BIN"
    chmod +x "$NEMAC_BIN"

    cat > /etc/nemac << CONF
[General]
Version=$NEMAC_VERSION
CONF

    cat > /etc/nemacde << CONF
[General]
NemacDE=true
CONF

    echo -e "  ${GREEN}[5/6]${NC} Конфигурация готова  ${GREEN}✓${NC}"
}

setup_xinitrc() {
    echo -e "  ${BLUE}[6/6]${NC} Настраиваю автозапуск..."

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

    echo -e "  ${GREEN}[6/6]${NC} Файл ~/.xinitrc настроен  ${GREEN}✓${NC}"
}

uninstall_nemac() {
    print_header
    echo -e "  ${RED}Удаление Nemac DE...${NC}"
    echo ""

    rm -rf "$NEMAC_DIR"
    rm -f "$NEMAC_BIN"
    rm -f /etc/nemac /etc/nemacde
    rm -rf /usr/share/backgrounds/nemacde
    rm -rf /usr/share/icons/nemac-light /usr/share/icons/nemac-dark
    rm -rf /usr/share/themes/Nemac /usr/share/themes/Nemac-light /usr/share/themes/Nemac-dark

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
    download_sources
    build_sources
    install_assets
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

# Если передан аргумент --uninstall — удаляем
if [ "$1" = "--uninstall" ]; then
    check_root
    uninstall_nemac
    exit 0
fi

do_install
