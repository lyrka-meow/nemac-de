project(nemac-sddm-helper)
set(PROJECT_NAME nemac-sddm-helper)

set(SRCS
    main.cpp
)

add_executable(${PROJECT_NAME}
    ${SRCS}
)

target_link_libraries(${PROJECT_NAME}
        Qt5::Core
        Qt5::Gui
)

configure_file(
    com.nemac.sddm.helper.pkexec.policy.in
    com.nemac.sddm.helper.pkexec.policy
    @ONLY
)

install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/com.nemac.sddm.helper.pkexec.policy DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/polkit-1/actions/)
