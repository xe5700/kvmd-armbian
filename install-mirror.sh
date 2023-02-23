# Github 增强加速脚本
# 加速地址参考github 增强加速下载脚本
# Created by xe5700
# @namespace    https://greasyfork.org/scripts/412245
# @supportURL   https://github.com/XIU2/UserScript
# @homepageURL  https://github.com/XIU2/UserScript
url_clone="";

url_raw="";
url_raw2="";

clone_mirror(){
	printf "Choose github clone mirror\n
	0. github.com [Orginal]
	1. hub.fastgit.org [China Hong Kong] \n
	2. gitclone.com [China Zhe Jiang] \n
	3. github.com.cnpmjs.org [Singapore]\n
	4. kgithub.com \n
	5. hub.njuu.cf \n
	6. hub.yzuu.cf \n
	"
	tryagain=1
	while [ $tryagain -eq 1 ]; do
		read -p "Please type [0-3]: " capture
		case $capture in 
		0) url_clone="https:\\/\\/github.com\\/"; tryagain=0;;
		1) url_clone="https:\\/\\/hub.fastgit.org\\/"; tryagain=0;;
		2) url_clone="https:\\/\\/gitclone.com\\/github.com\\/"; tryagain=0;;
		3) url_clone="https:\\/\\/github.com.cnpmjs.org\\/"; tryagain=0;;
		4) url_clone="https:\\/\\/kgithub.com\\/"; tryagin=0;;
		5) url_clone="https:\\/\\/hub.njuu.cf\\/"; tryagin=0;;
		6) url_clone="https:\\/\\/hub.yzuu.cf\\/"; tryagin=0;;
		*) printf "\nTry again.\n"; tryagain=1;;
		esac
		echo
		echo "Github clone URL -> $url_clone"
		echo
	done
}

raw_mirror(){
	printf "Choose github raw mirror\n
	0. https://raw.githubusercontent.com [Orginal]
	1. https://raw.fastgit.org [China Hong Kong]
	2. https://cdn.staticaly.com [Global]
	3. https://ghproxy.com [South Korea]
	"

	#1. https://cdn.jsdelivr.net [Global]
	tryagain=1
	while [ $tryagain -eq 1 ]; do
		read -p "Please type [0-3]: " capture
		case $capture in 
		0) url_raw="https:\\/\\/raw.githubusercontent.com\\/";url_raw2="https://raw.githubusercontent.com/"; tryagain=0;;
		1) url_raw="https:\\/\\/raw.fastgit.org\\/";url_raw2="https://raw.fastgit.org/"; tryagain=0;;
		2) url_raw="https:\\/\\/cdn.staticaly.com\\/gh\\/";url_raw2="https://cdn.staticaly.com/gh/"; tryagain=0;;
		3) url_raw="https:\\/\\/ghproxy.com\\/https:\\/\\/raw.githubusercontent.com\\/";url_raw2="https://ghproxy.com/https://raw.githubusercontent.com/"; tryagain=0;;
		*) printf "\nTry again.\n"; tryagain=1;;
		esac
		echo
		echo "Github raw URL -> $url_raw"
		echo
	done
}

clone_mirror
raw_mirror

appPath=$(dirname $0)

cd $appPath

cat install.sh | sed "s/https:\\/\\/raw.githubusercontent.com\\//$url_raw/" | sed "s/https:\\/\\/github.com\\//$url_clone/" | tee .tmp.kvmd-install.sh > /dev/null
chmod +x .tmp.kvmd-install.sh
./.tmp.kvmd-install.sh
rm -f .tmp.kvmd-install.sh