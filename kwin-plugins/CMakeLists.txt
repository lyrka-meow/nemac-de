cmake_minimum_required(VERSION 3.5)

project(nemac-kwin-plugins)

set(PROJECT_NAME "nemac-kwin")

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

add_subdirectory(plugins)

install(FILES config/kglobalshortcutsrc DESTINATION /etc/xdg)
install(FILES config/kwinrc DESTINATION /etc/xdg)
install(FILES config/kwinrulesrc DESTINATION /etc/xdg)

install(DIRECTORY scripts/nemaclauncher DESTINATION /usr/share/kwin/scripts)
install(DIRECTORY scripts/nemactiling DESTINATION /usr/share/kwin/scripts)
install(DIRECTORY scripts/nemacscrolling DESTINATION /usr/share/kwin/scripts)
install(DIRECTORY scripts/nemac_squash DESTINATION /usr/share/kwin/effects)
install(DIRECTORY scripts/nemac_scale DESTINATION /usr/share/kwin/effects)
install(DIRECTORY scripts/nemac_popups DESTINATION /usr/share/kwin/effects)
install(DIRECTORY tabbox/nemac_thumbnail DESTINATION /usr/share/kwin/tabbox)
