## Usage

1. From the root of your OpenWrt source tree, run:

    ```bash
    curl -sSL https://raw.githubusercontent.com/dotywrt/turboacc-n/main/add_turboacc.sh -o add_turboacc.sh && bash add_turboacc.sh
    ```

    The script automatically detects the kernel version of your source tree and applies the matching patches.

2. Then run:

    ```bash
    make menuconfig
    ```

