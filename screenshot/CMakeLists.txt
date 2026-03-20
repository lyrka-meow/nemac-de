cmake_minimum_required(VERSION 3.14)

project(nemac-screenshot LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt5 COMPONENTS Core DBus Gui Widgets Quick LinguistTools REQUIRED)

set(PROJECT_SOURCES
    src/main.cpp
    src/screenshotview.cpp
    qml.qrc
)

add_executable(nemac-screenshot
  ${PROJECT_SOURCES}
)

target_link_libraries(nemac-screenshot
  PRIVATE
  Qt5::Core
  Qt5::DBus
  Qt5::Gui
  Qt5::Widgets
  Qt5::Quick
)

file(GLOB TS_FILES ${CMAKE_CURRENT_SOURCE_DIR}/translations/*.ts)
qt5_create_translation(QM_FILES ${TS_FILES})
add_custom_target(translations DEPENDS ${QM_FILES} SOURCES ${TS_FILES})
add_dependencies(nemac-screenshot translations)

install(FILES ${QM_FILES} DESTINATION /usr/share/nemac-screenshot/translations)

install(TARGETS nemac-screenshot RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

install(FILES
    nemac-screenshot.desktop
    DESTINATION /usr/share/applications/
    COMPONENT Runtime
)
