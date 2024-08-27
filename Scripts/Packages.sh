#!/bin/bash
#安装和更新软件包

#删除自带软件包 （优先编译自带，所以需要删除才能升级）
rm -rf $(find ../feeds/luci/ -type d -regex ".*\(luci-lib-nixio\|luci-theme-argon\|luci-app-ssr-plus\|passwall\|aliyundrive-webdav\|openclash\|mosdns\|dockerman\|adguardhome\|alist\|luci-app-unblockneteasemusic\).*")
#删除自带核心packages 
rm -rf $(find ../feeds/packages/ -type d -regex ".*\(alist\|golang\|mosdns\|chinadns-ng\|sing-box\|xray-core\|v2ray-core\|v2ray-plugin\|v2ray-geodata\|aliyundrive-webdav\).*")

##git仓库  "$4"可拉仓库子目录
UPDATE_PACKAGE() {
  # 参数检查
  if [ "$#" -lt 1 ]; then
    echo "Usage: UPDATE_PACKAGE <git_url> [branch] [target_directory] [subdirectory]"
    return 1
  fi
  local git_url="$1"
  local branch="$2"
  local source_target_directory="$3"
  local target_directory="$3"
  local subdirectories="$4"
  # 输出参数日志
  echo "Git 仓库 URL: $git_url"
  echo "分支: $branch"
  echo "目标目录: $target_directory"
  echo "子目录: $subdirectories"
  
  # 自动补全 git_url 前缀
  if [[ ! "$git_url" =~ ^https:// ]]; then
    git_url="https://github.com/${git_url}.git"
  fi

  # 检测是否为 git 子目录
  if [ -n "$subdirectories" ]; then
    target_directory=$(pwd)/repos/$(echo "$git_url" | awk -F'/' '{print $(NF-1)"-"$NF}')
  fi

  # 检查目标目录是否存在
  if [ -d "$target_directory" ]; then
    pushd "$target_directory" || return 1
    git pull
    popd
  else
    if [ -n "$branch" ]; then
      git clone --depth=1 -b $branch $git_url $target_directory
    else
      git clone --depth=1 $git_url $target_directory
    fi
  fi

  # 检查 source_target_directory 是否存在
  if [ -n "$source_target_directory" ] && [ ! -d "$source_target_directory" ]; then
    mkdir -p "$source_target_directory"
    echo "创建目录 $source_target_directory"
  fi

  # 处理多个子目录
  if [ -n "$subdirectories" ]; then
    IFS=' ' read -r -a subdir_array <<< "$subdirectories"
    for subdir in "${subdir_array[@]}"; do
      cp -a $target_directory/$subdir ./$source_target_directory
      echo "复制 $subdir 到 $source_target_directory"
    done
    rm -rf $target_directory
    echo "删除repos目录"
  fi
}

# 用法示例  "https://github.com/xxx/yyy" "分支名" "目标目录" "git子目录 多目录空格隔开"
# UPDATE_PACKAGE "hanwckf/bl-mt798x" [branch] [target_directory] [subdirectory]
# UPDATE_PACKAGE "hanwckf/bl-mt798x" "main" "package/luci-xxx" "uboot-mtk-20220606 uboot-mtk-20230718-09eda825"
# UPDATE_PACKAGE "hanwckf/bl-mt798x" "" "package/luci-xxx" "uboot-mtk-20220606/xxx"
# UPDATE_PACKAGE "hanwckf/bl-mt798x"

  
# git拉取子目录
#svn export https://github.com/coolsnowwolf/luci/trunk/applications/luci-app-adblock ./feeds/luci/applications/luci-app-adblock
UPDATE_PACKAGE "messense/aliyundrive-webdav" "main" "" "openwrt/aliyundrive-webdav openwrt/luci-app-aliyundrive-webdav"
UPDATE_PACKAGE "immortalwrt/luci" "master" "" "libs/luci-lib-nixio"


# 正常git clone
#主题相关
UPDATE_PACKAGE "jerrykuku/luci-theme-argon" "master"
UPDATE_PACKAGE "0x676e67/luci-theme-design" "js"
UPDATE_PACKAGE "sirpdboy/luci-theme-kucat" "js"
UPDATE_PACKAGE "derisamedia/luci-theme-alpha" "master"
UPDATE_PACKAGE "animegasan/luci-app-alpha-config" "master"
#留学
UPDATE_PACKAGE "vernesong/OpenClash" "dev" "" "luci-app-openclash"
UPDATE_PACKAGE "xiaorouji/openwrt-passwall" "main"
UPDATE_PACKAGE "xiaorouji/openwrt-passwall-packages" "main"
#UPDATE_PACKAGE "fw876/helloworld" "master"
#其他插件
UPDATE_PACKAGE "sbwml/packages_lang_golang" "" "../feeds/packages/lang/golang"

UPDATE_PACKAGE "VIKINGYFY/luci-app-advancedplus" "main"
#UPDATE_PACKAGE "VIKINGYFY/luci-app-wolplus" "main"

UPDATE_PACKAGE "lwb1978/openwrt-gecoosac" "main"
UPDATE_PACKAGE "muink/luci-app-tinyfilemanager" "master"
UPDATE_PACKAGE "sbwml/luci-app-alist" "master"
UPDATE_PACKAGE "sbwml/luci-app-mosdns" "v5"
UPDATE_PACKAGE "chenmozhijin/luci-app-adguardhome" "master"
UPDATE_PACKAGE "lisaac/luci-app-dockerman" "master"
UPDATE_PACKAGE "gdy666/luci-app-lucky" "main"
UPDATE_PACKAGE "padavanonly/luci-app-mwan3helper-chinaroute" "main"
UPDATE_PACKAGE "tty228/luci-app-wechatpush" "master"
UPDATE_PACKAGE "UnblockNeteaseMusic/luci-app-unblockneteasemusic" "$([[ $REPO_URL == *"lede"* ]] && echo "master" || echo "js")"
UPDATE_PACKAGE "sirpdboy/netspeedtest" "master"

#更新软件包版本
UPDATE_VERSION() {
	local PKG_NAME=$1
	local PKG_MARK=${2:-not}
	local PKG_FILES=$(find ./ ../feeds/packages/ -maxdepth 3 -type f -wholename "*/$PKG_NAME/Makefile")

	echo " "

	if [ -z "$PKG_FILES" ]; then
		echo "$PKG_NAME not found!"
		return
	fi

	echo "$PKG_NAME version update has started!"

	for PKG_FILE in $PKG_FILES; do
		local PKG_REPO=$(grep -Pho 'PKG_SOURCE_URL:=https://.*github.com/\K[^/]+/[^/]+(?=.*)' $PKG_FILE | head -n 1)
		local PKG_VER=$(curl -sL "https://api.github.com/repos/$PKG_REPO/releases" | jq -r "map(select(.prerelease|$PKG_MARK)) | first | .tag_name")
		local NEW_VER=$(echo $PKG_VER | sed "s/.*v//g; s/_/./g")
		local NEW_HASH=$(curl -sL "https://codeload.github.com/$PKG_REPO/tar.gz/$PKG_VER" | sha256sum | cut -b -64)

		local OLD_VER=$(grep -Po "PKG_VERSION:=\K.*" "$PKG_FILE")

		echo "$OLD_VER $PKG_VER $NEW_VER $NEW_HASH"

		if [[ $NEW_VER =~ ^[0-9].* ]] && dpkg --compare-versions "$OLD_VER" lt "$NEW_VER"; then
			sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$NEW_VER/g" "$PKG_FILE"
			sed -i "s/PKG_HASH:=.*/PKG_HASH:=$NEW_HASH/g" "$PKG_FILE"
			echo "$PKG_FILE version has been updated!"
		else
			echo "$PKG_FILE version is already the latest!"
		fi
	done
}

#UPDATE_VERSION "软件包名" "测试版，true，可选，默认为否"
UPDATE_VERSION "sing-box" "true"
