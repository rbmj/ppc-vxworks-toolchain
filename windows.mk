#Makefile for WIX Toolchain

#executables:

INSTALLERNAME=FRCToolchainInstaller.msi

HEAT=heat
CANDLE=candle
LIGHT=light

#if you change any one of these bad things might happen
BUILD_DIR=wix-build
HARVEST_DIR=win32\\install-prefix\\mingw
GENERATE_CG=VxWorksToolchainGroup

CMAKE_HARVEST=win32\\install-prefix\\cmake
CMAKE_CG=CMakeGroup

all: $(BUILD_DIR)\\$(INSTALLERNAME)

$(BUILD_DIR)\\$(GENERATE_CG).wxs:
	$(HEAT) dir $(HARVEST_DIR) -sreg -ag -dr INSTALLDIR -cg $(GENERATE_CG) -var var.HarvestDir -out $(BUILD_DIR)\\$(GENERATE_CG).wxs

$(BUILD_DIR)\\$(GENERATE_CG).wixobj: $(BUILD_DIR)\\$(GENERATE_CG).wxs
	$(CANDLE) -dHarvestDir=$(CURDIR)\\$(HARVEST_DIR) $(BUILD_DIR)\\$(GENERATE_CG).wxs -out $(BUILD_DIR)\\$(GENERATE_CG).wixobj

$(BUILD_DIR)\\$(CMAKE_CG).wxs:
	$(HEAT) dir $(CMAKE_HARVEST) -sreg -ag -dr INSTALLDIR -cg $(CMAKE_CG) -var var.CMakeHarvest -out $(BUILD_DIR)\\$(CMAKE_CG).wxs

$(BUILD_DIR)\\$(CMAKE_CG).wixobj: $(BUILD_DIR)\\$(CMAKE_CG).wxs
	$(CANDLE) -dCMakeHarvest=$(CURDIR)\\$(CMAKE_HARVEST) $(BUILD_DIR)\\$(CMAKE_CG).wxs -out $(BUILD_DIR)\\$(CMAKE_CG).wixobj

$(BUILD_DIR)\\Toolchain.wixobj: Toolchain.wxs
	$(CANDLE) Toolchain.wxs -out $(BUILD_DIR)\\Toolchain.wixobj

$(BUILD_DIR)\\$(INSTALLERNAME): $(BUILD_DIR)\\Toolchain.wixobj $(BUILD_DIR)\\$(GENERATE_CG).wixobj $(BUILD_DIR)\\$(CMAKE_CG).wixobj
	$(LIGHT) -ext WixUIExtension $(BUILD_DIR)\\Toolchain.wixobj $(BUILD_DIR)\\$(GENERATE_CG).wixobj $(BUILD_DIR)\\$(CMAKE_CG).wixobj -out $(BUILD_DIR)\\$(INSTALLERNAME)
