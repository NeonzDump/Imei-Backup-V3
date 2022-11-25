#!/sbin/sh
########################## Script part start ##########################
# Mount system
mount -o rw /system_root
rm -rf /sdcard/imeibackup /sdcard/imeibackup.zip /sdcard/Flashable-IMEI-Backup*.zip
mkdir -p /sdcard/imeibackup/META-INF/com/google/android

# Get codename from build.prop
if [[ $(ls /dev/block | grep mapper) ]] ; then SYSTEM_BUILD_PROP=/system_root/system/build.prop && SYSTEM_LOCATION=/system_root/system/ ; else SYSTEM_BUILD_PROP=/system/system/build.prop && SYSTEM_LOCATION=/system/system/ ; fi
DEVICE_NAME=$(grep ro.product.system.device $SYSTEM_BUILD_PROP) && DEVICE_NAME=${DEVICE_NAME#*=} # Unable to get the prop directly so fetch from build.prop instead
DATE1=$(date +%Y%m%d)  # Append date for easier reference
DATE=$(date)

# MTK OR QUALCOMM(?)
if [[ $(ls /dev/block/by-name | grep nvram) ]] ; then IS_MTK=true ; else IS_MTK=false ; fi

########################## Assert part start ##########################
# Assert to prevent flashing wrong IMEI (Incase you're dumb?)
echo "assert(getprop(\"ro.product.system.device\") == \"$DEVICE_NAME\" || getprop(\"ro.product.system.device\") == \"$DEVICE_NAME\" || abort(\"E3004: This package is for device: $DEVICE_NAME; this device is \" + getprop(\"ro.product.system.device\") + \".\"););" >> /sdcard/imeibackup/META-INF/com/google/android/updater-script
echo 'ui_print (" ");
ui_print (" ");
ui_print (" Imei Backup Script (via Recovery) for both Qualcomm and MediaTek");
ui_print (" ");
ui_print (" ");
ui_print (" Flashing Partitions .... ");
ui_print (" ");
ui_print (" ");' >> /sdcard/imeibackup/META-INF/com/google/android/updater-script

if [ "$IS_MTK" == true ] ; then echo "ui_print (\" Target CPU: MediaTek\");" >> /sdcard/imeibackup/META-INF/com/google/android/updater-script && echo "ui_print (\" Target device: $DEVICE_NAME\");" >> /sdcard/imeibackup/META-INF/com/google/android/updater-script ; elif [ "$IS_MTK" == false ] ; then echo "ui_print (\" Target CPU: Qualcomm\");" >> /sdcard/imeibackup/META-INF/com/google/android/updater-script && echo "ui_print (\" Target device: $DEVICE_NAME\");" >> /sdcard/imeibackup/META-INF/com/google/android/updater-script ; fi
echo "ui_print (\" Backup date: $DATE\");" >> /sdcard/imeibackup/META-INF/com/google/android/updater-script

if [ "$IS_MTK" == false ]
then
    echo 'package_extract_file("persist.bin", "/dev/block/by-name/persist");
package_extract_file("modem.img", "/dev/block/by-name/modem");
package_extract_file("bluetooth.img", "/dev/block/by-name/bluetooth");
package_extract_file("dsp.img", "/dev/block/by-name/dsp");
package_extract_file("modemst1.img", "/dev/block/by-name/modemst1");
package_extract_file("modemst2.img", "/dev/block/by-name/modemst2");
package_extract_file("fsc.img", "/dev/block/by-name/fsc");
package_extract_file("fsg.img", "/dev/block/by-name/fsg");
package_extract_file("sec.img", "/dev/block/by-name/sec");' >> /sdcard/imeibackup/META-INF/com/google/android/updater-script
elif [ "$IS_MTK" == true ]
then
    echo 'package_extract_file("nvram.bin", "/dev/block/by-name/nvram");
package_extract_file("nvdata.img", "/dev/block/by-name/nvdata");
package_extract_file("persist.img", "/dev/block/by-name/persist");
package_extract_file("protect1.img", "/dev/block/by-name/protect1");
package_extract_file("protect2.img", "/dev/block/by-name/protect2");
package_extract_file("nvcfg.img", "/dev/block/by-name/nvcfg");' >> /sdcard/imeibackup/META-INF/com/google/android/updater-script
fi

echo 'ui_print (" ");
ui_print (" Flashed all partitions! ");
ui_print (" Your IMEI should hopefully be restored :)");
ui_print (" ");
ui_print (" ");' >> /sdcard/imeibackup/META-INF/com/google/android/updater-script

cp /tmp/update-binary /sdcard/imeibackup/META-INF/com/google/android
########################## Assert part end ##########################

########################## Backup part start ##########################
if [ "$IS_MTK" == false ]
then
    for part in fsg fsc modemst1 modemst2 dsp bluetooth modem persist sec; do dd if=/dev/block/by-name/$part of=/sdcard/imeibackup/${part}.img; done
    NAME_OF_ZIP="$DEVICE_NAME"-Flashable-IMEI-Backup-Qualcomm-"$DATE1".zip
elif [ "$IS_MTK" == true ]
then
    # IMG or bin doesnt matter, however in SP Flash tool its mentioned as .bin, so for users convienence (incase unable to flash recovery zip)
    for part in nvcfg nvdata persist protect1 protect2; do dd if=/dev/block/platform/bootdevice/by-name/$part of=/sdcard/imeibackup/${part}.img; done
    for part in seccfg nvram; do dd if=/dev/block/platform/bootdevice/by-name/$part of=/sdcard/imeibackup/${part}.bin; done
    NAME_OF_ZIP="$DEVICE_NAME"-Flashable-IMEI-Backup-MediaTek-"$DATE1".zip
fi
########################## Backup part end ##########################

cd /sdcard/imeibackup
zip -r $NAME_OF_ZIP *
rm -rf META-INF
cd -
cp /sdcard/imeibackup/$NAME_OF_ZIP /sdcard
########################## Script part end ##########################