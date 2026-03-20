set(SCREEN_SRCS
    wallpaper.cpp
    wallpaper.h
    plugin.cpp
)

find_package(Qt5 REQUIRED COMPONENTS DBus)

add_library(nemacsystem_qmlplugins SHARED ${SCREEN_SRCS})

target_link_libraries (nemacsystem_qmlplugins
    Qt5::Core
    Qt5::Quick
    Qt5::Gui
    Qt5::DBus
)

install(TARGETS nemacsystem_qmlplugins DESTINATION ${INSTALL_QMLDIR}/Nemac/System)
install(FILES qmldir DESTINATION ${INSTALL_QMLDIR}/Nemac/System)