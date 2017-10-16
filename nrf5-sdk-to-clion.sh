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

tmp_makefile="/tmp/CMakeLists-generator.mk"




\cat << 'EOF' > ${tmp_makefile}
LINKERSCRIPT:=`cat Makefile | sed -n 's/.*LINKER_SCRIPT\s\+:=\s\+\(.*\.ld\).*/\1/p'`
LINKER_SCRIPT:="$$$ \{CMAKE_SOURCE_DIR\}/"$(LINKERSCRIPT)
include Makefile
OPT += -std=c99
TEMPLATE_PATH:="$$$ \{CMAKE_SOURCE_DIR\}/"$(TEMPLATE_PATH)


generate:
	@echo 'cmake_minimum_required(VERSION 3.4.0)'

	@echo 'FUNCTION(SET_COMPILER_OPTIONS TARGET)' 
	@echo '	target_compile_options($$$ {TARGET} PRIVATE'
	@echo '		$$$ <$$$ <COMPILE_LANGUAGE:C>:$$$ {CFLAGS}>'
	@echo '			$$$ <$$$ <COMPILE_LANGUAGE:CXX>:$$$ {CXXFLAGS}>'
	@echo '			$$$ <$$$ <COMPILE_LANGUAGE:ASM>:$$$ {ASMFLAGS}>'
	@echo '		)'
	@echo 'ENDFUNCTION()'

	@echo ''
	@echo ''

	@echo 'FUNCTION(PRINT_SIZE_OF_TARGETS TARGET)'
	@echo '    SET(FILENAME "$$$ {CMAKE_BINARY_DIR}/$$$ {TARGET}")'
	@echo '    add_custom_command(TARGET $$$ {TARGET} POST_BUILD COMMAND $$$ {CMAKE_SIZE} $$$ {FILENAME})'
	@echo 'ENDFUNCTION()'

	@echo ''
	@echo ''

 
	@echo 'SET(CMAKE_SYSTEM_NAME Generic)'
	@echo 'SET(CMAKE_SYSTEM_PROCESSOR arm)'
	@echo 'INCLUDE(CMakeForceCompiler)'

	@echo ''
	@echo ''

	@echo 'SET(TOOLCHAIN_PREFIX "/usr")'
	@echo 'SET(TARGET_TRIPLET "arm-none-eabi")'
	@echo 'SET(TOOLCHAIN_BIN_DIR $$$ {TOOLCHAIN_PREFIX}/bin)'
	@echo 'SET(TOOLCHAIN_INC_DIR $$$ {TOOLCHAIN_PREFIX}/$$$ {TARGET_TRIPLET}/include)'
	@echo 'SET(TOOLCHAIN_LIB_DIR $$$ {TOOLCHAIN_PREFIX}/$$$ {TARGET_TRIPLET}/lib)'
	@echo 'SET(CMAKE_SIZE $$$ {TOOLCHAIN_BIN_DIR}/$$$ {TARGET_TRIPLET}-size$$$ {TOOL_EXECUTABLE_SUFFIX} CACHE INTERNAL "size tool")'

	@echo ''
	@echo ''
	@echo ''
	@echo ''


	$(foreach var, PROJECT_NAME SDK_ROOT PROJ_DIR SRC_FILES INC_FOLDERS CFLAGS CXXFLAGS ASMFLAGS LDFLAGS LIB_FILES, \
		echo "set($(var) $($(var)))" ; \
	)
	@echo ''
	@echo ''

	

	@echo 'string(REPLACE ";" " " LDFLAGS "$$$ {LDFLAGS}")'

	@echo ''
	@echo ''

	@echo 'set(CMAKE_C_FLAGS "" CACHE INTERNAL "c compiler flags")'
	@echo 'set(CMAKE_CXX_FLAGS "" CACHE INTERNAL "c++ compiler flags")'
	@echo 'set(CMAKE_ASM_FLAGS "" CACHE INTERNAL "asm compiler flags")'
	@echo 'set(CMAKE_EXE_LINKER_FLAGS $$$ {LDFLAGS} CACHE INTERNAL "executable linker flags")'

	@echo ''
	@echo ''

	@echo 'CMAKE_FORCE_C_COMPILER($$$ {TOOLCHAIN_BIN_DIR}/$$$ {TARGET_TRIPLET}-gcc$$$ {TOOL_EXECUTABLE_SUFFIX} GNU)'
	@echo 'CMAKE_FORCE_CXX_COMPILER($$$ {TOOLCHAIN_BIN_DIR}/$$$ {TARGET_TRIPLET}-g++$$$ {TOOL_EXECUTABLE_SUFFIX} GNU)'
	@echo 'SET(CMAKE_ASM_COMPILER $$$ {TOOLCHAIN_BIN_DIR}/$$$ {TARGET_TRIPLET}-gcc$$$ {TOOL_EXECUTABLE_SUFFIX})'

	@echo ''
	@echo ''

	@echo ''
	@echo ''



	@echo 'project($$$ {PROJECT_NAME})'
	@echo 'enable_language(ASM)'

	@echo ''
	@echo ''

	@echo 'set(LIBS $$$ {LIB_FILES})'

	@echo 'include_directories($$$ {INC_FOLDERS})'
	@echo 'add_executable($$$ {PROJECT_NAME} $$$ {SRC_FILES})'
	@echo 'target_link_libraries($$$ {PROJECT_NAME} PUBLIC $$$ {LIBS})'

	@echo ''
	@echo ''


	@echo 'SET_COMPILER_OPTIONS($$$ {PROJECT_NAME})'
	@echo 'PRINT_SIZE_OF_TARGETS($$$ {PROJECT_NAME})'
EOF

\echo "cmake_minimum_required(VERSION 2.8.9)" > CMakeLists.txt

for makefile in `\find ./examples -name Makefile` ; do
    dir=`\dirname ${makefile}`
    \echo "Creating CMakeLists.txt for ${makefile}"
    \pushd ${dir} > /dev/null
    \make -s -f ${tmp_makefile} generate > CMakeLists.txt
    \popd > /dev/null
    \echo "#add_subdirectory(${dir})" >> CMakeLists.txt
done
\rm ${tmp_makefile}

echo '************************************'
echo 'Enjoy using CLION with the NRF5-SDK!'
echo '************************************'
