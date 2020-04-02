#!/bin/sh -xv

Persistence_init()
{
        PERSISTENCESTORE=/run/persistence
        mkdir -pv ${PERSISTENCESTORE}
        PART2=$(grep -m 1 findiso /proc/mounts | cut -f 1 -d ' ')
        DEV=$(readlink /sys/class/block/${PART2#/dev/})
        DEV=${DEV%/*}
        DEV=/dev/${DEV##*/}

        # is the persistence partition present ..
        if [ -b ${DEV}*3 ] && mount -v ${DEV}*3 ${PERSISTENCESTORE}
        then
                # .. but empty?
                if [ $(ls ${PERSISTENCESTORE} | wc -w) -eq 0 ]
                then
                        mkdir -pv ${PERSISTENCESTORE}/linux-userdata
                        mkdir -pv ${PERSISTENCESTORE}/linux-systemconfig
                        mkdir -pv ${PERSISTENCESTORE}/linux-systemdata
                        mkdir -pv ${PERSISTENCESTORE}/linux-system

                        # set up the exit trap to unmount theses bind-mounted persistence directories
                        trap "trap_umount_persistencedirs; trap_umount_partitions; trap_remove_mountsubdirs; trap_remove_mountdir" EXIT SIGHUP SIGQUIT SIGTERM

                        # home persistence
                        # TODO: f2fscrypt add_key -S 0x42
                        echo "/home bind,source=." > ${PERSISTENCESTORE}/linux-userdata/persistence.conf

                        # systemconfig persistence: network connections and printer configuration
                        echo "/etc/cups union,source=printer-configuration" > ${PERSISTENCESTORE}/linux-systemconfig/persistence.conf
                        echo "/etc/NetworkManager/system-connections union,source=network-connections" >> ${PERSISTENCESTORE}/linux-systemconfig/persistence.conf

                        # systemdata persistence: stuff
                        echo "/var/lib union,source=var-lib" > ${PERSISTENCESTORE}/linux-systemdata/persistence.conf
                        echo "/usr/src union,source=usr-src" >> ${PERSISTENCESTORE}/linux-systemdata/persistence.conf

                        # system persistence: to be !DELETED! before update
                        echo "/ union,source=rootfs" > ${PERSISTENCESTORE}/linux-system/persistence.conf

                        # binding etc gives full git ability from outside
                        # echo "/etc bind,source=etc" >> ${PERSISTENCESTORE}/linux-system/persistence.conf

                        # union mount for etc allows shipping hotfixes
                        echo "/etc union,source=etc" >> ${PERSISTENCESTORE}/linux-system/persistence.conf

                        echo "/var/lib/apt union,source=var-lib-apt" >> ${PERSISTENCESTORE}/linux-system/persistence.conf
                        echo "/var/lib/aptitude union,source=var-lib-aptitude" >> ${PERSISTENCESTORE}/linux-system/persistence.conf
                        echo "/var/lib/dlocate union,source=var-lib-dlocate" >> ${PERSISTENCESTORE}/linux-system/persistence.conf
                        echo "/var/lib/dpkg union,source=var-lib-dpkg" >> ${PERSISTENCESTORE}/linux-system/persistence.conf
                        echo "/var/lib/live union,source=var-lib-live" >> ${PERSISTENCESTORE}/linux-system/persistence.conf
                fi
                umount -v ${PERSISTENCESTORE}
        fi
        rmdir -v ${PERSISTENCESTORE}
}

Persistence_init
