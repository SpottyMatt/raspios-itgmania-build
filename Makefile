DISTRO=$(shell dpkg --status tzdata|grep Provides|cut -f2 -d'-')
RPI_MODEL=$(shell ./rpi-hw-info/rpi-hw-info.py 2>/dev/null | awk -F ':' '{print $$1}')

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
	sudo mkdir -p /usr/local/itgmania-5.1
	sudo chmod a+rw /usr/local/itgmania-5.1

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
	cmake -G "Unix Makefiles" \
		-DCMAKE_BUILD_TYPE=Release
	cmake $(PARALLELISM) .

.PHONY: itgmania-build
itgmania-build:
	cd itgmania && cmake -B build -DCMAKE_BUILD_TYPE=Release -DWITH_MINIMAID=OFF
	cd itgmania && make -C build $(PARALLELISM)

.PHONY: itgmania-install
itgmania-install:
	$(MAKE) --dir itgmania install

# Test target for build script development
.PHONY: test-build
test-build:
	@echo "=== ITGMania Build Test ==="
	@echo "Hostname: $$(hostname)"
	@echo "Date: $$(date)"
	@echo "PWD: $$(pwd)"
	@echo "Distro: $(DISTRO)"
	@echo "RPI Model: $(RPI_MODEL)"
	@echo "Parallelism: $(PARALLELISM)"
	@echo "Git Status:"
	@git status --short || echo "Not a git repository"
	@echo "Git Log (last 3):"
	@git log --oneline -3 || echo "No git history"
	@echo "Directory Contents:"
	@ls -la
	@echo "=== Test Complete ==="
	@sleep 2  # Give time to see output

endif
