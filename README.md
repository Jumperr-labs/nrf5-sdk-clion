# Nordic's nRF5-SDK with CLion
Hey there embedded developers, you deserve a modern IDE!

Running this script from the root directory of your [nRF5-SDK](https://www.nordicsemi.com/eng/Products/Bluetooth-low-energy/nRF5-SDK) will create CMakelists.txt files for all of the example projects in the SDK.

## How to convert all examples on the SDK to CLion
_Tested on Ubuntu 16.04
1. Clone the repository or download the scripts nrf5-sdk-to-clion.sh and nrf5-make2cmake.sh
2. (optional) Add the path where the scripts are located to the PATH enviroment variable PATH
4. (optional) Create a backup for your current nrf5-SDK directory
5. `nrf5-sdk-to-clion.sh <root_to_sdk>` 
6. Open _"CMakeLists.txt"_ for the desired project
7. From CLion, go to File-->Open and choose the root directory of the nRF5-SDK.
The last stage is needed since adding all of the example projects to the CMakeLists.txt file would overload CLion.

## How to convert any Makefile (with nRF5-SDK structure) to CMake
_Tested on Ubuntu 16.04
`nrf5-make2cmake.sh <path_to_Makefile>` this will create a CMakeLists.txt on the same folder of the Makefile



