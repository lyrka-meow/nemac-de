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
├── installer.sh    # Интерактивный установщик (TUI-меню)
├── nemac           # CLI-утилита управления (ставится в /usr/local/bin/)
├── LICENSE          # GPL-3.0
└── README.md
```

## Лицензия

GPL-3.0 — см. [LICENSE](LICENSE).

Основан на исходниках [CutefishOS](https://github.com/cutefishos) (GPL-3.0).
