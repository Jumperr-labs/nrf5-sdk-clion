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

nrf52_stlink="nrf52_stlink.cfg"

\cat << 'EOF3' > ${nrf52_stlink}

source [find interface/stlink-v2-1.cfg]

transport select hla_swd

source [find target/nrf52.cfg]

EOF3


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
	@echo 'include(nrf52.cmake) # get it from https://github.com/nvelozsavino/nordic_cmake.git'
	@echo ''
	@echo ''
	@echo '$(GNU_INSTALL_ROOT2)'
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
	@echo 'project( $$$ {PROJECT_NAME} )'
	@echo 'enable_language(ASM)'
	@echo ''
	@echo 'NRF_SET_COMPILERS()'
	@echo 'SET_COMPILATION_FLAGS()'

	@echo ''
	@echo 'set(PROJECT_CMAKE_INCLUDE "$$$ {CMAKE_SOURCE_DIR}/project.cmake" CACHE STRING "Project CMake Include")'
	@echo 'if(EXISTS $$$ {PROJECT_CMAKE_INCLUDE} )'
	@echo '    include($$$ {PROJECT_CMAKE_INCLUDE})'
	@echo 'endif()'

	@echo ''
	@echo ''

	@echo 'include_directories($$$ {INC_FOLDERS})'
	@echo 'add_executable($$$ {PROJECT_NAME} $$$ {SRC_FILES})'

	@echo 'target_link_libraries($$$ {PROJECT_NAME} PUBLIC $$$ {LIBS_CLEAN} $$$ {LIB_FILES_CLEAN})'
	@echo ''
	@echo ''

	@echo 'message(FATAL_ERROR "Set SOFTDEVICE variables with the Softdevice hex file and info and comment this error")'
	@echo 'set(SOFTDEVICE_HEX_FILE "<PATH TO SOFTDEVICE HEX FILE>")'
	@echo 'set(SOFTDEVICE_FWID_REQ "<FWID_REQ>")'
	@echo 'set(SOFTDEVICE_FWID_ID "<FWID_ID>")'
	@echo ''
	@echo ''

	@echo 'set(FW_VERSION "v0.0.1")      #Firmware Version'
	@echo 'set(OUTPUT_FOLDER "$$$ {CMAKE_SOURCE_DIR}/build/$$$ {FW_VERSION}/")'
	@echo 'set(OBJ_NAME "$$$ {OUTPUT_FOLDER}/$$$ {PROJECT_NAME}")'
	@echo ''
	@echo ''

	@echo 'set(APP_HEX_FILE $$$ {TARGET_HEX_FILE})'
	@echo 'set(APP_HEX_FILE-CREATE TRUE)'
	@echo 'set(BOOTLOADER_VERSION 1)'

	@echo 'SET_COMPILER_OPTIONS($$$ {PROJECT_NAME})'
	@echo 'PRINT_SIZE_OF_TARGETS($$$ {PROJECT_NAME})'
	@echo 'ADD_HEX_BIN_TARGETS($$$ {PROJECT_NAME} $$$ {OBJ_NAME})'
	@echo 'NRF_FLASH_TARGET($$$ {PROJECT_NAME} $$$ {TARGET_HEX_FILE})'
	@echo ''

	@echo 'if (NOT BOOTLOADER_HEX_FILE)'
	@echo '    message(WARNING "Add -DBOOTLOADER_HEX_FILE=<path_to_bootloader_hex_file> to CMake env variables")'
	@echo 'endif()'

	@echo 'if (NOT KEY_PEM_FILE)'
	@echo '    message(WARNING "Add -DKEY_PEM_FILE=<path_to_pem_key_file> to CMake env variables")'
	@echo 'endif()'
	@echo 'GENERATE_UPDATE_FLASH_TARGET($$$ {PROJECT_NAME} "APP" $$$ {OBJ_NAME}.zip)'
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
