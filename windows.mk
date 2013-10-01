#Makefile for WIX Toolchain

#executables:

INSTALLERNAME=FRCToolchainInstaller.msi

HEAT=heat
CANDLE=candle
LIGHT=light

#if you change either one of these bad things might happen
HARVEST_DIR=win32\\install-prefix\\mingw
GENERATE_CG=VxWorksToolchainGroup

CMAKE_HARVEST=win32\\install-prefix\\cmake
CMAKE_CG=CMakeGroup

all: $(INSTALLERNAME)

$(GENERATE_CG).wxs.in:
	$(HEAT) dir $(HARVEST_DIR) -sreg -ag -dr INSTALLDIR -cg $(GENERATE_CG) -out $(GENERATE_CG).wxs.in

$(GENERATE_CG).wxs: $(GENERATE_CG).wxs.in
	sed s!SourceDir\\!SourceDir\\$(HARVEST_DIR)\\!g < $(GENERATE_CG).wxs.in > $(GENERATE_CG).wxs

$(GENERATE_CG).wixobj: $(GENERATE_CG).wxs
	$(CANDLE) $(GENERATE_CG).wxs

$(CMAKE_CG).wxs.in:
	$(HEAT) dir $(CMAKE_HARVEST) -sreg -ag -dr INSTALLDIR -cg $(CMAKE_CG).wxs -out $(CMAKE_CG).wxs.in

$(CMAKE_CG).wxs: $(CMAKE_CG).wxs.in
	sed s!SourceDir\\!SourceDir\\$(CMAKE_HARVEST)\\!g < $(CMAKE_CG).wxs.in > $(CMAKE_CG).wxs

$(CMAKE_CG).wixobj: $(CMAKE_CG).wxs
	$(CANDLE) $(CMAKE_CG).wxs

Toolchain.wixobj: Toolchain.wxs
	$(CANDLE) Toolchain.wxs

$(INSTALLERNAME): Toolchain.wixobj $(GENERATE_CG).wixobj $(CMAKE_CG).wixobj
	$(LIGHT) -ext WixUIExtension Toolchain.wixobj $(GENERATE_CG).wixobj $(CMAKE_CG).wixobj -out $(INSTALLERNAME)
