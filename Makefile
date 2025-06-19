DISTRO=$(shell dpkg --status tzdata|grep Provides|cut -f2 -d'-')
RPI_MODEL=$(shell ./rpi-hw-info/rpi-hw-info.py 2>/dev/null | awk -F ':' '{print $$1}')
BASE_INSTALL_DIR=/usr/local

ifeq ($(RPI_MODEL),4B)
PARALLELISM=-j3
else
PARALLELISM=-j1
endif

.PHONY: all

ifeq ($(wildcard ./rpi-hw-info/rpi-hw-info.py),)
all: submodules
	$(MAKE) all

submodules:
	git submodule init rpi-hw-info
	git submodule update rpi-hw-info
	@ if ! [ -e ./rpi-hw-info/rpi-hw-info.py ]; then echo "Couldn't retrieve the RPi HW Info Detector's git submodule. Figure out why or run 'make RPI_MODEL=<your_model>'"; exit 1; fi

%: submodules
	$(MAKE) $@

else

all:
	$(MAKE) system-prep
	$(MAKE) itgmania-prep
	$(MAKE) itgmania-build
	$(MAKE) itgmania-install

.PHONY: build-only
build-only:
	$(MAKE) build-prep
	$(MAKE) itgmania-prep
	$(MAKE) itgmania-build

.PHONY: system-prep
system-prep:
	$(MAKE) build-prep

.PHONY: build-prep
build-prep: ./itgmania-build/deps/$(DISTRO).list
	sudo sed -i 's/#deb-src/deb-src/g' /etc/apt/sources.list
	sudo apt-get update
	sudo apt-get install -y \
		$$(echo $$(cat ./itgmania-build/deps/$(DISTRO).list))
	sudo apt-get autoremove -y

./itgmania-build/deps/*.list:
	[ -e $(@) ]

.PHONY: itgmania-prep
.ONESHELL:
itgmania-prep: ARM_CPU=$(shell ./rpi-hw-info/rpi-hw-info.py | awk -F ':' '{print $$3}')
itgmania-prep: ARM_FPU=$(shell ./rpi-hw-info/rpi-hw-info.py | awk -F ':' '{print $$4}')
itgmania-prep:
	git submodule init
	git submodule update
	cd itgmania
	git submodule update --init --recursive
	
	# Create install directory
	sudo mkdir -p "$(BASE_INSTALL_DIR)"
	sudo chmod a+rw "$(BASE_INSTALL_DIR)"
	
	# Configure CMake with the correct install prefix
	cmake -G "Unix Makefiles" \
		-DCMAKE_BUILD_TYPE=Release \
		-DWITH_MINIMAID=OFF \
		-DCMAKE_INSTALL_PREFIX="$(BASE_INSTALL_DIR)"
	cmake .

.PHONY: itgmania-build
itgmania-build:
	$(MAKE) --dir itgmania $(PARALLELISM)

.PHONY: itgmania-install
itgmania-install:
	$(MAKE) --dir itgmania $(PARALLELISM) install

endif
