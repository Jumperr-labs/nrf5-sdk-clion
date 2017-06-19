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
include Makefile

generate:
	$(foreach var, PROJECT_NAME SDK_ROOT PROJ_DIR SRC_FILES INC_FOLDERS CFLAGS CXXFLAGS, \
		echo "set($(var) $($(var)))" ; \
		echo ; \
	)

	@echo 'cmake_minimum_required(VERSION 2.4.0)'
	@echo 'project($$$ {PROJECT_NAME})'

	@echo 'list(APPEND CFLAGS "-undef" "-D__GNUC__")'
	@echo 'list(FILTER CFLAGS EXCLUDE REGEX mcpu)'
	@echo 'string(REPLACE ";" " " CFLAGS "$$$ {CFLAGS}")'
	@echo 'set(CMAKE_C_FLAGS $$$ {CFLAGS})'

	@echo 'include_directories($$$ {INC_FOLDERS})'
	@echo 'add_executable($$$ {PROJECT_NAME} $$$ {SRC_FILES})'
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
