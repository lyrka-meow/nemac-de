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

INSTALL_COMPONENTS=(
    "wallpapers"
    "icons"
    "cursor-themes"
    "gtk-themes"
    "sddm-theme"
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
    echo -e "${BOLD}  Nemac Desktop Environment — Installer${NC}"
    echo -e "${CYAN}=================================================${NC}"
    echo ""
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Этот скрипт нужно запускать с правами root (sudo)${NC}"
        echo -e "Запустите: ${YELLOW}sudo sh -c \"\$(curl -fsSL ...)\"${NC}"
        exit 1
    fi
}

check_arch() {
    if ! command -v pacman &> /dev/null; then
        echo -e "${RED}Ошибка: pacman не найден.${NC}"
        echo -e "${RED}Nemac DE поддерживает только Arch Linux и производные.${NC}"
        exit 1
    fi
}

install_dependencies() {
    echo -e "${BLUE}[1/5] Установка зависимостей...${NC}"

    # Сборочные зависимости (нужны только для компиляции)
    local build_deps=(
        git cmake make gcc
        qt5-tools
        extra-cmake-modules
    )

    # Рантайм-зависимости (нужны для работы DE)
    local runtime_deps=(
        qt5-base qt5-declarative qt5-quickcontrols2 qt5-x11extras qt5-svg
        kwin kwindowsystem kidletime kdecoration
        polkit polkit-qt5
        networkmanager-qt modemmanager-qt
        libxcb xcb-util xcb-util-wm xcb-util-keysyms
        libpulse
        bluez bluez-qt
        solid kio
        xdg-utils
        freetype2 fontconfig
    )

    # Xorg — ставим только если нет ни xorg-server, ни wayland-сессии
    if ! pacman -Qi xorg-server &>/dev/null; then
        echo -e "  ${YELLOW}Xorg не найден, добавляю в зависимости...${NC}"
        runtime_deps+=(xorg-server xorg-xinit xorg-xrdb)
    else
        echo -e "  ${GREEN}Xorg уже установлен, пропускаю${NC}"
        # xorg-xinit и xorg-xrdb могут быть не установлены
        if ! pacman -Qi xorg-xinit &>/dev/null; then
            runtime_deps+=(xorg-xinit)
        fi
        if ! pacman -Qi xorg-xrdb &>/dev/null; then
            runtime_deps+=(xorg-xrdb)
        fi
    fi

    # Аудио — не трогаем если уже есть pipewire-pulse или pulseaudio
    if pacman -Qi pipewire-pulse &>/dev/null; then
        echo -e "  ${GREEN}PipeWire (pulse) уже установлен, используем его${NC}"
    elif pacman -Qi pulseaudio &>/dev/null; then
        echo -e "  ${GREEN}PulseAudio уже установлен, используем его${NC}"
    else
        echo -e "  ${YELLOW}Аудио-сервер не найден, ставлю pipewire-pulse...${NC}"
        runtime_deps+=(pipewire-pulse)
    fi

    # libcanberra — для звуковых событий
    if ! pacman -Qi libcanberra &>/dev/null; then
        runtime_deps+=(libcanberra)
    fi

    pacman -S --needed --noconfirm "${build_deps[@]}" "${runtime_deps[@]}" 2>&1 | while read -r line; do
        echo -e "  ${line}"
    done
    echo -e "${GREEN}  Зависимости установлены.${NC}"
}

download_sources() {
    echo -e "${BLUE}[2/5] Скачивание исходников Nemac...${NC}"

    if [ -d "$NEMAC_DIR/.git" ]; then
        echo -e "  ${YELLOW}Репозиторий уже скачан, обновляю...${NC}"
        cd "$NEMAC_DIR" && git pull --quiet 2>/dev/null || true
    else
        rm -rf "$NEMAC_DIR"
        echo -e "  ${GREEN}Клонирую репозиторий...${NC}"
        git clone --quiet "$NEMAC_REPO" "$NEMAC_DIR"
    fi

    echo -e "${GREEN}  Исходники скачаны в $NEMAC_DIR${NC}"
}

build_sources() {
    echo -e "${BLUE}[3/5] Сборка компонентов...${NC}"

    local total=${#BUILD_ORDER[@]}
    local current=0
    local failed=()

    for component in "${BUILD_ORDER[@]}"; do
        current=$((current + 1))
        local src_dir="$NEMAC_DIR/$component"

        if [ ! -d "$src_dir" ]; then
            echo -e "  ${YELLOW}[$current/$total]${NC} $component — не найден, пропускаю"
            continue
        fi

        echo -e "  ${GREEN}[$current/$total]${NC} Собираю $component..."
        rm -rf "$src_dir/build"
        mkdir -p "$src_dir/build"
        cd "$src_dir/build"

        if cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr .. > /tmp/nemac-cmake-$component.log 2>&1; then
            if make -j"$(nproc)" > /tmp/nemac-make-$component.log 2>&1; then
                make install > /dev/null 2>&1
                echo -e "    ${GREEN}✓ $component собран и установлен${NC}"
            else
                echo -e "    ${RED}✗ $component — ошибка сборки (make)${NC}"
                echo -e "    ${YELLOW}Лог: /tmp/nemac-make-$component.log${NC}"
                failed+=("$component")
            fi
        else
            echo -e "    ${RED}✗ $component — ошибка конфигурации (cmake)${NC}"
            echo -e "    ${YELLOW}Лог: /tmp/nemac-cmake-$component.log${NC}"
            failed+=("$component")
        fi
    done

    if [ ${#failed[@]} -gt 0 ]; then
        echo ""
        echo -e "  ${YELLOW}Не удалось собрать: ${failed[*]}${NC}"
        echo -e "  ${YELLOW}Проверьте логи в /tmp/nemac-*.log${NC}"
    fi

    echo -e "${GREEN}  Сборка завершена.${NC}"
}

install_assets() {
    echo -e "${BLUE}[4/5] Установка ресурсов (обои, иконки, темы)...${NC}"

    # Обои
    if [ -d "$NEMAC_DIR/wallpapers/sources" ]; then
        mkdir -p /usr/share/wallpapers/nemac
        cp -f "$NEMAC_DIR/wallpapers/sources"/*.jpg /usr/share/wallpapers/nemac/ 2>/dev/null || true
        echo -e "    ${GREEN}✓ Обои установлены${NC}"
    fi

    # Иконки
    if [ -d "$NEMAC_DIR/icons/Crule" ]; then
        cp -rf "$NEMAC_DIR/icons/Crule" /usr/share/icons/
        cp -rf "$NEMAC_DIR/icons/Crule-dark" /usr/share/icons/ 2>/dev/null || true
        gtk-update-icon-cache /usr/share/icons/Crule 2>/dev/null || true
        echo -e "    ${GREEN}✓ Иконки установлены${NC}"
    fi

    # Курсоры
    if [ -d "$NEMAC_DIR/cursor-themes/nemac-light" ]; then
        cp -rf "$NEMAC_DIR/cursor-themes/nemac-light" /usr/share/icons/
        cp -rf "$NEMAC_DIR/cursor-themes/nemac-dark" /usr/share/icons/ 2>/dev/null || true
        echo -e "    ${GREEN}✓ Темы курсоров установлены${NC}"
    fi

    # GTK-темы
    if [ -d "$NEMAC_DIR/gtk-themes/Nemac" ]; then
        mkdir -p /usr/share/themes
        cp -rf "$NEMAC_DIR/gtk-themes/Nemac" /usr/share/themes/
        cp -rf "$NEMAC_DIR/gtk-themes/Nemac-light" /usr/share/themes/ 2>/dev/null || true
        cp -rf "$NEMAC_DIR/gtk-themes/Nemac-dark" /usr/share/themes/ 2>/dev/null || true
        echo -e "    ${GREEN}✓ GTK-темы установлены${NC}"
    fi

    # SDDM-тема
    if [ -d "$NEMAC_DIR/sddm-theme" ]; then
        mkdir -p /usr/share/sddm/themes/nemac
        cp -rf "$NEMAC_DIR/sddm-theme"/* /usr/share/sddm/themes/nemac/ 2>/dev/null || true
        echo -e "    ${GREEN}✓ SDDM-тема установлена${NC}"
    fi

    echo -e "${GREEN}  Ресурсы установлены.${NC}"
}

install_nemac_cmd() {
    echo -e "${BLUE}[5/5] Установка CLI и конфигурации...${NC}"

    cp "$NEMAC_DIR/nemac" "$NEMAC_BIN"
    chmod +x "$NEMAC_BIN"

    # /etc/nemac — версия и флаг для About в настройках
    cat > /etc/nemac << CONF
[General]
Version=$NEMAC_VERSION
CONF

    cat > /etc/nemacde << CONF
[General]
NemacDE=true
CONF

    echo -e "    ${GREEN}✓ Команда 'nemac' установлена${NC}"
    echo -e "    ${GREEN}✓ Конфигурация /etc/nemac создана (v$NEMAC_VERSION)${NC}"
}

setup_xinitrc() {
    echo -e "${YELLOW}Настройка ~/.xinitrc...${NC}"

    local real_user="${SUDO_USER:-$USER}"
    local real_home
    real_home=$(eval echo "~$real_user")
    local target="$real_home/.xinitrc"

    if [ ! -f "$target" ]; then
        echo "$START_CMD" > "$target"
        chown "$real_user":"$real_user" "$target"
        echo -e "${GREEN}  Создан $target с командой '$START_CMD'${NC}"
    else
        if grep -q "nemac-session" "$target"; then
            echo -e "${GREEN}  Nemac уже прописан в $target${NC}"
        else
            sed -i 's/^exec /#exec /g' "$target"
            echo "$START_CMD" >> "$target"
            echo -e "${GREEN}  Добавлено '$START_CMD' в $target${NC}"
        fi
    fi

    echo ""
    read -rp "Нажмите Enter для продолжения..."
}

full_install() {
    check_arch
    install_dependencies
    download_sources
    build_sources
    install_assets
    install_nemac_cmd
    echo ""
    echo -e "${GREEN}=====================================${NC}"
    echo -e "${GREEN}  Nemac DE v$NEMAC_VERSION установлен!${NC}"
    echo -e "${GREEN}=====================================${NC}"
    echo ""
    echo -e "Следующий шаг: настройте ${YELLOW}.xinitrc${NC} (пункт 2 в меню)"
    echo -e "или введите ${YELLOW}nemac${NC} в терминале для управления."
    echo ""
    read -rp "Нажмите Enter для продолжения..."
}

download_only() {
    check_arch
    echo -e "${YELLOW}Скачивание исходников без сборки...${NC}"
    echo ""
    download_sources
    echo ""
    echo -e "${GREEN}Исходники скачаны в: ${YELLOW}$NEMAC_DIR${NC}"
    echo -e "Можете изучить код или собрать вручную."
    echo ""
    read -rp "Нажмите Enter для продолжения..."
}

uninstall_nemac() {
    echo -e "${RED}Удаление Nemac DE...${NC}"
    echo ""

    echo -e "  ${YELLOW}Удаляю исходники и сборку...${NC}"
    rm -rf "$NEMAC_DIR"

    echo -e "  ${YELLOW}Удаляю команду nemac...${NC}"
    rm -f "$NEMAC_BIN"

    echo -e "  ${YELLOW}Удаляю конфигурации...${NC}"
    rm -f /etc/nemac /etc/nemacde

    echo -e "  ${YELLOW}Удаляю ресурсы...${NC}"
    rm -rf /usr/share/wallpapers/nemac
    rm -rf /usr/share/icons/nemac-light /usr/share/icons/nemac-dark
    rm -rf /usr/share/themes/Nemac /usr/share/themes/Nemac-light /usr/share/themes/Nemac-dark
    rm -rf /usr/share/sddm/themes/nemac

    local real_user="${SUDO_USER:-$USER}"
    local real_home
    real_home=$(eval echo "~$real_user")
    local target="$real_home/.xinitrc"

    if [ -f "$target" ]; then
        sed -i '/nemac-session/d' "$target"
        sed -i 's/^#exec /exec /g' "$target"
        echo -e "  ${YELLOW}Очищен $target${NC}"
    fi

    echo ""
    echo -e "${GREEN}Nemac DE удалён.${NC}"
    echo ""
    read -rp "Нажмите Enter для продолжения..."
}

show_menu() {
    while true; do
        print_header
        echo -e "  ${BOLD}Выберите действие:${NC}"
        echo ""
        echo -e "  ${GREEN}1${NC}) Полная установка (зависимости + сборка + ресурсы)"
        echo -e "  ${GREEN}2${NC}) Настроить ~/.xinitrc (для запуска через startx)"
        echo -e "  ${GREEN}3${NC}) Только скачать исходники (без сборки)"
        echo -e "  ${GREEN}4${NC}) Установить команду 'nemac' (CLI управление)"
        echo -e "  ${RED}5${NC}) Удалить Nemac DE"
        echo -e "  ${RED}0${NC}) Выход"
        echo ""
        read -rp "  Ваш выбор [0-5]: " choice

        case $choice in
            1) full_install ;;
            2) setup_xinitrc ;;
            3) download_only ;;
            4) install_nemac_cmd; read -rp "Нажмите Enter..." ;;
            5)
                echo ""
                read -rp "  Вы уверены? (y/N): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    uninstall_nemac
                fi
                ;;
            0)
                echo ""
                echo -e "${GREEN}  До встречи! Используйте 'nemac' для управления.${NC}"
                echo ""
                exit 0
                ;;
            *)
                echo -e "${RED}  Неверный выбор. Введите число от 0 до 5.${NC}"
                sleep 1
                ;;
        esac
    done
}

show_menu
