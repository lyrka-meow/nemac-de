cmake_minimum_required(VERSION 3.5)
project(gtk-theme)
install(DIRECTORY Nemac DESTINATION ${CMAKE_INSTALL_PREFIX}/share/themes)
install(DIRECTORY Nemac-light DESTINATION ${CMAKE_INSTALL_PREFIX}/share/themes)
install(DIRECTORY Nemac-dark DESTINATION ${CMAKE_INSTALL_PREFIX}/share/themes)
    
