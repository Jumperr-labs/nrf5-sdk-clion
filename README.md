# Nordic's nRF5-SDK with CLion
Hey there embedded developers, you deserve a modern IDE!

Running this script from the root directory of your [nRF5-SDK](https://www.nordicsemi.com/eng/Products/Bluetooth-low-energy/nRF5-SDK) will create CMakelists.txt files for all of the example projects in the SDK.

_Disclaimer: This will not let you build or flash your project from CLion but you will be able to navigate through your project and the SDK libraries._

## How to use it
_Tested on Ubuntu 16.04 and macOS_
1. (optional) Create a backup for your current nrf5-SDK directory
2. cd into the root of the nrf5-SDK directory
3. `curl -s https://raw.githubusercontent.com/Jumperr-labs/nrf5-sdk-clion/master/nrf5-sdk-to-clion.sh | bash`
4. Open _"./CMakeLists.txt"_ and uncomment your projects' path (you can uncomment multiple projects)

The last stage is needed since adding all of the example projects to the CMakeLists.txt file would overload CLion.
