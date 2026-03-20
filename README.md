# Nemac DE

**Nemac** — десктопное окружение для Linux на базе компонентов [CutefishOS](https://github.com/cutefishos), с удобным установщиком и CLI-инструментом управления.

> Поддерживается только **Arch Linux** и производные.

## Установка

Одной командой:

```bash
sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/lyrka-meow/nemac-de/main/installer.sh)"
```

## Управление

После установки доступна команда `nemac` в терминале:

```bash
nemac
```

Через неё можно:
- Переустановить / обновить DE
- Настроить `~/.xinitrc`
- Обновить исходники
- Удалить Nemac DE

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
├── sddm-theme/        # Тема SDDM
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
| **sddm-theme** | Тема менеджера входа SDDM |
| **cursor-themes** | Темы курсора (светлая/тёмная) |
| **gtk-themes** | GTK-темы (светлая/тёмная) |

## Лицензия

GPL-3.0 — см. [LICENSE](LICENSE).

Основан на исходниках [CutefishOS](https://github.com/cutefishos) (GPL-3.0).
