project(nemac-shutdown)

add_executable(nemac-shutdown
    main.cpp
    actions.cpp
    qml.qrc
)

target_link_libraries(nemac-shutdown
        Qt5::Core
        Qt5::Widgets
        Qt5::Quick
        Qt5::QuickControls2
        Qt5::DBus
)

file(GLOB TS_FILES ${CMAKE_CURRENT_SOURCE_DIR}/translations/*.ts)
qt5_create_translation(QM_FILES ${TS_FILES})
add_custom_target(shutdown-translations DEPENDS ${QM_FILES} SOURCES ${TS_FILES})
add_dependencies(nemac-shutdown shutdown-translations)
install(FILES ${QM_FILES} DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/nemac-shutdown/translations)

install(TARGETS nemac-shutdown RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
