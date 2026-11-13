# Setup Guide

Exact steps used to set up the toolchain. Commands marked **Ubuntu** run in the WSL Ubuntu window (`user@host:~$` prompt). Commands marked **cmd** or **PowerShell** run on Windows.

## 1. WSL2 + Ubuntu (PowerShell as Administrator)

```
wsl --install -d Ubuntu-22.04
```

Cap WSL memory so Windows stays usable on a 16 GB laptop. Create `%USERPROFILE%\.wslconfig`:

```
[wsl2]
memory=10GB
processors=4
```

Then run `wsl --shutdown` and reopen Ubuntu. Keep project files under the Linux home folder, not `/mnt/c`.

## 2. Base tools (Ubuntu)

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git build-essential autoconf automake cmake ninja-build \
  python3 python3-pip python3-venv gtkwave iverilog device-tree-compiler \
  libboost-all-dev flex bison ccache help2man perl curl wget unzip \
  libfl2 libfl-dev zlib1g-dev libelf-dev srecord tree
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
```

`iverilog -V | head -1` prints two harmless "Unable to get version" lines on Ubuntu; ignore them.

## 3. VS Code with WSL

Install VS Code (not Visual Studio) on Windows, add the **WSL** extension, then in Ubuntu run `code .` from a project folder.

## 4. GitHub over SSH (Ubuntu)

```bash
ssh-keygen -t ed25519 -C "you@example.com"
cat ~/.ssh/id_ed25519.pub     # add this key at GitHub > Settings > SSH and GPG keys
ssh -T git@github.com
```

## 5. Verilator v4.210 (Ubuntu)

Ibex pins this version (see `ci/vars.env` in the Ibex repo).

```bash
mkdir -p ~/tools && cd ~/tools
git clone https://github.com/verilator/verilator verilator-src
cd verilator-src
git checkout v4.210
autoconf
./configure --prefix=$HOME/tools/verilator-4.210
make -j4
make install
echo 'export PATH=$HOME/tools/verilator-4.210/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
verilator --version
```

Do **not** set `VERILATOR_ROOT`; it breaks this install layout.

## 6. RISC-V toolchain (Ubuntu)

lowRISC prebuilt toolchain, the same one Ibex CI uses (`RISCV_TOOLCHAIN_TAR_VERSION` and `..._VARIANT` in `ci/vars.env`):

```bash
mkdir -p ~/tools/riscv ~/work/dl && cd ~/work/dl
wget https://github.com/lowRISC/lowrisc-toolchains/releases/download/20220210-1/lowrisc-toolchain-gcc-rv32imcb-20220210-1.tar.xz
tar -C ~/tools/riscv -xf lowrisc-toolchain-gcc-rv32imcb-20220210-1.tar.xz --strip-components=1
echo 'export PATH=$HOME/tools/riscv/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
riscv32-unknown-elf-gcc --version
```

## 7. Ibex simple system (Ubuntu)

```bash
mkdir -p ~/work && cd ~/work
git clone https://github.com/lowRISC/ibex
cd ibex
python3 -m venv ~/venv
source ~/venv/bin/activate        # needed in every new window before fusesoc
pip install -U pip
pip install -r python-requirements.txt

fusesoc --cores-root=. run --target=sim --setup --build \
  lowrisc:ibex:ibex_simple_system \
  --RV32E=0 --RV32M=ibex_pkg::RV32MFast

make -C examples/sw/simple_system/hello_test

./build/lowrisc_ibex_ibex_simple_system_0/sim-verilator/Vibex_simple_system -t \
  --meminit=ram,./examples/sw/simple_system/hello_test/hello_test.elf
cat ibex_simple_system.log
```

Expected: the log contains the hello message. Notes:

- `libelf.h: No such file` during the build means `libelf-dev` is missing (included in step 2).
- `make -C` builds the C program into an `.elf` with the RISC-V toolchain; FuseSoC builds the simulator from the RTL. They are separate steps.

## 8. Spike, the RISC-V reference model (Ubuntu)

```bash
cd ~/work
git clone --recursive https://github.com/riscv-software-src/riscv-isa-sim
cd riscv-isa-sim
mkdir build && cd build
../configure --prefix=$HOME/tools/spike
make -j4
make install
echo 'export PATH=$HOME/tools/spike/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
spike --help | head -5
```

Build takes about 10 minutes. Stop at any line containing `error`.

Note: Ibex's co-simulation expects a lowRISC-patched Spike (version pinned as `SPIKE_IBEX_VERSION` in `ci/vars.env`), as far as I know. Upstream Spike is fine for learning; switch to the pinned one when the co-simulation flow is set up.

## 9. Vivado (Windows)

- Download the **AMD Unified Installer 2026.1, Windows Self Extracting Web Installer** (about 286 MB EXE). Not the 96 GB SFD image, not Linux.
- Install **2026.1**, **not 2026.1.1**: the free Basic license does not cover the 2026.1.1 minor release and Vivado refuses to launch.
- Choose Vivado, then only the 7 Series / Artix-7 device family; untick Model Composer, DocNav and cable drivers. Disk use is about 50 GB.
- License Manager: choose "Get My Full or Purchased Certificate-Based License", then on the licensing site tick **Vivado Basic Tier License, Node Locked License**.
- When adding the host, use OS **Windows 64-bit**, Host ID Type **Ethernet MAC**, and the MAC of your real Wi-Fi/Ethernet adapter (`getmac /v /fo list`), 12 characters without separators. Do not use the C: drive serial or a virtual adapter.
- Load the emailed `.lic` in License Manager. If `XILINXD_LICENSE_FILE` is set to an old path, clear or fix it.
- The Basic license is annual: renew it before it expires.

## 10. UVM check and the xsim script (Windows cmd)

```
C:\Xilinx\2026.1\Vivado\settings64.bat
xvlog -sv -L uvm hello_uvm.sv
xelab -debug typical -L uvm top -s hello_snap
xsim hello_snap -runall
```

`run_xsim.bat file.sv [top] [testname] [seed]` runs all three stages, writes `compile.log`, `elab.log` and `sim.log` into `runs\<name>_s<seed>\`, and appends PASS/FAIL to `runs\summary.log`.

## 11. Git on Windows

```
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
cd C:\work\soc-verification-portfolio
git add .
git commit -m "describe the change"
git push
```

Keep generated output out of the repo with a `.gitignore` (`runs/`, `xsim.dir/`, `*.log`, `*.jou`, `*.pb`, `*.wdb`, `build/`).
