#!/usr/bin/env make -f

#final targets:
.PHONY: all
all: \
	stmp/gccdist-all \
	stmp/install-binutils \
	stmp/install-gcc-host \
	stmp/install-gcc-target \
	stmp/install-wpilib \
	stmp/install-buildscripts \
	stmp/install-tools \
	stmp/copy-make \
	stmp/extract-cmake

.PHONY: clean
clean:
	rm -rf win32
	rm -rf stmp
	rm -rf wix-build
	rm -f *.exe *.dll

PREFIX=/mingw
TARGET=powerpc-wrs-vxworks
WINDIR=$(CURDIR)/win32
INSTALLDIR=$(WINDIR)/install-prefix

GCC_DOWNLOAD_URL=http://ftp.gnu.org/gnu/gcc/gcc-4.8.2/gcc-4.8.2.tar.gz
GCC_EXTRACTNAME=gcc-4.8.2

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

stmp/prepare:
	mkdir -p win32/install-prefix/mingw
	mkdir -p stmp
	mkdir -p wix-build
	touch stmp/prepare

stmp/download-binutils: stmp/prepare
	wget -O $(BINUTILS_ORIG_ARCHIVE) $(BINUTILS_DOWNLOAD_URL)
	touch stmp/download-binutils

stmp/extract-binutils: stmp/download-binutils
	cd $(WINDIR) ; tar -xf $(BINUTILS_ORIG_ARCHIVE)
	touch stmp/extract-binutils

stmp/download-gcc: stmp/prepare
	wget -O $(GCC_ORIG_ARCHIVE) $(GCC_DOWNLOAD_URL)
	touch stmp/download-gcc

stmp/prelim-extract-gcc: stmp/download-gcc
	cd $(WINDIR) ; tar -xf $(GCC_ORIG_ARCHIVE)
	touch stmp/prelim-extract-gcc

stmp/extract-gcc: stmp/prelim-extract-gcc
	cd $(GCC_SRCDIR) ; ./contrib/download_prerequisites
	touch stmp/extract-gcc

stmp/download-wpilib: stmp/prepare
	wget -O $(WPILIB_ORIG_ARCHIVE) $(WPILIB_DOWNLOAD_URL)
	touch stmp/download-wpilib

stmp/extract-wpilib: stmp/download-wpilib
	cd $(WINDIR) ; unzip -qo $(WPILIB_ORIG_ARCHIVE)
	touch stmp/extract-wpilib

stmp/download-gccdist: stmp/prepare
	wget -O $(GCCDIST_ORIG_ARCHIVE) $(GCCDIST_DOWNLOAD_URL)
	touch stmp/download-gccdist

stmp/extract-gccdist: stmp/download-gccdist
	cd $(WINDIR) ; unzip -qo $(GCCDIST_ORIG_ARCHIVE)
	find $(WINDIR)/gccdist -type f -exec dos2unix {} +
	touch stmp/extract-gccdist

$(BINUTILS_BUILDDIR)/Makefile: stmp/extract-binutils
	mkdir -p $(BINUTILS_BUILDDIR)
	cd $(BINUTILS_BUILDDIR) ; $(BINUTILS_SRCDIR)/configure \
		--prefix=$(INSTALLDIR)$(PREFIX) \
		--build=$(shell $(BINUTILS_SRCDIR)/config.guess) \
		--target=$(TARGET) \
		--host=i686-w64-mingw32

stmp/build-binutils: $(BINUTILS_BUILDDIR)/Makefile
	cd $(BINUTILS_BUILDDIR) ; make -j4
	touch stmp/build-binutils

stmp/install-binutils: stmp/build-binutils
	cd $(BINUTILS_BUILDDIR) ; make install
	touch stmp/install-binutils

$(GCC_BUILDDIR)/Makefile: stmp/extract-gcc
	mkdir -p $(GCC_BUILDDIR)
	cd $(GCC_BUILDDIR) ; $(GCC_SRCDIR)/configure \
		--prefix=$(INSTALLDIR)$(PREFIX) \
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

stmp/build-gcc-host: $(GCC_BUILDDIR)/Makefile
	cd $(GCC_BUILDDIR) ; make all-host -j4
	touch stmp/build-gcc-host

stmp/install-gcc-host: stmp/build-gcc-host
	cd $(GCC_BUILDDIR) ; make install-host
	touch stmp/install-gcc-host

#GCC has trouble building target libraries in a canadian cross configuration
#so brute-force solution is just build two compilers...

$(GCC_LINUXDIR)/Makefile: stmp/extract-gcc
	mkdir -p $(GCC_LINUXDIR)

	cd $(GCC_LINUXDIR) ; CFLAGS_FOR_TARGET="-g -O2 -mlongcall" $(GCC_SRCDIR)/configure \
		--prefix=$(INSTALLDIR)$(PREFIX) \
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
		--disable-symvers \
		--enable-cxx-flags=-mlongcall

stmp/build-gcc-target: $(GCC_LINUXDIR)/Makefile
	cd $(GCC_LINUXDIR) ; make -j4
	touch stmp/build-gcc-target

stmp/install-gcc-target: stmp/build-gcc-target
	cd $(GCC_LINUXDIR) ; make install-target 
	touch stmp/install-gcc-target

$(WPILIB_BUILDDIR)/Makefile: stmp/extract-wpilib
	mkdir -p $(WPILIB_BUILDDIR)
	cd $(WPILIB_BUILDDIR) ; frcmake $(WPILIB_SRCDIR) -DCMAKE_INSTALL_PREFIX=$(PREFIX)/$(TARGET)

stmp/build-wpilib: $(WPILIB_BUILDDIR)/Makefile
	cd $(WPILIB_BUILDDIR) ; make -j4
	touch stmp/build-wpilib

stmp/install-wpilib: stmp/build-wpilib
	cd $(WPILIB_BUILDDIR) ; make install DESTDIR=$(INSTALLDIR)
	touch stmp/install-wpilib

$(BUILDSCRIPTS_ORIG_ARCHIVE): stmp/prepare
	wget -O $(BUILDSCRIPTS_ORIG_ARCHIVE) $(BUILDSCRIPTS_DOWNLOAD_URL)

stmp/extract-buildscripts: $(BUILDSCRIPTS_ORIG_ARCHIVE)
	cd $(WINDIR) ; unzip -qo $(BUILDSCRIPTS_ORIG_ARCHIVE)
	touch stmp/extract-buildscripts

$(BUILDSCRIPTS_BUILDDIR)/Makefile: stmp/extract-buildscripts
	mkdir -p $(BUILDSCRIPTS_BUILDDIR)
	cd $(BUILDSCRIPTS_BUILDDIR) ; cmake $(BUILDSCRIPTS_SRCDIR) -DCROSS_BUILD_WINDOWS=1

stmp/build-buildscripts: $(BUILDSCRIPTS_BUILDDIR)/Makefile
	cd $(BUILDSCRIPTS_BUILDDIR) ; make
	touch stmp/build-buildscripts

stmp/install-buildscripts: stmp/build-buildscripts
	cd $(BUILDSCRIPTS_BUILDDIR) ; make install DESTDIR=$(INSTALLDIR)
	touch stmp/install-buildscripts

### GCCDIST STUFF ###

stmp/gccdist-directories: stmp/extract-gccdist
	mkdir -p \
		$(TOOL_DIR) \
		$(WIND_BASE) \
		$(LDSCRIPT_DIR) \
		$(TOOL_DIR)/sys-include \
		$(WIND_BASE)/target/h \
		$(INSTALL_BASE_DIR)/licenses
	touch stmp/gccdist-directories

GCCDIST_ARCHIVE_BASE=$(WINDIR)/gccdist/WindRiver/vxworks-6.3

stmp/gccdist-scripts: stmp/gccdist-directories
	cp -dpr --no-preserve=ownership $(GCCDIST_ARCHIVE_BASE)/host $(WIND_BASE)
	touch stmp/gccdist-scripts

stmp/gccdist-headers: stmp/gccdist-directories
	cp -dpr --no-preserve=ownership $(GCCDIST_ARCHIVE_BASE)/target/h/. $(TOOL_DIR)/sys-include
	cp -r $(TOOL_DIR)/sys-include/wrn/coreip/. $(WIND_BASE)/target/h
	touch stmp/gccdist-headers

$(LDSCRIPT_DIR)/dkm.ld: stmp/gccdist-directories
	sed '/ENTRY(_start)/d' < $(GCCDIST_ARCHIVE_BASE)/target/h/tool/gnu/ldscripts/link.OUT > $(LDSCRIPT_DIR)/dkm.ld

$(INSTALL_BASE_DIR)/licenses/wrs_license.htm: stmp/gccdist-directories
	cp $(WINDIR)/gccdist/WindRiver/gnu/3.4.4-vxworks-6.3/license.htm $(INSTALL_BASE_DIR)/licenses/wrs_license.htm

$(INSTALL_BASE_DIR)/licenses/gccdist_license.pdf: stmp/gccdist-directories
	cp $(WINDIR)/gccdist/WindRiver/gnu/3.4.4-vxworks-6.3/3rd_party_licensor_notice.pdf $(INSTALL_BASE_DIR)/licenses/gccdist_license.pdf

stmp/gccdist-all: \
	stmp/gccdist-scripts \
	stmp/gccdist-headers \
	$(LDSCRIPT_DIR)/dkm.ld \
	$(INSTALL_BASE_DIR)/licenses/wrs_license.htm \
	$(INSTALL_BASE_DIR)/licenses/gccdist_license.pdf
	touch stmp/gccdist-all

### BINARY DEPENDENCIES ###

CMAKE_EXTRACTNAME=cmake-2.8.12-win32-x86
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

LIBICONV_FNAME=libiconv-1.14-2-mingw32-dll-2.tar.lzma
LIBICONV_ORIG_ARCHIVE=$(WINDIR)/$(LIBICONV_FNAME)
LIBICONV_DOWNLOAD_URL=http://downloads.sourceforge.net/project/mingw/MinGW/Base/libiconv/libiconv-1.14-2/$(LIBICONV_FNAME)
LIBICONV_FOLDER=$(WINDIR)/libiconv

LIBINTL_FNAME=libintl-0.18.1.1-2-mingw32-dll-8.tar.lzma
LIBINTL_ORIG_ARCHIVE=$(WINDIR)/$(LIBINTL_FNAME)
LIBINTL_DOWNLOAD_URL=http://downloads.sourceforge.net/project/mingw/MinGW/Base/gettext/gettext-0.18.1.1-2/$(LIBINTL_FNAME)
LIBINTL_FOLDER=$(WINDIR)/libintl

LIBGCC_FNAME=libgcc-4.7.2-1-mingw32-dll-1.tar.lzma
LIBGCC_ORIG_ARCHIVE=$(WINDIR)/$(LIBGCC_FNAME)
LIBGCC_DOWNLOAD_URL=http://downloads.sourceforge.net/project/mingw/MinGW/Base/gcc/Version4/gcc-4.7.2-1/$(LIBGCC_FNAME)
LIBGCC_FOLDER=$(WINDIR)/libgcc

MAKE_FNAME=make-3.82-5-mingw32-bin.tar.lzma
MAKE_ORIG_ARCHIVE=$(WINDIR)/$(MAKE_FNAME)
MAKE_DOWNLOAD_URL=http://downloads.sourceforge.net/project/mingw/MinGW/Extension/make/make-3.82-mingw32/$(MAKE_FNAME)
MAKE_FOLDER=$(WINDIR)/mingw32-make

stmp/download-cmake: stmp/prepare
	wget -O $(CMAKE_ORIG_ARCHIVE) $(CMAKE_DOWNLOAD_URL)
	touch stmp/download-cmake

stmp/extract-cmake: stmp/download-cmake
	cd $(WINDIR) ; unzip -qo $(CMAKE_ORIG_ARCHIVE)
	mkdir -p $(INSTALLDIR)/cmake
	cd $(WINDIR) ; cp -r $(CMAKE_EXTRACTNAME)/. $(INSTALLDIR)/cmake
	touch stmp/extract-cmake

stmp/download-sed: stmp/prepare
	wget -O $(SED_ORIG_ARCHIVE) $(SED_DOWNLOAD_URL)
	touch stmp/download-sed

stmp/extract-sed: stmp/download-sed
	cd $(WINDIR) ; unzip -qo $(SED_ORIG_ARCHIVE)
	touch stmp/extract-sed

stmp/download-tclkit: stmp/prepare
	wget -O $(WINDIR)/$(TCLKIT_FNAME) $(TCLKIT_DOWNLOAD_URL)
	touch stmp/download-tclkit

stmp/download-wput: stmp/prepare
	wget -O $(WPUT_ORIG_ARCHIVE) $(WPUT_DOWNLOAD_URL)
	touch stmp/download-wput

stmp/extract-wput: stmp/download-wput
	mkdir -p $(WPUT_FOLDER)
	cd $(WPUT_FOLDER) ; unzip -qo $(WPUT_ORIG_ARCHIVE)
	touch stmp/extract-wput

stmp/download-libiconv: stmp/prepare
	wget -O $(LIBICONV_ORIG_ARCHIVE) $(LIBICONV_DOWNLOAD_URL)
	touch stmp/download-libiconv

stmp/extract-libiconv: stmp/download-libiconv
	mkdir -p $(LIBICONV_FOLDER)
	cd $(LIBICONV_FOLDER) ; tar --lzma -xvf $(LIBICONV_ORIG_ARCHIVE)
	touch stmp/extract-libiconv

stmp/download-libintl: stmp/prepare
	wget -O $(LIBINTL_ORIG_ARCHIVE) $(LIBINTL_DOWNLOAD_URL)
	touch stmp/download-libintl

stmp/extract-libintl: stmp/download-libintl
	mkdir -p $(LIBINTL_FOLDER)
	cd $(LIBINTL_FOLDER) ; tar --lzma -xvf $(LIBINTL_ORIG_ARCHIVE)
	touch stmp/extract-libintl

stmp/download-libgcc: stmp/prepare
	wget -O $(LIBGCC_ORIG_ARCHIVE) $(LIBGCC_DOWNLOAD_URL)
	touch stmp/download-libgcc

stmp/extract-libgcc: stmp/download-libgcc
	mkdir -p $(LIBGCC_FOLDER)
	cd $(LIBGCC_FOLDER) ; tar --lzma -xvf $(LIBGCC_ORIG_ARCHIVE)
	touch stmp/extract-libgcc

stmp/download-make: stmp/prepare
	wget -O $(MAKE_ORIG_ARCHIVE) $(MAKE_DOWNLOAD_URL)
	touch stmp/download-make

stmp/extract-make: stmp/download-make
	mkdir -p $(MAKE_FOLDER)
	cd $(MAKE_FOLDER) ; tar --lzma -xvf $(MAKE_ORIG_ARCHIVE)
	touch stmp/extract-make

stmp/install-tools: stmp/download-tclkit stmp/extract-sed stmp/extract-wput stmp/extract-libiconv stmp/extract-libintl stmp/extract-libgcc stmp/extract-make
	cd $(WINDIR) ; \
		cp $(TCLKIT_FNAME) $(INSTALL_BASE_DIR)/bin/tclsh.exe ; \
		cp $(SED_EXTRACTNAME) $(INSTALL_BASE_DIR)/bin/sed.exe 
	cp -r $(WPUT_FOLDER)/. $(INSTALL_BASE_DIR)/bin
	cp -r $(LIBICONV_FOLDER)/bin/. $(INSTALL_BASE_DIR)/bin
	cp -r $(LIBINTL_FOLDER)/bin/. $(INSTALL_BASE_DIR)/bin
	cp -r $(LIBGCC_FOLDER)/bin/. $(INSTALL_BASE_DIR)/bin
	cp -r $(MAKE_FOLDER)/bin/. $(INSTALL_BASE_DIR)/bin
	touch stmp/install-tools

stmp/copy-make: stmp/install-tools
	cp $(INSTALL_BASE_DIR)/bin/mingw32-make.exe $(CURDIR)
	cp $(INSTALL_BASE_DIR)/bin/libiconv-2.dll $(CURDIR)
	cp $(INSTALL_BASE_DIR)/bin/libintl-8.dll $(CURDIR)
	cp $(INSTALL_BASE_DIR)/bin/libgcc_s_dw2-1.dll $(CURDIR)
	touch stmp/copy-make
