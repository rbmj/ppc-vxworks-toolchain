#!/usr/bin/env make -f

#final targets:
all: \
	stmp-install-binutils \
	stmp-install-gcc-host \
	stmp-install-gcc-target \
	stmp-install-wpilib \
	stmp-install-buildscripts \
	stmp-install-tools \
	stmp-extract-cmake \
	stmp-gccdist-all

PREFIX=/mingw
TARGET=powerpc-wrs-vxworks
WINDIR=$(CURDIR)/win32
INSTALLDIR=$(WINDIR)/install-prefix

GCC_DOWNLOAD_URL=http://ftp.gnu.org/gnu/gcc/gcc-4.8.0/gcc-4.8.0.tar.gz
GCC_EXTRACTNAME=gcc-4.8.0

BINUTILS_DOWNLOAD_URL=http://ftp.gnu.org/gnu/binutils/binutils-2.23.1.tar.gz
BINUTILS_EXTRACTNAME=binutils-2.23.1

WPILIB_DOWNLOAD_URL=https://github.com/rbmj/wpilib/archive/master.zip
WPILIB_EXTRACTNAME=wpilib-master

BUILDSCRIPTS_DOWNLOAD_URL=https://github.com/rbmj/frc-buildscripts/archive/master.zip
BUILDSCRIPTS_EXTRACTNAME=frc-buildscripts-master

BINUTILS_ORIG_ARCHIVE=$(WINDIR)/$(TARGET)-$(BINUTILS_EXTRACTNAME).tar.gz
BINUTILS_SRCDIR=$(WINDIR)/$(BINUTILS_EXTRACTNAME)
BINUTILS_BUILDDIR=$(WINDIR)/build-$(BINUTILS_EXTRACTNAME)

GCC_ORIG_ARCHIVE=$(WINDIR)/$(TARGET)-$(GCC_EXTRACTNAME).tar.gz
GCC_LINUXDIR=$(WINDIR)/linux-build-$(GCC_EXTRACTNAME)
GCC_SRCDIR=$(WINDIR)/$(GCC_EXTRACTNAME)
GCC_BUILDDIR=$(WINDIR)/build-$(GCC_EXTRACTNAME)

INSTALL_BASE_DIR=$(INSTALLDIR)$(PREFIX)
GCCDIST_DOWNLOAD_URL=ftp://ftp.ni.com/pub/devzone/tut/updated_vxworks63gccdist.zip
GCCDIST_ORIG_ARCHIVE=$(WINDIR)/gccdist.zip

WPILIB_ORIG_ARCHIVE=$(WINDIR)/$(WPILIB_EXTRACTNAME).zip
WPILIB_SRCDIR=$(WINDIR)/$(WPILIB_EXTRACTNAME)
WPILIB_BUILDDIR=$(WINDIR)/build-$(WPILIB_EXTRACTNAME)

BUILDSCRIPTS_ORIG_ARCHIVE=$(WINDIR)/$(BUILDSCRIPTS_EXTRACTNAME).zip
BUILDSCRIPTS_SRCDIR=$(WINDIR)/$(BUILDSCRIPTS_EXTRACTNAME)
BUILDSCRIPTS_BUILDDIR=$(WINDIR)/build-$(BUILDSCRIPTS_EXTRACTNAME)

TOOL_DIR=$(INSTALL_BASE_DIR)/powerpc-wrs-vxworks
WIND_BASE=$(TOOL_DIR)/wind_base
LDSCRIPT_DIR=$(TOOL_DIR)/share/ldscripts

stmp-download-binutils:
	wget -O $(BINUTILS_ORIG_ARCHIVE) $(BINUTILS_DOWNLOAD_URL)
	touch stmp-download-binutils

stmp-extract-binutils: stmp-download-binutils
	cd $(WINDIR) ; tar -xf $(BINUTILS_ORIG_ARCHIVE)
	touch stmp-extract-binutils

stmp-download-gcc:
	wget -O $(GCC_ORIG_ARCHIVE) $(GCC_DOWNLOAD_URL)
	touch stmp-download-gcc

stmp-prelim-extract-gcc: stmp-download-gcc
	cd $(WINDIR) ; tar -xf $(GCC_ORIG_ARCHIVE)
	touch stmp-prelim-extract-gcc

stmp-extract-gcc: stmp-prelim-extract-gcc
	cd $(GCC_SRCDIR) ; ./contrib/download_prerequisites
	touch stmp-extract-gcc

stmp-download-wpilib:
	wget -O $(WPILIB_ORIG_ARCHIVE) $(WPILIB_DOWNLOAD_URL)
	touch stmp-download-wpilib

stmp-extract-wpilib: stmp-download-wpilib
	cd $(WINDIR) ; unzip -qo $(WPILIB_ORIG_ARCHIVE)
	touch stmp-extract-wpilib

stmp-download-gccdist:
	wget -O $(GCCDIST_ORIG_ARCHIVE) $(GCCDIST_DOWNLOAD_URL)
	touch stmp-download-gccdist

stmp-extract-gccdist: stmp-download-gccdist
	cd $(WINDIR) ; unzip -qo $(GCCDIST_ORIG_ARCHIVE)
	touch stmp-extract-gccdist

$(BINUTILS_BUILDDIR)/Makefile: stmp-extract-binutils
	mkdir -p $(BINUTILS_BUILDDIR)
	cd $(BINUTILS_BUILDDIR) ; $(BINUTILS_SRCDIR)/configure \
		--prefix=$(PREFIX) \
		--build=$(shell $(BINUTILS_SRCDIR)/config.guess) \
		--target=$(TARGET) \
		--host=i686-w64-mingw32

stmp-build-binutils: $(BINUTILS_BUILDDIR)/Makefile
	cd $(BINUTILS_BUILDDIR) ; make -j4
	touch stmp-build-binutils

stmp-install-binutils: stmp-build-binutils
	cd $(BINUTILS_BUILDDIR) ; make install DESTDIR=$(INSTALLDIR)
	touch stmp-install-binutils

$(GCC_BUILDDIR)/Makefile: stmp-extract-gcc
	mkdir -p $(GCC_BUILDDIR)
	cd $(GCC_BUILDDIR) ; $(GCC_SRCDIR)/configure \
		--prefix=$(PREFIX) \
		--build=$(shell $(GCC_SRCDIR)/config.guess) \
		--target=$(TARGET) \
		--host=i686-w64-mingw32 \
		--with-gnu-as \
		--with-gnu-ld \
		--with-headers \
		--disable-libssp \
		--disable-multilib \
		--with-float=hard \
		--enable-languages=c,c++ \
		--enable-threads=vxworks \
		--enable-libstdcxx \
		--without-gconv \
		--disable-libgomp \
		--disable-libmudflap \
		--with-cpu-PPC603 \
		--disable-symvers

stmp-build-gcc-host: $(GCC_BUILDDIR)/Makefile
	cd $(GCC_BUILDDIR) ; make all-host -j4
	touch stmp-build-gcc-host

stmp-install-gcc-host: stmp-build-gcc-host
	cd $(GCC_BUILDDIR) ; make install-host DESTDIR=$(INSTALLDIR)
	touch stmp-install-gcc-host

#GCC has trouble building target libraries in a canadian cross configuration
#so brute-force solution is just build two compilers...

$(GCC_LINUXDIR)/Makefile: stmp-extract-gcc
	mkdir -p $(GCC_LINUXDIR)
	cd $(GCC_LINUXDIR) ; $(GCC_SRCDIR)/configure \
		--prefix=$(PREFIX) \
		--target=$(TARGET) \
		--with-gnu-as \
		--with-gnu-ld \
		--with-headers \
		--disable-libssp \
		--disable-multilib \
		--with-float=hard \
		--enable-languages=c,c++ \
		--enable-threads=vxworks \
		--enable-libstdcxx \
		--without-gconv \
		--disable-libgomp \
		--disable-libmudflap \
		--with-cpu-PPC603 \
		--disable-symvers

stmp-build-gcc-target: $(GCC_LINUXDIR)/Makefile
	cd $(GCC_LINUXDIR) ; make -j4
	touch stmp-build-gcc-target

stmp-install-gcc-target: stmp-build-gcc-target
	cd $(GCC_LINUXDIR) ; make install-target DESTDIR=$(INSTALLDIR)
	touch stmp-install-gcc-target

$(WPILIB_BUILDDIR)/Makefile: stmp-extract-wpilib
	mkdir -p $(WPILIB_BUILDDIR)
	cd $(WPILIB_BUILDDIR) ; frcmake $(WPILIB_SRCDIR) -DCMAKE_INSTALL_PREFIX=$(PREFIX)/$(TARGET)

stmp-build-wpilib: $(WPILIB_BUILDDIR)/Makefile
	cd $(WPILIB_BUILDDIR) ; make -j4
	touch stmp-build-wpilib

stmp-install-wpilib: stmp-build-wpilib
	cd $(WPILIB_BUILDDIR) ; make install DESTDIR=$(INSTALLDIR)
	touch stmp-install-wpilib

$(BUILDSCRIPTS_ORIG_ARCHIVE):
	wget -O $(BUILDSCRIPTS_ORIG_ARCHIVE) $(BUILDSCRIPTS_DOWNLOAD_URL)

stmp-extract-buildscripts: $(BUILDSCRIPTS_ORIG_ARCHIVE)
	cd $(WINDIR) ; unzip -qo $(BUILDSCRIPTS_ORIG_ARCHIVE)
	touch stmp-extract-buildscripts

$(BUILDSCRIPTS_BUILDDIR)/Makefile: stmp-extract-buildscripts
	mkdir -p $(BUILDSCRIPTS_BUILDDIR)
	cd $(BUILDSCRIPTS_BUILDDIR) ; cmake $(BUILDSCRIPTS_SRCDIR) -DCROSS_BUILD_WINDOWS=1

stmp-build-buildscripts: $(BUILDSCRIPTS_BUILDDIR)/Makefile
	cd $(BUILDSCRIPTS_BUILDDIR) ; make
	touch stmp-build-buildscripts

stmp-install-buildscripts: stmp-build-buildscripts
	cd $(BUILDSCRIPTS_BUILDDIR) ; make install DESTDIR=$(INSTALLDIR)
	touch stmp-install-buildscripts

### GCCDIST STUFF ###

stmp-gccdist-directories: stmp-extract-gccdist
	mkdir -p \
		$(TOOL_DIR) \
		$(WIND_BASE) \
		$(LDSCRIPT_DIR) \
		$(TOOL_DIR)/sys-include \
		$(WIND_BASE)/target/h \
		$(INSTALL_BASE_DIR)/licenses
	touch stmp-gccdist-directories

GCCDIST_ARCHIVE_BASE=$(WINDIR)/gccdist/WindRiver/vxworks-6.3

stmp-gccdist-scripts: stmp-gccdist-directories
	cp -R $(GCCDIST_ARCHIVE_BASE)/host $(WIND_BASE)
	touch stmp-gccdist-scripts

stmp-gccdist-headers: stmp-gccdist-directories
	cp -R $(GCCDIST_ARCHIVE_BASE)/target/h/. $(TOOL_DIR)/sys-include
	cp -R $(GCCDIST_ARCHIVE_BASE)/target/h/wrn/coreip/. $(WIND_BASE)/target/h
	touch stmp-gccdist-headers


$(LDSCRIPT_DIR)/dkm.ld: stmp-gccdist-directories
	sed '/ENTRY(_start)/d' < $(GCCDIST_ARCHIVE_BASE)/target/h/tool/gnu/ldscripts/link.OUT > $(LDSCRIPT_DIR)/dkm.ld

$(INSTALL_BASE_DIR)/licenses/wrs_license.htm: stmp-gccdist-directories
	cp $(WINDIR)/gccdist/WindRiver/gnu/3.4.4-vxworks-6.3/license.htm $(INSTALL_BASE_DIR)/licenses/wrs_license.htm

$(INSTALL_BASE_DIR)/licenses/gccdist_license.pdf: stmp-gccdist-directories
	cp $(WINDIR)/gccdist/WindRiver/gnu/3.4.4-vxworks-6.3/3rd_party_licensor_notice.pdf $(INSTALL_BASE_DIR)/licenses/gccdist_license.pdf

stmp-gccdist-all: \
	stmp-gccdist-scripts \
	stmp-gccdist-headers \
	$(LDSCRIPT_DIR)/dkm.ld \
	$(INSTALL_BASE_DIR)/licenses/wrs_license.htm \
	$(INSTALL_BASE_DIR)/licenses/gccdist_license.pdf
	touch stmp-gccdist-all

### BINARY DEPENDENCIES ###

CMAKE_EXTRACTNAME=cmake-2.8.10.2-win32-x86
CMAKE_FNAME=$(CMAKE_EXTRACTNAME).zip
CMAKE_ORIG_ARCHIVE=$(WINDIR)/$(CMAKE_FNAME)
CMAKE_DOWNLOAD_URL=http://www.cmake.org/files/v2.8/$(CMAKE_FNAME)

TCLKIT_FNAME=tclkitsh-8.5.8-win32.upx.exe
TCLKIT_DOWNLOAD_URL=http://tclkit.googlecode.com/files/$(TCLKIT_FNAME)

SED_EXTRACTNAME=ssed.exe
SED_FNAME=sed-3.62.zip
SED_ORIG_ARCHIVE=$(WINDIR)/$(SED_FNAME)
SED_DOWNLOAD_URL=http://sed.sourceforge.net/grabbag/ssed/$(SED_FNAME)
WPUT_FNAME=wput-pre0.6.zip
WPUT_ORIG_ARCHIVE=$(WINDIR)/$(WPUT_FNAME)
WPUT_DOWNLOAD_URL=http://downloads.sourceforge.net/project/wput/wput/pre0.6/$(WPUT_FNAME)
WPUT_FOLDER=$(WINDIR)/wput

stmp-download-cmake:
	wget -O $(CMAKE_ORIG_ARCHIVE) $(CMAKE_DOWNLOAD_URL)
	touch stmp-download-cmake

stmp-extract-cmake: stmp-download-cmake
	cd $(WINDIR) ; unzip -qo $(CMAKE_ORIG_ARCHIVE)
	mkdir -p $(INSTALLDIR)/cmake
	cd $(WINDIR) ; cp -r $(CMAKE_EXTRACTNAME)/. $(INSTALLDIR)/cmake
	touch stmp-extract-cmake

stmp-download-sed:
	wget -O $(SED_ORIG_ARCHIVE) $(SED_DOWNLOAD_URL)
	touch stmp-download-sed

stmp-extract-sed: stmp-download-sed
	cd $(WINDIR) ; unzip -qo $(SED_ORIG_ARCHIVE)
	touch stmp-extract-sed

stmp-download-tclkit:
	wget -O $(WINDIR)/$(TCLKIT_FNAME) $(TCLKIT_DOWNLOAD_URL)
	touch stmp-download-tclkit

stmp-download-wput:
	wget -O $(WPUT_ORIG_ARCHIVE) $(WPUT_DOWNLOAD_URL)
	touch stmp-download-wput

stmp-extract-wput:
	mkdir -p $(WPUT_FOLDER)
	cd $(WPUT_FOLDER) ; unzip -qo $(WPUT_ORIG_ARCHIVE)
	touch stmp-extract-wput

stmp-install-tools: stmp-download-tclkit stmp-extract-sed stmp-extract-wput
	cd $(WINDIR) ; \
		cp $(TCLKIT_FNAME) $(INSTALL_BASE_DIR)/bin/tclsh.exe ; \
		cp $(SED_EXTRACTNAME) $(INSTALL_BASE_DIR)/bin/sed.exe 
	cp -r mingw_tools/. $(INSTALL_BASE_DIR)/bin
	cp -r $(WPUT_FOLDER)/. $(INSTALL_BASE_DIR)/bin
	touch stmp-install-tools
