cmake_minimum_required(VERSION 3.22.1)

foreach(_var IN ITEMS
        LIBASS_VERSION
        LIBASS_SHA256
        LIBASS_ZIP_URL
        LIBASS_ZIP_MIRROR_URL
        LIBASS_CACHE_DIR
        LIBASS_ROOT
        LIBASS_ARCHIVE
        LIBASS_HEADER
        ANDROID_ABI)
    if(NOT DEFINED ${_var} OR "${${_var}}" STREQUAL "")
        message(FATAL_ERROR "${_var} is required")
    endif()
endforeach()

get_filename_component(_cache_parent "${LIBASS_CACHE_DIR}" DIRECTORY)
file(MAKE_DIRECTORY "${_cache_parent}")

# Android Gradle can build ABI variants in parallel; serialize the shared cache.
file(LOCK "${LIBASS_CACHE_DIR}.lock" GUARD PROCESS TIMEOUT 300)

if(NOT EXISTS "${LIBASS_ARCHIVE}" OR NOT EXISTS "${LIBASS_HEADER}")
    file(MAKE_DIRECTORY "${LIBASS_CACHE_DIR}")
    set(_libass_zip "${LIBASS_CACHE_DIR}/libass-android-${LIBASS_VERSION}.zip")

    # O zip vem de um release de terceiro (edde746/libass) e já falhou por erro HTTP no CI (31/10).
    # file(DOWNLOAD) não repete sozinho: tenta até 4 vezes, cada uma conferindo o sha256 fixado.
    set(_libass_ok FALSE)
    foreach(_attempt RANGE 1 4)
        # Alterna origens: uma fora do ar não derruba o build (o espelho fica nas tentativas ímpares).
        math(EXPR _libass_impar "${_attempt} % 2")
        if(_libass_impar)
            set(_libass_url "${LIBASS_ZIP_MIRROR_URL}")
        else()
            set(_libass_url "${LIBASS_ZIP_URL}")
        endif()
        message(STATUS "Fetching fork libass ${LIBASS_VERSION} from ${_libass_url} (attempt ${_attempt}/4)")
        file(DOWNLOAD "${_libass_url}" "${_libass_zip}"
            EXPECTED_HASH "SHA256=${LIBASS_SHA256}"
            TLS_VERIFY ON
            TIMEOUT 300
            INACTIVITY_TIMEOUT 60
            STATUS _libass_dl)
        list(GET _libass_dl 0 _libass_dl_code)
        if(_libass_dl_code EQUAL 0)
            set(_libass_ok TRUE)
            break()
        endif()
        file(REMOVE "${_libass_zip}")
        message(WARNING "libass download attempt ${_attempt}/4 failed: ${_libass_dl}")
        if(_attempt LESS 4)
            execute_process(COMMAND "${CMAKE_COMMAND}" -E sleep 15)
        endif()
    endforeach()
    if(NOT _libass_ok)
        message(FATAL_ERROR "Failed to download libass ${LIBASS_VERSION} from all sources: ${_libass_dl}")
    endif()

    file(REMOVE_RECURSE "${LIBASS_ROOT}")
    file(ARCHIVE_EXTRACT INPUT "${_libass_zip}" DESTINATION "${LIBASS_CACHE_DIR}")
endif()

if(NOT EXISTS "${LIBASS_ARCHIVE}")
    message(FATAL_ERROR "libass archive for ${ANDROID_ABI} was not extracted: ${LIBASS_ARCHIVE}")
endif()
if(NOT EXISTS "${LIBASS_HEADER}")
    message(FATAL_ERROR "libass headers were not extracted: ${LIBASS_HEADER}")
endif()
