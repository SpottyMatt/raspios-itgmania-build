Compile ITGmania on Raspberry Pi
=========================

![ITGmania Raspberry Pi Build](itgmania-build.png)

Scripts & instructions to build [ITGmania](https://github.com/itgmania/itgmania) from source on a Raspberry Pi running Raspberry Pi OS.

There is a may be more required to make ITGmania actually _playable_ on a Raspberry Pi (especially on the model 3B) beyond just building it.
If all you want to do is play ITGmania, you may want to look for additional setup guides for controllers, audio, and display optimization.

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Notes](#notes)

Prerequisites
=========================

**You** must provide the following:

1. A supported [Raspberry Pi model](https://www.raspberrypi.org/products/)
   1. 4B (tested and working)
   2. Other models may work but are untested
2. An installed & working [Raspberry Pi OS](https://www.raspberrypi.org/downloads/) operating system, Bookworm (Debian 12) or later.

Quick Start
=========================

1. Clone this repository
   ```bash
   git clone https://github.com/your-username/raspios-itgmania-build.git
   cd raspios-itgmania-build
   ```

2. Run `make`
   ```bash
   make
   ```

3. Wait a while
   - ~30 minutes for RPi 4B (may vary based on system load)

4. Install manually (if the automated install fails due to permissions):
   ```bash
   sudo make itgmania-install
   ```

5. Look in `/usr/local/itgmania/` for the installed game

6. Done!

**Note:** You've just _built_ the ITGmania binary but there's a lot more required to play it well on a Raspberry Pi.
For optimal performance, you'll need to configure controllers, audio settings, and potentially display settings.

Notes
=========================

Building for Other Raspberry Pi Models
-------------------------

The build system uses hardware detection to automatically configure ARM compilation flags via the [rpi-hw-info](https://github.com/SpottyMatt/rpi-hw-info) submodule.

For Raspberry Pi 4B, this has been tested and works. Other models should theoretically work but have not been tested.

If you encounter issues with automatic hardware detection, you can override the model:

```bash
make RPI_MODEL=4B
```

See this excellent gist: [GCC compiler optimization for ARM-based systems](https://gist.github.com/fm4dd/c663217935dc17f0fc73c9c81b0aa845) for more information on compiling with GCC on Raspberry Pi - but you shouldn't need it; itgmania is largely arm-compatible!

Supporting Additional Raspberry Pi Models
-------------------------

This repository uses the [SpottyMatt/rpi-hw-info](https://github.com/SpottyMatt/rpi-hw-info) repository to decode Raspberry Pi hardware information and figure out the correct compiler flags.

If you manage to get this to compile on a new Raspberry Pi model, make sure that repository is capable of correctly detecting the new Pi, and reports the correct CPU and FPU compile targets.

Then, update the `rpi-hw-info` submodule in this repo and you're done! This repo now supports compiling for the new Raspberry Pi hardware.

ITGmania Source
-------------------------

This uses the [ITGmania](https://github.com/itgmania/itgmania) repository as a git submodule.

The build is currently configured for a release build with minimal dependencies to ensure compatibility on Raspberry Pi hardware.

If you want to try building from a more recent commit, [update the `itgmania` submodule](https://stackoverflow.com/questions/5828324/update-git-submodule-to-latest-commit-on-origin/5828396#5828396) before building:

```bash
cd itgmania
git pull origin main  # or whatever branch you want
cd ..
git add itgmania
git commit -m "Update ITGmania submodule to latest"
```

Build Configuration
-------------------------

The current build is configured in the `Makefile` with two main targets:

- `itgmania-build` - Builds the ITGmania binary
- `itgmania-install` - Installs the ITGmania binary to `/usr/local/itgmania/`

### Configuration Variables

- `BASE_INSTALL_DIR` - Controls the base installation directory (default: `/usr/local`)
  - ITGmania will be installed to `$(BASE_INSTALL_DIR)/itgmania/`
  - Can be overridden: `make BASE_INSTALL_DIR=/opt`

Dependencies
-------------------------

The build system automatically installs required dependencies from [itgmania-build/deps/<distro>.list`](./itgmania-build/deps/).

Troubleshooting
-------------------------

**Build fails with permission errors during install:**
Run the install step manually with sudo:

```bash
sudo make itgmania-install
```

**Hardware detection fails:**
Override with a known working model:

```bash
make RPI_MODEL=4B
```

**Missing dependencies:**
Ensure your system is up to date:

```bash
sudo apt update && sudo apt upgrade
```

**Out of memory during build:**
The build uses parallel compilation (`-j3`, etc.) based on the detected RPi model. For systems with less memory, you can reduce parallelism by editing the Makefile or using:

```bash
make PARALLELISM=-j1
``` 
