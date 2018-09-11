# ----------------------------------------------------------------------------
#
#        ** **        **          **  ****      **  **********  ********** ®
#       **   **        **        **   ** **     **  **              **
#      **     **        **      **    **  **    **  **              **
#     **       **        **    **     **   **   **  *********       **
#    **         **        **  **      **    **  **  **              **
#   **           **        ****       **     ** **  **              **
#  **  .........  **        **        **      ****  **********      **
#     ...........
#                                     Reach Further™
#
# ----------------------------------------------------------------------------
# 
#  This design is the property of Avnet.  Publication of this
#  design is not authorized without written consent from Avnet.
# 
#  Please direct any questions to the UltraZed community support forum:
#     http://www.ultrazed.org/forum
# 
#  Product information is available at:
#     http://www.ultrazed.org/product/ultrazed-EG
# 
#  Disclaimer:
#     Avnet, Inc. makes no warranty for the use of this code or design.
#     This code is provided  "As Is". Avnet, Inc assumes no responsibility for
#     any errors, which may appear in this code, nor does it make a commitment
#     to update the information contained herein. Avnet, Inc specifically
#     disclaims any implied warranties of fitness for a particular purpose.
#                      Copyright(c) 2017 Avnet, Inc.
#                              All rights reserved.
# 
# ----------------------------------------------------------------------------
# 
#  Create Date:         Aug 25, 2017
#  Design Name:         Avnet UltraZed-3EG SOM PetaLinux BSP Generator
#  Module Name:         make_uz3eg_pciec_ccd_bsp.tcl
#  Project Name:        Avnet UltraZed-3EG SOM  PetaLinux BSP Generator
#  Target Devices:      Xilinx Zynq Ultrascale MPSoC
#  Hardware Boards:     Avnet UltraZed-3EG SOM and supported development
#                       carriers such as the PCIEC (UZ3EG_PCIEC)
# 
#  Tool versions:       Xilinx Vivado 2017.2
# 
#  Description:         Build Script for UZ3EG PetaLinux BSP HW Platform
# 
#  Dependencies:        None
#
#  Revision:            Aug 25, 2017: 1.00 Initial version
#                       Sep 11, 2017: 2.00 Modified design:
#                                          - add TPM 2.0 SPI support
#                       Jun 25, 2018: 2.01 Modified design:
#                                          - add support for FMC-Network1
#                                            dual Ethernet ports
# 
# ----------------------------------------------------------------------------

#!/bin/bash

# Set global variables here.
APP_PETALINUX_INSTALL_PATH=/opt/petalinux-v2017.4-final
APP_VIVADO_INSTALL_PATH=/opt/Xilinx/Vivado/2017.4
PLNX_VER=2017_4
BUILD_BOOT_SD_OPTION=yes
FSBL_PROJECT_NAME=zynqmp_fsbl
HDL_HARDWARE_NAME=uz3eg_pciec_ccd_hw
HDL_PROJECT_NAME=uz3eg_pciec_ccd
HDL_PROJECTS_FOLDER=../../hdl/Projects
HDL_SCRIPTS_FOLDER=../../hdl/Scripts
PETALINUX_APPS_FOLDER=../../petalinux/apps
PETALINUX_CONFIGS_FOLDER=../../petalinux/configs
PETALINUX_PROJECTS_FOLDER=../../petalinux/projects
PETALINUX_SCRIPTS_FOLDER=../../petalinux/scripts
START_FOLDER=`pwd`
TFTP_HOST_FOLDER=/tftpboot

PLNX_BUILD_SUCCESS=-1

source_tools_settings ()
{
  # Source the tools settings scripts so that both Vivado and PetaLinux can 
  # be used throughout this build script.
  source ${APP_VIVADO_INSTALL_PATH}/settings64.sh
  source ${APP_PETALINUX_INSTALL_PATH}/settings.sh
}

# This function checks to see if any board specific device-tree is available 
# and, if so, installs it into the meta-user BSP recipes folder.
petalinux_project_configure_devicetree ()
{
  # Check to see if a device (usually related to the SOM) specific system-user
  # devicetree source file is available.  According to PetaLinux methodology,
  # the system-user.dtsi file is where all of the non-autogenerated devicetree
  # information is supposed to be included.  The benefit of using this 
  # approach over modifying system-conf.dtsi is that the petalinux-config tool
  # is designed to leave system-user.dtsi untouched in case you need to go 
  # back and configure your PetaLinux project further after this bulid 
  # automation has been applied.
  #
  # If available, overwrite the board specific top level devicetree source 
  # with the revision controlled source files.
  if [ -f ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/device-tree/system-user.dtsi.${HDL_PROJECT_NAME} ]
    then
    echo " "
    echo "Overwriting system-user level devicetree source include file..."
    echo " "
    cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/device-tree/system-user.dtsi.${HDL_PROJECT_NAME} \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi
  else
    echo " "
    echo "WARNING: No board specific PetaLinux project configuration files found, "
    echo "PetaLinux project config is not touched for this build ..."
echo "=== ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/device-tree/system-user.dtsi.${HDL_PROJECT_NAME} ==="
    echo " "
  fi
}

# This function checks to see if any user configuration is available for the
# kernel and, if so, sets up the meta-user kernel recipes folder and installs
# the user kernel configuration into that folder.
petalinux_project_configure_kernel ()
{
  # Check to see if a device (usually related to the SOM or reference design) 
  # specific kernel user configuration file is available.  
  #
  # If available, copy the kernel user configuration file to the meta-user
  # kernel recipes folder.
  if [ -f ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/kernel/user.cfg.${HDL_PROJECT_NAME} ]
    then

    # Create the meta-user kernel recipes folder structure if it does not 
    # already exist (for a new PetaLinux project, it usually doesn't).
    if [ ! -d ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel ]
      then
      mkdir ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel
    fi
    if [ ! -d ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux ]
      then
      mkdir ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux
    fi
    if [ ! -d ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx ]
      then
      mkdir ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx
    fi

    # Copy the kernel user config over to the meta-user kernel recipe folder.
    echo " "
    echo "Overwriting kernel user configuration file..."
    echo " "
    cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/kernel/user.cfg.${HDL_BOARD_NAME} \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx/user_${HDL_BOARD_NAME}.cfg
    
    # Create the kernel user config .bbappend file if it does not already exist.
    if [ ! -f ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx_%.bbappend ]
      then
      echo "SRC_URI += \"file://user_${HDL_BOARD_NAME}.cfg\"" > ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx_%.bbappend
      echo "" >> ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx_%.bbappend
      echo "FILESEXTRAPATHS_prepend := \"\${THISDIR}/\${PN}:\"" >> ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx_%.bbappend
    fi 
  else
    echo " "
    echo "WARNING: No board specific kernel user configuration files found, "
    echo "PetaLinux kernel user config recipe is not touched for this build ..."
    echo " "
  fi

    #
    # TODO: Verify that SPI patching is not required to reach the TPM 2.0 Pmod.
    #       If no longer required, remove this section of code leftover from
    #       the 2017.2 build.
    #

    # Copy the kernel user config over to the meta-user kernel recipe folder.
#    echo " "
#    echo "Overwriting kernel user configuration file..."
#    echo " "
#    cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/kernel/user.cfg.${HDL_PROJECT_NAME} \
#    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx/user_${HDL_PROJECT_NAME}.cfg

    # Copy the kernel patches over to the meta-user kernel recipe folder.
#    echo " "
#    echo "Adding kernel patches ..."
#    echo " "
#    cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/kernel/tpm-tis-spi.patch \
#    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx/.

    # Create the kernel user config .bbappend file if it does not already 
    # exist.
#    if [ ! -f ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx_%.bbappend ]
#      then
#      echo "SRC_URI += \"file://user_${HDL_PROJECT_NAME}.cfg\"" > ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx_%.bbappend

#      echo "" >> ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx_%.bbappend
#      echo "SRC_URI_append = \" \          " >> ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx_%.bbappend
#      echo "  file://tpm-tis-spi.patch \ " >> ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx_%.bbappend
#      echo "\"                             " >> ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx_%.bbappend

#      echo "" >> ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx_%.bbappend
#      echo "FILESEXTRAPATHS_prepend := \"\${THISDIR}/\${PN}:\"" >> ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx_%.bbappend
#    fi 
#  else
#    echo " "
#    echo "WARNING: No board specific kernel user configuration files found, "
#    echo "PetaLinux kernel user config recipe is not touched for this build ..."
#    echo " "
#  fi
}

# This function checks to see if any board specific configuration is available
# for the rootfs and, if so, installs the rootfs configuration into the 
# PetaLinux project configs folder.
petalinux_project_configure_rootfs ()
{
  # Check to see if a device (usually related to the SOM or reference design) 
  # specific rootfs configuration file is available.  
  #
  # If available, overwrite the board specific rootfs configuration file with
  # the revision controlled config file.
  if [ -f ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/rootfs/config.${HDL_PROJECT_NAME} ]
    then
    echo " "
    echo "Overwriting rootfs configuration file..."
    echo " "
    cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/rootfs/config.${HDL_PROJECT_NAME} \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/configs/rootfs_config
  else
    echo " "
    echo "WARNING: No board specific rootfs configuration files found, "
    echo "PetaLinux rootfs config is not touched for this build ..."
    echo " "
  fi

  if [ -d ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/meta-user/uz3eg_pciec_ccd/recipes-apps ]
    then
    # Copy the applications to the meta-user apps recipe folder.
    echo " "
    echo "Adding applications ..."
    echo " "
    cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/meta-user/uz3eg_pciec_ccd/recipes-apps/* \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-apps/.
  else
    echo " "
    echo "WARNING: No applications found, "
    echo "project-spec/meta-user/recipes-apps is not touched for this build ..."
    echo " "
  fi

  if [ -d ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/meta-user/uz3eg_pciec_ccd/recipes-core ]
    then
    # Copy the applications to the meta-user core recipe folder.
    echo " "
    echo "Adding core files ..."
    echo " "
    cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/meta-user/uz3eg_pciec_ccd/recipes-core/* \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-core/.
  else
    echo " "
    echo "WARNING: No core files found, "
    echo "project-spec/meta-user/recipes-core is not touched for this build ..."
    echo " "
  fi

}

# This function must add any patches or files that are needed to support 
# booting from SD card.  This usually invovles manipulation of U-Boot 
# commands within environment variables in order to force the Linux Kernel,
# devicetree, and RAMdisk rootfs (image.ub) to be loaded from the SD card 
# FAT32 filesystem.
petalinux_project_set_boot_config_sd ()
{ 
  # Apply the meta-user level BSP platform-top.h file to establish a baseline
  # override for anything that was directly generated by petalinux-config by
  # overwitting the file found in the following folder with the board specific
  # revision controlled version:
  #  
  # project-spec/meta-user/recipes-bsp/u-boot/files/platform-top.h
  echo " "
  echo "Overriding meta-user BSP platform-top.h to add SD boot support in U-Boot ..."
  echo " "
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-bsp/u-boot/files/
  cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/u-boot/platform-top.h.uz_sd_boot ./platform-top.h
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}
}

create_petalinux_bsp ()
{ 
  # This function is responsible for creating a PetaLinux BSP around the
  # hardware platform specificed in HDL_PROJECT_NAME variable and build
  # the PetaLinux project within the folder specified by the 
  # PETALINUX_PROJECT_NAME variable.
  #
  # When complete, the BSP should boot from SD card by default.

  # Check to see if the PetaLinux projects folder even exists because when
  # you clone the source tree from Avnet Github, the projects folder is not
  # part of that tree.
  if [ ! -d ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER} ]; then
    # Create the PetaLinux projects folder.
    mkdir ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}
  fi

  # Change to PetaLinux projects folder.
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}

  # Create the PetaLinux project.
  petalinux-create --type project --template zynqMP --name ${PETALINUX_PROJECT_NAME}

  # Create the hardware definition folder.
  mkdir -p ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/hw_platform

  # Import the hardware definition files and hardware platform bitstream from
  # implemented system products folder.
  cd ${START_FOLDER}/${HDL_PROJECTS_FOLDER}

  echo " "
  echo "Importing hardware definition ${HDL_HARDWARE_NAME} from impl_1 folder ..."
  echo " "

  cp -f ${HDL_PROJECT_NAME}/${HDL_BOARD_NAME}/${HDL_PROJECT_NAME}.runs/impl_1/${HDL_PROJECT_NAME}_wrapper.sysdef \
  ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/hw_platform/${HDL_HARDWARE_NAME}.hdf

  echo " "
  echo "Importing hardware bitstream ${HDL_HARDWARE_NAME} from impl_1 folder ..."
  echo " "

  cp -f ${HDL_PROJECT_NAME}/${HDL_BOARD_NAME}/${HDL_PROJECT_NAME}.runs/impl_1/${HDL_PROJECT_NAME}_wrapper.bit \
  ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/hw_platform/system_wrapper.bit

  # Change directories to the hardware definition folder for the PetaLinux
  # project, at this point the .hdf file must be located in this folder 
  # for the petalinux-config step to be successful.
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}

  # Import the hardware description into the PetaLinux project.
  petalinux-config --oldconfig --get-hw-description=./hw_platform/ -p ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}
 
  # Overwrite the PetaLinux project config with some sort of revision 
  # controlled source file.
  # 
  # If a patch is available, then the patch is preferred to be used since you
  # won't unintentionally affect as many pieces of the project configuration.
  #
  # If a patch is not available, but an entire board specific configuration is 
  # available, then that has second preference but you can wipe out some
  # project configuration attributes this way.
  #
  # If neither of those are present, use the generic one by default.
  if [ -f ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/config.${HDL_BOARD_NAME}_CCD.patch ] 
    then
    echo " "
    echo "Patching PetaLinux project config for project ..."
    echo " "
    cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/configs/
    patch < ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/config.${HDL_BOARD_NAME}_CCD.patch
    cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}
  elif [ -f ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/config.${HDL_PROJECT_NAME}.patch ] 
    then
    echo " "
    echo "Patching PetaLinux project config for board ..."
    echo " "
    cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/configs/
    patch < ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/project/config.${HDL_PROJECT_NAME}.patch
    cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}
  elif [ -f ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/project/config.${PETALINUX_PROJECT_NAME} ] 
    then
    echo " "
    echo "Overwriting PetaLinux project config ..."
    echo " "
    cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/project/config.${HDL_PROJECT_NAME} \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/configs/config
  elif [ -f ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/project/config.generic ]
    then
    echo " "
    echo "WARNING: Using generic PetaLinux project config ..."
    echo " "
    cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/project/config.generic \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/configs/config    
  else
    echo " "
    echo "WARNING: No board specific PetaLinux project configuration files found, "
    echo "PetaLinux project config is not touched for this build ..."
    echo " "
  fi

  # Configure the root file system.
  petalinux_project_configure_rootfs

  # Configure the device-tree.
  petalinux_project_configure_devicetree

  # Configure the kernel.
  petalinux_project_configure_kernel

  # If the SD boot option is set, then perform the steps needed to  
  # build BOOT.BIN for booting from SD with the bistream loaded from 
  # the BOOT.BIN container image on the SD card.
  if [ "$BUILD_BOOT_SD_OPTION" == "yes" ]
  then
    # Modify the project configuration for sd boot.
    petalinux_project_set_boot_config_sd

    # Make sure that intermediary files get cleaned up.
    # petalinux-build -x distclean
    # Make sure that intermediary files get cleaned up.  This will also force
    # the rootfs to get rebuilt and generate a new image.ub file.
    petalinux-build -x mrproper

    # Build PetaLinux project.
    petalinux-build 

    # If the SD OOB boot option is set, then perform the steps needed to  
    # build BOOT.BIN for booting from SD without any bistream loaded from 
    # the BOOT.BIN container image on the SD card or from U-Boot during
    # second stage boot.
    if [ "$BUILD_BOOT_SD_OOB_OPTION" == "yes" ]
    then
      # Create boot image which does not contain the bistream image.
      petalinux-package --boot --fsbl images/linux/${FSBL_PROJECT_NAME}.elf --uboot --force

      # Copy the boot.bin file and name the new file BOOT_SD_OOB.BIN
      cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/BOOT.BIN \
      ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/BOOT_SD_OOB.bin
    fi

    # Create boot image which DOES contain the bistream image.
    petalinux-package --boot --fsbl images/linux/${FSBL_PROJECT_NAME}.elf --fpga hw_platform/system_wrapper.bit --uboot --force

    # Copy the boot.bin file and name the new file BOOT_SD.BIN
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/BOOT.BIN \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/BOOT_SD.bin
  fi
  
  # Change to HDL scripts folder.
  cd ${START_FOLDER}/${HDL_SCRIPTS_FOLDER}

  # Clean the hardware project output products using the HDL TCL scripts.
  echo "set argv [list board=${HDL_BOARD_NAME} project=${HDL_PROJECT_NAME} clean=yes jtag=yes version_override=yes]" > cleanup.tcl
  echo "set argc [llength \$argv]" >> cleanup.tcl
  echo "source ./make.tcl -notrace" >> cleanup.tcl

  # Launch vivado in batch mode to clean output products from the hardware platform.
  vivado -mode batch -source cleanup.tcl

  # Change to PetaLinux project folder.
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/

  # Package the bitstream within the PetaLinux pre-built folder.
  petalinux-package --prebuilt --fpga hw_platform/system_wrapper.bit

  # Rename the pre-built bitstream file to download.bit so that the default 
  # format for the petalinux-boot command over jtag will not need the bit file 
  # specified explicitly.
  mv -f pre-built/linux/implementation/system_wrapper.bit \
  pre-built/linux/implementation/download.bit

  # Change to PetaLinux projects folder.
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/

  # Copy the BOOT_SD.BIN to the pre-built images folder.
  cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/BOOT_SD.bin \
  ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/pre-built/linux/images/

  # Copy the image.ub to the pre-built images folder.
  cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/image.ub \
  ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/pre-built/linux/images/

  # Change to PetaLinux projects folder.
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/

  # Package the hardware source into a BSP package output.
  petalinux-package --bsp -p ${PETALINUX_PROJECT_NAME} \
  --hwsource ${START_FOLDER}/${HDL_PROJECTS_FOLDER}/${HDL_PROJECT_NAME}/${HDL_BOARD_NAME}/ \
  --output ${PETALINUX_PROJECT_NAME}

  # Change to PetaLinux scripts folder.
  cd ${START_FOLDER}/${PETALINUX_SCRIPTS_FOLDER}
}

# This function is responsible for first creating all of the hardware
# platforms needed for generating PetaLinux BSPs and once the hardware
# platforms are ready, they can be specificed in HDL_BOARD_NAME variable 
# before the call to create_petalinux_bsp.
#
# Once the PetaLinux BSP creation is complete, a BSP package file with the
# name specified in the PETALINUX_PROJECT_NAME variable can be distributed
# for use to others.
#
# NOTE:  If there is more than one hardware platform to be built, they will
#        all be built before any PetaLinux projects are created.  If you
#        are looking to save some time and only build for a specific target
#        be sure to comment out the other build targets in the 
#        make_<platform>.tcl hardware platform automation script AND comment
#        out the other BSP automated projects below otherwise, everything
#        will build which can take a very long time if you have multiple
#        hardware platforms and BSP projects defined.
main_make_function ()
{
  #
  # Create the hardware platforms for the supported targets.
  #

  # Change to HDL scripts folder.
  cd ${START_FOLDER}/${HDL_SCRIPTS_FOLDER}

  # Launch vivado in batch mode to build hardware platforms for target
  # boards.
  vivado -mode batch -source make_${HDL_PROJECT_NAME}.tcl

  #
  # Create the PetaLinux BSP for the UZ3EG_PCIEC target.
  #
  HDL_BOARD_NAME=UZ3EG_PCIEC
  PETALINUX_PROJECT_NAME=uz3eg_pciec_ccd_${PLNX_VER}
  create_petalinux_bsp

}

# First source any tools scripts to setup the environment needed to call both
# PetaLinux and Vivado from this make script.
source_tools_settings

# Call the main_make_function declared above to start building everything.
main_make_function


