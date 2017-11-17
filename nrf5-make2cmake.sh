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

tmp_makefile=$(mktemp)

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

	@echo 'FUNCTION(ADD_HEX_BIN_TARGETS TARGET)'
	@echo '    SET(FILENAME "$$$ {CMAKE_BINARY_DIR}/$$$ {TARGET}")'
	@echo '    add_custom_command(TARGET $$$ {TARGET} POST_BUILD COMMAND $$$ {CMAKE_OBJCOPY} -Oihex $$$ {FILENAME} $$$ {FILENAME}.hex)'
	@echo '    add_custom_command(TARGET $$$ {TARGET} POST_BUILD COMMAND $$$ {CMAKE_OBJCOPY} -Obinary $$$ {FILENAME} $$$ {FILENAME}.bin)'
	@echo 'ENDFUNCTION()'

	@echo ''
	@echo ''

 
	@echo 'SET(CMAKE_SYSTEM_NAME Generic)'
	@echo 'SET(CMAKE_SYSTEM_PROCESSOR arm)'
	@echo 'INCLUDE(CMakeForceCompiler)'

	@echo '$(GNU_INSTALL_ROOT2)'
	@echo ''

	@echo ''
	@echo ''
	@echo ''
	@echo ''


	$(foreach var, PROJECT_NAME SDK_ROOT PROJ_DIR OUTPUT_DIRECTORY LDFLAGS, \
		echo 	"set($(var) $($(var)))" ; \
	)
	@echo ''
	@echo ''

	$(foreach var, CFLAGS CXXFLAGS ASMFLAGS LIB_FILES , \
		echo 	"set($(var)" ; \
		echo " $($(var))" | sed -e 's/\s\+/\n\t/g'; \
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



	@echo 'foreach(LIB $$$ {LIB_FILES})'
	@echo 'find_file(LIB_FILE_$$$ {LIB} $$$ {LIB} $$$ {CMAKE_SOURCE_DIR})'
	@echo '	if (NOT LIB_FILE_$$$ {LIB})'
	@echo '		list(APPEND LIBS $$$ {LIB})'
	@echo '	else ()'
	@echo '		list(APPEND LIB_FILES_CLEAN $$$ {LIB_FILE_$$$ {LIB}})'
	@echo '	endif()'
	@echo 'endforeach()'

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

	@echo 'set(CMAKE_C_COMPILER $(CC))'
	@echo 'set(CMAKE_CXX_COMPILER $(CXX))'
	@echo 'set(CMAKE_ASM_COMPILER $(AS))'
	@echo 'set(CMAKE_SIZE $(SIZE))'
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
	@echo 'target_link_libraries($$$ {PROJECT_NAME} PUBLIC $$$ {LIB_FILES_CLEAN})'

	@echo ''
	@echo ''


	@echo 'SET_COMPILER_OPTIONS($$$ {PROJECT_NAME})'
	@echo 'PRINT_SIZE_OF_TARGETS($$$ {PROJECT_NAME})'
	@echo 'ADD_HEX_BIN_TARGETS($$$ {PROJECT_NAME})'
EOF



makefile=$1
dir=`\dirname ${makefile}`
\echo "Creating CMakeLists.txt for ${makefile}"
\pushd ${dir} > /dev/null
\make -s -f ${tmp_makefile} generate > CMakeLists.txt
\popd > /dev/null
\rm ${tmp_makefile}

echo '************************************'
echo 'Enjoy using CLION with the NRF5-SDK!'
echo '************************************'
