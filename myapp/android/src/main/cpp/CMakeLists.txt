cmake_minimum_required(VERSION 3.10.2)

project("my_native_lib")

add_library(
    my_native_lib  # Имя библиотеки
    SHARED
    native_code.cpp  # Исходные файлы
)

find_library(log-lib log)  # Для Android NDK (логирование)

target_link_libraries(
    my_native_lib
    ${log-lib}
)