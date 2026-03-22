# Nemac DE

**Nemac** — десктопное окружение для Linux на базе компонентов [CutefishOS](https://github.com/cutefishos), с удобным установщиком и CLI-инструментом управления.

> Поддерживается только **Arch Linux** и производные.  
> Работает только на **Xorg (X11)**. Запуск строго через `startx`.

## Установка

Одной командой:

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/lyrka-meow/nemac-de/main/installer.sh)"
```

## Управление

После установки доступна команда `nemac` в терминале:

```bash
nemac
```

Через неё: обновить DE, удалить Nemac DE и т.д.

## Запуск

После установки и настройки `.xinitrc`:

```bash
startx
```

## Структура

```
nemac-de/
├── core/               # Системные компоненты и бэкенд
├── nemacui/            # GUI-библиотека (на базе Qt Quick)
├── libnemac/           # Системная библиотека
├── qt-plugins/         # Плагин Qt-платформы, единый стиль
├── dock/               # Панель задач (таскбар)
├── statusbar/          # Верхняя статусбар-панель
├── launcher/           # Лаунчер приложений
├── terminal/           # Эмулятор терминала
├── settings/           # Системные настройки
├── screenshot/         # Инструмент скриншотов
├── filemanager/        # Файловый менеджер
├── screenlocker/       # Экран блокировки
├── texteditor/         # Текстовый редактор
├── calculator/         # Калькулятор
├── kwin-plugins/       # Плагины и конфигурация KWin
├── icons/              # Тема иконок
├── wallpapers/         # Обои
├── cursor-themes/      # Тема курсоров
├── gtk-themes/         # GTK-темы
├── installer.sh        # Интерактивный установщик (TUI-меню)
├── nemac               # CLI-утилита управления (/usr/local/bin/)
├── LICENSE             # GPL-3.0
└── README.md
```

## Компоненты

| Компонент | Описание |
|-----------|----------|
| **core** | Системные демоны, сессия, управление питанием, уведомления |
| **nemacui** | GUI-библиотека на Qt Quick (ребрендинг FishUI) |
| **libnemac** | Системная библиотека для интеграции компонентов |
| **dock** | Панель задач внизу экрана |
| **statusbar** | Верхняя панель состояния |
| **launcher** | Полноэкранный лаунчер приложений |
| **terminal** | Эмулятор терминала |
| **settings** | Приложение системных настроек |
| **screenshot** | Инструмент для создания скриншотов |
| **filemanager** | Файловый менеджер |
| **screenlocker** | Блокировка экрана |
| **texteditor** | Текстовый редактор |
| **calculator** | Калькулятор |
| **kwin-plugins** | Плагины оконного менеджера KWin |
| **qt-plugins** | Qt-тема и стиль виджетов |
| **icons** | Тема иконок Crule |
| **wallpapers** | Системные обои |
| **cursor-themes** | Темы курсора (светлая/тёмная) |
| **gtk-themes** | GTK-темы (светлая/тёмная) |

## Если сборка падает на CMake (KF5)

Сообщения вида `Could not find KF5WindowSystem`, `KF5::WindowSystem was not found` значат, что **не найдены CMake-конфиги KDE Frameworks 5**.

На **Arch / CachyOS** пакет `kwindowsystem` (без суффикса) — это **KF6**, он ставит только `KF6WindowSystem`. Nemac собирается на **Qt5 + KF5**, нужны пакеты с суффиксом **`5`**:

```bash
sudo pacman -S --needed \
  kwindowsystem5 kidletime5 kcoreaddons5 \
  libkscreen5 kio5 solid5 \
  networkmanager-qt5 bluez-qt5 \
  extra-cmake-modules qt5-base
```

Установщик `installer.sh` подтягивает эти имена автоматически.

Установщик вызывает CMake с **`-Wno-dev`**, чтобы не засорять лог предупреждениями ECM про **FindXCB** (имена `XCB_XCB`, `XCB_IMAGE` и т.д.) — это известная особенность модулей KDE, на результат сборки не влияет.

Если вы запускаете **CMake вручную** (например `cd core/build && cmake ..`), добавьте **`cmake -Wno-dev ..`** — иначе те же строки снова появятся в терминале; на успех конфигурации они не влияют.

Строка **`Could NOT find AppMenuGtkModule`** для `gmenuproxy` обычно **нормальна**: глобальное меню для GTK ставится опционально (`appmenu-gtk-module` в репозиториях); без неё Nemac всё равно собирается.

Логи: `/tmp/nemac-cmake-*.log` и `/tmp/nemac-make-*.log`.

## Лицензия

GPL-3.0 — см. [LICENSE](LICENSE).

Основан на исходниках [CutefishOS](https://github.com/cutefishos) (GPL-3.0).
