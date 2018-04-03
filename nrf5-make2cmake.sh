#!/usr/bin/env bash

#Copyright 2017 Jumper Labs Ltd.

#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

set -e


nrf52_cmake="nrf52.cmake"

\cat << 'EOF2' > ${nrf52_cmake}
cmake_minimum_required(VERSION 3.4.0)

FUNCTION(SET_COMPILER_OPTIONS TARGET)
	target_compile_options(${TARGET} PRIVATE
		$<$<COMPILE_LANGUAGE:C>:${CFLAGS}>
			$<$<COMPILE_LANGUAGE:CXX>:${CXXFLAGS}>
			$<$<COMPILE_LANGUAGE:ASM>:${ASMFLAGS}>
		)
ENDFUNCTION()


FUNCTION(NRF_FLASH_TARGET TARGET)


	if (NOT OPENOCD_BIN)
		find_program(OPENOCD_BIN openocd)
		if (NOT OPENOCD_BIN)
			message(WANING "OpenOCD binaries, not found, no FLASH target will be created")
			return()
		else()
			message(STATUS "Found OpenOCD binaries in ${OPENOCD_BIN}")
		endif()
	else()
		message(STATUS "Using OpenOCD binaries: ${OPENOCD_BIN}")
	endif()

	if (BOOTLOADER_FILE AND NOT NRFUTIL_BIN)
		find_program(NRFUTIL_BIN nrfutil)
		if (NOT NRFUTIL_BIN)
			message(WANING "nrfutil binaries, not found, no Bootloader settings can be created")
			return()
		else()
			message(STATUS "Found nrfutil binaries in ${NRFUTIL_BIN}")
		endif()
	else()
		message(STATUS "Using nrfutil binaries: ${NRFUTIL_BIN}")
	endif()




	set(FILE ${CMAKE_BINARY_DIR}/${TARGET})
	if (SOFTDEVICE)
		set(REQUIRE_MERGEHEX TRUE)
		set(SOFT_DEV_CMD "nrf5 mass_erase\; program \"${SOFTDEVICE}\" verify\;")
	else()
		set(SOFT_DEV_CMD "")
	endif()

	#nrfutil settings generate --family NRF52 --application remote_nordic.hex --application-version 1 --bootloader-version 1 --bl-settings-version 1 settings.hex



	if (BOOTLOADER_FILE)

		set(BOOT_FILE ${CMAKE_BINARY_DIR}/boot.hex)
		set(SETTINGS_FILE ${CMAKE_BINARY_DIR}/settings.hex)
		set(BOOT_CMD
				COMMAND echo "Preparing Bootloader"
				COMMAND rm -f ${SETTINGS_FILE}
				COMMAND rm -f ${BOOT_FILE}
				COMMAND ${NRFUTIL_BIN} settings generate --family NRF52 --application ${FILE}.hex --application-version 1 --bootloader-version 1 --bl-settings-version 1 ${SETTINGS_FILE}
				COMMAND ${MERGEHEX_BIN} -m ${BOOTLOADER_FILE} ${SETTINGS_FILE} -o ${BOOT_FILE}
				COMMAND echo "Bootloader hex done ${BOOT_FILE}"
				)
		set(REQUIRE_MERGEHEX TRUE)
	else()
		set(BOOT_CMD "")
	endif()



	if (REQUIRE_MERGEHEX AND NOT MERGEHEX_BIN)
		find_program(MERGEHEX_BIN mergehex)
		if (NOT MERGEHEX_BIN)
			message(WARNING "mergehex binaries, not found, no FLASH target will be created")
			return()
		else()
			message(STATUS "Found mergehex binaries in ${MERGEHEX_BIN}")
		endif()
	else()
		message(STATUS "Using mergehex binaries: ${MERGEHEX_BIN}")
	endif()




	if (OPENOCD_SCRIPT)
		set(OPENOCD_SCRIPT_CMD "-s ${OPENOCD_SCRIPT}")
	else()
		set(OPENOCD_SCRIPT_CMD "")
	endif()

	if(BOOT_FILE OR SOFTDEVICE)
		set(FULL_FILE ${CMAKE_BINARY_DIR}/full.hex)
		set(MERGE_CMD
				COMMAND rm -f ${FULL_FILE}
				COMMAND ${MERGEHEX_BIN} -m ${BOOT_FILE} ${SOFTDEVICE} ${FILE}.hex -o ${FULL_FILE}
				)
	else()
		set(FULL_FILE ${FILE}.hex)
		set(MERGE_CMD
				"")
	endif()

	set(OPENOCD_FLASH_CMD "reset_config none\; init\; halt\; nrf5 mass_erase\; program \"${FULL_FILE}\" verify\; reset\; exit")
	set(OPENOCD_DEBUG_CMD "reset_config none\; init\; halt\; nrf5 mass_erase\; program \"${FULL_FILE}\" verify\; verify\; reset halt\; exit")
	if (HLA_SERIAL)
		set(OPENOCD_FLASH_CMD "hla_serial ${HLA_SERIAL}\; ${OPENOCD_FLASH_CMD}")
		set(OPENOCD_DEBUG_CMD "hla_serial ${HLA_SERIAL}\; ${OPENOCD_DEBUG_CMD}")
	else()

	endif()


	add_custom_target(Flash
			DEPENDS ${TARGET}
			COMMAND rm -f ${FILE}.hex
			COMMAND rm -f ${FULL_FILE}
			COMMAND ${CMAKE_OBJCOPY} -Oihex ${FILE} ${FILE}.hex
			${BOOT_CMD}
			${MERGE_CMD}
			COMMAND ${OPENOCD_BIN} -f ${OPENOCD_CFG} ${OPENOCD_SCRIPT_CMD} -c "${OPENOCD_FLASH_CMD}"
			WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} USES_TERMINAL)

	add_custom_target(Flash-Debug
			DEPENDS ${TARGET}
			COMMAND rm -f ${FILE}.hex
			COMMAND rm -f ${FULL_FILE}
			COMMAND ${CMAKE_OBJCOPY} -Oihex ${FILE} ${FILE}.hex
			${BOOT_CMD}
			${MERGE_CMD}
			COMMAND ${OPENOCD_BIN} -f ${OPENOCD_CFG} ${OPENOCD_SCRIPT_CMD} -c "${OPENOCD_DEBUG_CMD}"
			WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} USES_TERMINAL)


ENDFUNCTION()

FUNCTION(PRINT_SIZE_OF_TARGETS TARGET)
    SET(FILENAME "${CMAKE_BINARY_DIR}/${TARGET}")
    add_custom_command(TARGET ${TARGET} POST_BUILD COMMAND ${CMAKE_SIZE} ${FILENAME})
ENDFUNCTION()


FUNCTION(ADD_HEX_BIN_TARGETS TARGET)
    SET(FILENAME "${CMAKE_BINARY_DIR}/${TARGET}")
    add_custom_command(TARGET ${TARGET} POST_BUILD COMMAND ${CMAKE_OBJCOPY} -Oihex ${FILENAME} ${FILENAME}.hex)
    add_custom_command(TARGET ${TARGET} POST_BUILD COMMAND ${CMAKE_OBJCOPY} -Obinary ${FILENAME} ${FILENAME}.bin)
ENDFUNCTION()


FUNCTION(SET_COMPILATION_FLAGS)
	foreach(LIB ${LIB_FILES})
	find_file(LIB_FILE_${LIB} ${LIB} ${CMAKE_SOURCE_DIR})
		if (NOT LIB_FILE_${LIB})
			list(APPEND LIBS ${LIB})
		else ()
			list(APPEND LIB_FILES_CLEAN ${LIB_FILE_${LIB}})
		endif()
	endforeach()
	string(REPLACE ";" " " LDFLAGS "${LDFLAGS}")
	set(CMAKE_C_FLAGS "" CACHE INTERNAL "c compiler flags")
	set(CMAKE_CXX_FLAGS "" CACHE INTERNAL "c++ compiler flags")
	set(CMAKE_ASM_FLAGS "-x assembler-with-cpp" CACHE INTERNAL "asm compiler flags")
	set(CMAKE_EXE_LINKER_FLAGS "${LDFLAGS} " CACHE INTERNAL "executable linker flags")
ENDFUNCTION()

FUNCTION(NRF_SET_COMPILERS)

	if (WIN32 OR WIN64)
		set(TOOL_EXECUTABLE_SUFFIX .exe)
	else()
		set(TOOL_EXECUTABLE_SUFFIX )
	endif()


	if(NOT TARGET_TRIPLET)
		set(TARGET_TRIPLET arm-none-eabi)
		set(EXE_EXTENSION ${TOOL_EXECUTABLE_SUFFIX})
		message(STATUS "Using default target triplet ${TARGET_TRIPLET}")
	else()
		set(EXE_EXTENSION )
		message(STATUS "Using target triplet ${TARGET_TRIPLET}")
	endif()
	if(NOT TOOLCHAIN_PATH OR C_COMPILER)
		get_filename_component(TOOLCHAIN_PATH ${C_COMPILER} DIRECTORY)
	else()
		if (NOT TOOLCHAIN_PATH STREQUAL "")
			set(TOOLCHAIN_PATH ${TOOLCHAIN_PATH}/)
		endif()
	endif()

	if(NOT C_COMPILER)
		set(C_COMPILER ${TOOLCHAIN_PATH}${TARGET_TRIPLET}-gcc${EXE_EXTENSION})
		message(STATUS "Using default C compiler: ${C_COMPILER}")
	else()
		message(STATUS "Using C compiler: ${CXX_COMPILER}")
	endif()

	if(NOT CXX_COMPILER)
		set(CXX_COMPILER ${TOOLCHAIN_PATH}${TARGET_TRIPLET}-c++${EXE_EXTENSION})
		message(STATUS "Using default C++ compiler: ${CXX_COMPILER}")
	else()
		message(STATUS "Using C++ compiler: ${CXX_COMPILER}")
	endif()

	if(NOT ASM_COMPILER)
		set(ASM_COMPILER ${TOOLCHAIN_PATH}${TARGET_TRIPLET}-gcc${EXE_EXTENSION})
		message(STATUS "Using default ASM compiler: ${ASM_COMPILER}")
	else()
		message(STATUS "Using ASM compiler: ${ASM_COMPILER}")
	endif()

	if(NOT COMPILER_SIZE_TOOL)
		set(COMPILER_SIZE_TOOL ${TOOLCHAIN_PATH}${TARGET_TRIPLET}-size${EXE_EXTENSION})
		message(STATUS "Using default compiler size tool: ${COMPILER_SIZE_TOOL}")
	else()
		message(STATUS "Using compiler size tool: ${COMPILER_SIZE_TOOL}")
	endif()

	if(NOT COMPILER_OBJCOPY_TOOL)
		set(COMPILER_OBJCOPY_TOOL ${TOOLCHAIN_PATH}${TARGET_TRIPLET}-objcopy${EXE_EXTENSION})
		message(STATUS "Using default compiler objcopy tool: ${COMPILER_OBJCOPY_TOOL}")
	else()
		message(STATUS "Using compiler objcopy tool: ${COMPILER_OBJCOPY_TOOL}")
	endif()

	if( ${CMAKE_VERSION} VERSION_LESS 3.6.0)
		INCLUDE(CMakeForceCompiler)
		CMAKE_FORCE_C_COMPILER( ${C_COMPILER} GNU)
		CMAKE_FORCE_CXX_COMPILER( ${CXX_COMPILER} GNU)
	else()
		SET(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY PARENT_SCOPE)
		SET(CMAKE_C_COMPILER ${C_COMPILER} PARENT_SCOPE)
		SET(CMAKE_CXX_COMPILER ${CXX_COMPILER} PARENT_SCOPE)
	endif()

	SET(CMAKE_SIZE ${COMPILER_SIZE_TOOL} PARENT_SCOPE)
	SET(CMAKE_OBJCOPY ${COMPILER_OBJCOPY_TOOL} PARENT_SCOPE)
	SET(CMAKE_ASM_COMPILER ${ASM_COMPILER} PARENT_SCOPE)
ENDFUNCTION()



set(CMAKE_C_FLAGS_DEBUG "")
set(CMAKE_C_FLAGS_RELEASE "")
set(CMAKE_C_FLAGS_MINSIZEREL "")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "")

set(CMAKE_CXX_FLAGS_DEBUG "")
set(CMAKE_CXX_FLAGS_RELEASE "")
set(CMAKE_CXX_FLAGS_MINSIZEREL "")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "")

set(CMAKE_ASM_FLAGS_DEBUG "")
set(CMAKE_ASM_FLAGS_RELEASE  "")
set(CMAKE_ASM_FLAGS_MINSIZEREL   "")
set(CMAKE_ASM_FLAGS_RELWITHDEBINFO "")

set(CMAKE_EXE_LINKE_FLAGS_DEBUG "")
set(CMAKE_EXE_LINKE_FLAGS_RELEASE  "")
set(CMAKE_EXE_LINKE_FLAGS_MINSIZEREL   "")
set(CMAKE_EXE_LINKE_FLAGS_RELWITHDEBINFO "")

EOF2




tmp_makefile="CMakeLists-generator.mk"
\cat << 'EOF' > ${tmp_makefile}
LINKERSCRIPT=$$(cat Makefile | sed -n 's/\s*LINKER_SCRIPT\s*:=\s*\(.*\.ld\)/\1/p')
LINKER_SCRIPT:=$(LINKERSCRIPT)
include Makefile

OPT += -std=c99

TEMPLATE_PATH:="$$$ \{CMAKE_SOURCE_DIR\}/"$(TEMPLATE_PATH)

generate:
	@echo 'cmake_minimum_required(VERSION 3.4.0)'
	@echo ''
	@echo 'include(nrf52.cmake)'

	@echo ''
	@echo ''

	@echo '$(GNU_INSTALL_ROOT2)'
	@echo ''

	@echo 'set(C_COMPILER $(CC))'
	@echo 'set(CXX_COMPILER $(CXX))'
	@echo 'set(ASM_COMPILER $(CC))'
	@echo ''

	$(foreach var, PROJECT_NAME, \
		echo 	"set($(var) $($(var)))" ; \
	)
	@echo ''
	@echo ''

	$(foreach var, CFLAGS CXXFLAGS ASMFLAGS LIB_FILES, \
		echo 	"set($(var)" ; \
		echo " $($(var))" | sed -e 's/\s\+/\n\t/g'; \
		echo	")" ; \
	)
	$(foreach var, LDFLAGS, \
		echo 	"set($(var)" ; \
		echo " $($(var))" | sed -e 's/\s\+/\n\t/g; s/-\(L\|T\)/-\1$$$ {CMAKE_SOURCE_DIR}\//g'; \
		echo	")" ; \
	)

	@echo 'set(SRC_FILES '
	@echo ' $(SRC_FILES)' | sed -e 's/\s\+/\n\t/g'
	@echo ')'
	@echo ''
	@echo ''

	@echo 'set(INC_FOLDERS'
	@echo ' $(INC_FOLDERS)' | sed -e 's/\s\+/\n\t/g'
	@echo ')'
	@echo ''
	@echo ''
	@echo 'project($$$ {PROJECT_NAME})'
	@echo 'enable_language(ASM)'
	@echo ''

	@echo 'NRF_SET_COMPILERS()'
	@echo 'SET_COMPILATION_FLAGS()'


	@echo ''

	@echo 'set(PROJECT_CMAKE_INCLUDE "$$$ {CMAKE_SOURCE_DIR}/project.cmake" CACHE STRING "Project CMake Include")'
	@echo 'if(EXISTS $$$ {PROJECT_CMAKE_INCLUDE} )'
	@echo '    include( $$$ {PROJECT_CMAKE_INCLUDE} )'
	@echo 'endif()'
	@echo ''
	@echo ''

	@echo 'include_directories($$$ {INC_FOLDERS})'
	@echo 'add_executable($$$ {PROJECT_NAME} $$$ {SRC_FILES})'
	@echo 'target_link_libraries($$$ {PROJECT_NAME} PUBLIC $$$ {LIB_FILES_CLEAN})'

	@echo 'message(WARNING "Set SOFTDEVICE variable with the Softdevice hex file")'
	@echo '#set(SOFTDEVICE $$$ {CMAKE_CURRENT_SOURCE_DIR}/s132.hex)'
	@echo 'message(WARNING "Set MERGEHEX_BIN with path to mergehex utility")'
	@echo '#set(MERGEHEX_BIN /opt/nordic/mergehex/mergehex)'

	@echo 'SET_COMPILER_OPTIONS($$$ {PROJECT_NAME})'
	@echo 'PRINT_SIZE_OF_TARGETS($$$ {PROJECT_NAME})'
	@echo 'ADD_HEX_BIN_TARGETS($$$ {PROJECT_NAME})'
	@echo 'NRF_FLASH_TARGET($$$ {PROJECT_NAME})'
EOF



makefile=$1
    \pwd
    dir=`\dirname ${makefile}`
    \echo "Creating CMakeLists.txt for ${makefile}"
    \pushd ${dir} > /dev/null
    \make -s -f ${tmp_makefile} generate > CMakeLists.txt
    \popd > /dev/null
\rm ${tmp_makefile}

echo '************************************'
echo 'Enjoy using CLION with the NRF5-SDK!'
echo '************************************'
