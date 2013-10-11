#Makefile for WIX Toolchain

#executables:

BUNDLENAME=FRCToolchainInstaller.exe
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

all: $(BUILD_DIR)\\$(BUNDLENAME)

$(BUILD_DIR)\\$(GENERATE_CG).wxs:
	$(HEAT) dir $(HARVEST_DIR) -sreg -ag -dr INSTALLDIR -cg $(GENERATE_CG) -var var.HarvestDir -out $(BUILD_DIR)\\$(GENERATE_CG).wxs

$(BUILD_DIR)\\$(GENERATE_CG).wixobj: $(BUILD_DIR)\\$(GENERATE_CG).wxs
	$(CANDLE) -dHarvestDir=SourceDir\\..\\$(HARVEST_DIR) $(BUILD_DIR)\\$(GENERATE_CG).wxs -out $(BUILD_DIR)\\$(GENERATE_CG).wixobj

$(BUILD_DIR)\\$(CMAKE_CG).wxs:
	$(HEAT) dir $(CMAKE_HARVEST) -sreg -ag -dr INSTALLDIR -cg $(CMAKE_CG) -var var.CMakeHarvest -out $(BUILD_DIR)\\$(CMAKE_CG).wxs

$(BUILD_DIR)\\$(CMAKE_CG).wixobj: $(BUILD_DIR)\\$(CMAKE_CG).wxs
	$(CANDLE) -dCMakeHarvest=SourceDir\\..\\$(CMAKE_HARVEST) $(BUILD_DIR)\\$(CMAKE_CG).wxs -out $(BUILD_DIR)\\$(CMAKE_CG).wixobj

$(BUILD_DIR)\\Toolchain.wixobj: Toolchain.wxs Properties.wxi
	$(CANDLE) Toolchain.wxs -out $(BUILD_DIR)\\Toolchain.wixobj

$(BUILD_DIR)\\$(INSTALLERNAME): $(BUILD_DIR)\\Toolchain.wixobj $(BUILD_DIR)\\$(GENERATE_CG).wixobj $(BUILD_DIR)\\$(CMAKE_CG).wixobj
	$(LIGHT) -ext WixUIExtension $(BUILD_DIR)\\Toolchain.wixobj $(BUILD_DIR)\\$(GENERATE_CG).wixobj $(BUILD_DIR)\\$(CMAKE_CG).wixobj -out $(BUILD_DIR)\\$(INSTALLERNAME)

$(BUILD_DIR)\\Bundle.wixobj: Bundle.wxs Properties.wxi
	$(CANDLE) Bundle.wxs -ext WixBalExtension -out $(BUILD_DIR)\\Bundle.wixobj

$(BUILD_DIR)\\$(BUNDLENAME): $(BUILD_DIR)\\$(INSTALLERNAME) $(BUILD_DIR)\\Bundle.wixobj
	$(LIGHT) -ext WixBalExtension $(BUILD_DIR)\\Bundle.wixobj -out $(BUILD_DIR)\\$(BUNDLENAME)
