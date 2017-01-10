#!/usr/bin/env bash
# Generates random locally administred MAC address
# Credits:
# http://serverfault.com/questions/40712/what-range-of-mac-addresses-can-i-safely-use-for-my-virtual-machines?answertab=active#tab-top

x=$(echo $RANDOM|md5sum);echo 02${x:0:10}

