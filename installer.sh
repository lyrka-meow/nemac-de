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
NEMAC_SRC="$NEMAC_DIR/src"
NEMAC_BIN="/usr/local/bin/nemac"
XINITRC_FILE="$HOME/.xinitrc"
START_CMD="exec nemac-session"

CUTEFISH_REPOS=(
    "cutefishos/libcutefish"
    "cutefishos/fishui"
    "cutefishos/core"
    "cutefishos/dock"
    "cutefishos/statusbar"
    "cutefishos/launcher"
    "cutefishos/settings"
    "cutefishos/filemanager"
    "cutefishos/screenlocker"
    "cutefishos/screenshot"
    "cutefishos/terminal"
    "cutefishos/kwin-plugins"
    "cutefishos/wallpapers"
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
    echo -e "${BLUE}[1/4] Установка зависимостей...${NC}"
    pacman -S --needed --noconfirm \
        git cmake make gcc \
        qt5-base qt5-declarative qt5-quickcontrols2 qt5-x11extras qt5-tools \
        kwin kwindowsystem kidletime \
        polkit polkit-qt5 \
        networkmanager-qt \
        xorg-server xorg-xinit xorg-xrdb \
        libxcb xcb-util xcb-util-wm \
        pulseaudio libpulse \
        bluez bluez-qt \
        solid \
        kio \
        xdg-utils \
        freetype2 fontconfig 2>&1 | while read -r line; do
            echo -e "  ${line}"
        done
    echo -e "${GREEN}  Зависимости установлены.${NC}"
}

download_sources() {
    echo -e "${BLUE}[2/4] Скачивание исходников Cutefish...${NC}"
    mkdir -p "$NEMAC_SRC"

    local total=${#CUTEFISH_REPOS[@]}
    local current=0

    for repo in "${CUTEFISH_REPOS[@]}"; do
        current=$((current + 1))
        local name=$(basename "$repo")
        local target="$NEMAC_SRC/$name"

        if [ -d "$target" ]; then
            echo -e "  ${YELLOW}[$current/$total]${NC} $name — уже скачан, обновляю..."
            cd "$target" && git pull --quiet 2>/dev/null || true
        else
            echo -e "  ${GREEN}[$current/$total]${NC} Скачиваю $name..."
            git clone --quiet "https://github.com/$repo.git" "$target" 2>/dev/null
        fi
    done

    echo -e "${GREEN}  Все исходники скачаны в $NEMAC_SRC${NC}"
}

build_sources() {
    echo -e "${BLUE}[3/4] Сборка компонентов...${NC}"

    local build_order=(
        "libcutefish"
        "fishui"
        "core"
        "kwin-plugins"
        "dock"
        "statusbar"
        "launcher"
        "settings"
        "filemanager"
        "screenlocker"
        "screenshot"
        "terminal"
    )

    local total=${#build_order[@]}
    local current=0

    for component in "${build_order[@]}"; do
        current=$((current + 1))
        local src_dir="$NEMAC_SRC/$component"

        if [ ! -d "$src_dir" ]; then
            echo -e "  ${YELLOW}[$current/$total]${NC} $component — не найден, пропускаю"
            continue
        fi

        echo -e "  ${GREEN}[$current/$total]${NC} Собираю $component..."
        mkdir -p "$src_dir/build"
        cd "$src_dir/build"

        if cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr .. > /dev/null 2>&1; then
            if make -j"$(nproc)" > /dev/null 2>&1; then
                make install > /dev/null 2>&1
                echo -e "  ${GREEN}  ✓ $component собран и установлен${NC}"
            else
                echo -e "  ${RED}  ✗ $component — ошибка сборки (make)${NC}"
            fi
        else
            echo -e "  ${RED}  ✗ $component — ошибка конфигурации (cmake)${NC}"
        fi
    done

    echo -e "${GREEN}  Сборка завершена.${NC}"
}

install_nemac_cmd() {
    echo -e "${BLUE}[4/4] Установка команды 'nemac'...${NC}"

    local script_url="https://raw.githubusercontent.com/lyrka-meow/nemac-de/main/nemac"
    if [ -f "$(dirname "$0")/nemac" ] 2>/dev/null; then
        cp "$(dirname "$0")/nemac" "$NEMAC_BIN"
    else
        curl -fsSL "$script_url" -o "$NEMAC_BIN" 2>/dev/null || {
            # Если curl не удался, создаем fallback
            cat > "$NEMAC_BIN" << 'NEMAC_SCRIPT'
#!/bin/bash
echo "Nemac CLI — используйте установщик для переустановки"
NEMAC_SCRIPT
        }
    fi

    chmod +x "$NEMAC_BIN"
    echo -e "${GREEN}  Команда 'nemac' установлена. Введите 'nemac' в терминале для управления.${NC}"
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
        if grep -q "nemac-session\|cutefish-session" "$target"; then
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
    install_nemac_cmd
    echo ""
    echo -e "${GREEN}=====================================${NC}"
    echo -e "${GREEN}  Nemac DE успешно установлен!${NC}"
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
    echo -e "${GREEN}Исходники скачаны в: ${YELLOW}$NEMAC_SRC${NC}"
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

    local real_user="${SUDO_USER:-$USER}"
    local real_home
    real_home=$(eval echo "~$real_user")
    local target="$real_home/.xinitrc"

    if [ -f "$target" ]; then
        sed -i '/nemac-session/d' "$target"
        sed -i '/cutefish-session/d' "$target"
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
        echo -e "  ${GREEN}1${NC}) Полная установка (зависимости + исходники + сборка)"
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
