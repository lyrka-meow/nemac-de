find_package(PkgConfig)
pkg_check_modules(POLKIT_AGENT REQUIRED polkit-agent-1)
message(STATUS "polkit agent: ${POLKIT_AGENT_INCLUDE_DIRS} ${POLKIT_AGENT_LIBRARIES}")

find_package(PolkitQt5-1 REQUIRED)

include_directories(
    ${POLKIT_AGENT_INCLUDE_DIRS}
    "${POLKITQT-1_INCLUDE_DIR}"
)

add_executable(nemac-polkit-agent
    main.cpp
    polkitagentlistener.cpp
    dialog.cpp
    qml.qrc
)

target_link_libraries(nemac-polkit-agent
        Qt5::Core
        Qt5::Widgets
        Qt5::Quick
        Qt5::QuickControls2

        # NemacUI

        ${POLKITQT-1_CORE_LIBRARY}
        ${POLKITQT-1_AGENT_LIBRARY}
        ${POLKIT_AGENT_LDFLAGS}
)

file(GLOB TS_FILES translations/*.ts)
qt5_create_translation(QM_FILES ${TS_FILES})
add_custom_target(polkit-agent-translations DEPENDS ${QM_FILES} SOURCES ${TS_FILES})
add_dependencies(nemac-polkit-agent polkit-agent-translations)

install(TARGETS nemac-polkit-agent
    DESTINATION ${CMAKE_INSTALL_BINDIR}
    COMPONENT Runtime
)

install(FILES
nemac-polkit-agent.desktop
    DESTINATION "${CMAKE_INSTALL_FULL_SYSCONFDIR}/xdg/autostart"
    COMPONENT Runtime
)

install(FILES ${QM_FILES} DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/nemac-polkit-agent/translations)
