#!/bin/bash

#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识   获取当前日期部分（例如 '24.10.20'）
WRT_DATE_ONLY=$(TZ=UTC-8 date +"%y.%m.%d")
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_DATE_ONLY')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")
#删除首页DDNS的示例，加快加载
sed -i '/myddns_ipv4/,$d' ./feeds/packages/net/ddns-scripts/files/etc/config/ddns
echo "删除DDNS示例!"

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE
#修改默认时区
sed -i "s/timezone='.*'/timezone='CST-8'/g" $CFG_FILE
sed -i "/timezone='.*'/a\\\t\t\set system.@system[-1].zonename='Asia/Shanghai'" $CFG_FILE

#配置文件修改
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
#echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config
#echo "CONFIG_MTK_MEMORY_SHRINK=$([[ $WRT_ADJUST == "true" ]] && echo "y" || echo "n")" >> ./.config
#echo "CONFIG_MTK_MEMORY_SHRINK_AGGRESS=$([[ $WRT_ADJUST == "true" ]] && echo "y" || echo "n")" >> ./.config
if [[ $WRT_ADJUST == "true" ]]; then
    echo "CONFIG_MTK_MEMORY_SHRINK=y" >> ./.config
    echo "CONFIG_MTK_MEMORY_SHRINK_AGGRESS=y" >> ./.config
    echo "CONFIG_MTK_MEMORY_SHRINK 和 CONFIG_MTK_MEMORY_SHRINK_AGGRESS 已启用"
else
    echo "CONFIG_MTK_MEMORY_SHRINK=n" >> ./.config
    echo "CONFIG_MTK_MEMORY_SHRINK_AGGRESS=n" >> ./.config
    echo "CONFIG_MTK_MEMORY_SHRINK 和 CONFIG_MTK_MEMORY_SHRINK_AGGRESS 已禁用"
fi

#修改默认WIFI名
#mtwifi-cfg
WIFI_FILE="./package/mtk/applications/mtwifi-cfg/files/mtwifi.sh"
sed -i "s/ssid=\"ImmortalWrt-2.4G\"/ssid=\"$WRT_WIFI\"/" $WIFI_FILE
echo "已将 2.4G Wi-Fi 名称修改为: $WRT_WIFI"
sed -i "s/ssid=\"ImmortalWrt-5G\"/ssid=\"$WRT_WIFI\_5G\"/" $WIFI_FILE
echo "已将 5G Wi-Fi 名称修改为: ${WRT_WIFI}_5G"
#mtk
sed -i "s/SSID1=MT7981_AX3000_2.4G/SSID1=$WRT_WIFI/" ./package/mtk/drivers/wifi-profile/files/mt7981/mt7981.dbdc.b0.dat
sed -i "s/SSID1=MT7981_AX3000_5G/SSID1=$WRT_WIFI\_5G/" ./package/mtk/drivers/wifi-profile/files/mt7981/mt7981.dbdc.b1.dat
sed -i "s/SSID1=MT7986_AX6000_2.4G/SSID1=$WRT_WIFI/" ./package/mtk/drivers/wifi-profile/files/mt7986/mt7986-ax6000.dbdc.b0.dat
sed -i "s/SSID1=MT7986_AX6000_5G/SSID1=$WRT_WIFI\_5G/" ./package/mtk/drivers/wifi-profile/files/mt7986/mt7986-ax6000.dbdc.b1.dat


#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo "$WRT_PACKAGE" >> ./.config
fi

#23.05专用
if [[ $WRT_BRANCH == *"23.05"* ]]; then
	#sed -i '/luci-app-openclash/d' ./.config
	sed -i '/luci-app-upnp/d' ./.config
	sed -i '/miniupnpd/d' ./.config

	#echo "CONFIG_PACKAGE_luci-app-openclash=n" >> ./.config
	echo "CONFIG_PACKAGE_luci-app-passwall=n" >> ./.config
	
        echo "CONFIG_PACKAGE_luci-app-upnp=n" >> ./.config
	echo "CONFIG_PACKAGE_miniupnpd=n" >> ./.config

	echo "CONFIG_PACKAGE_luci-app-homeproxy=y" >> ./.config
	echo "CONFIG_PACKAGE_luci-app-upnp-mtk-adjust=y" >> ./.config
fi

#修改Tiny Filemanager汉化
if [ -d "./package/luci-app-tinyfilemanager" ]; then
	PO_FILE="./package/luci-app-tinyfilemanager/po/zh_Hans/tinyfilemanager.po"	
	sed -i '/msgid "Tiny File Manager"/{n; s/msgstr.*/msgstr "文件管理器"/}' "$PO_FILE"
	sed -i 's/启用用户验证/用户验证/g;s/家目录/初始目录/g;s/Favicon 路径/收藏夹图标路径/g;s/存储//g' "$PO_FILE"	
	echo "修改Tiny Filemanager汉化!"
fi
#修改wolplus汉化
if [ -d "./package/luci-app-wolplus" ]; then
	PO_FILE="./package/luci-app-wolplus/po/zh_Hans/wolplus.po"
        sed -i '/msgid "Wake on LAN +"/{n;s/msgstr ""/msgstr "网络唤醒+"/}' "$PO_FILE"
	echo "修改wolplus汉化!"
fi
