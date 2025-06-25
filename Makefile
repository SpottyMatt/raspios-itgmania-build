DISTRO=$(shell dpkg --status tzdata|grep Provides|cut -f2 -d'-')
RPI_MODEL=$(shell if [ -x ./venv/bin/rpi-hw-info ]; then ./venv/bin/rpi-hw-info 2>/dev/null | awk -F ':' '{print $$1}'; fi)
BASE_INSTALL_DIR=/usr/local

ifeq ($(RPI_MODEL),4B)
PARALLELISM=-j3
else
PARALLELISM=-j1
endif

.PHONY: all

ifeq ($(wildcard ./venv/bin/rpi-hw-info),)
all: rpi-hw-info-setup
	$(MAKE) all

rpi-hw-info-setup:
	python3 -m venv venv
	./venv/bin/pip install --upgrade pip
	./venv/bin/pip install "rpi-hw-info~=2.0"
	@ if ! [ -e ./venv/bin/rpi-hw-info ]; then echo "Failed to install rpi-hw-info. Check Python and pip setup."; exit 1; fi

%: rpi-hw-info-setup
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
itgmania-prep: ARM_CPU=$(shell ./venv/bin/rpi-hw-info | awk -F ':' '{print $$3}')
itgmania-prep: ARM_FPU=$(shell ./venv/bin/rpi-hw-info | awk -F ':' '{print $$4}')
itgmania-prep:
	git submodule init
	git submodule update
	cd itgmania
	git submodule update --init --recursive
	
	# Create install directory
	sudo mkdir -p "$(BASE_INSTALL_DIR)/itgmania"
	sudo chmod a+rw "$(BASE_INSTALL_DIR)/itgmania"
	
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

.PHONY: clean-rpi-hw-info
clean-rpi-hw-info:
	rm -rf venv

endif
