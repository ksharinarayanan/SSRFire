red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
cyan=`tput setaf 6`
reset=`tput sgr0`


read -p "${yellow}Do you want to install gau[y/n]:${reset} " input
if [[ $input == 'y' ]]; then
	echo "${cyan}Installing gau... ${reset}"
	mkdir tools
	cd tools
	git clone https://github.com/lc/gau.git
       	cd gau
	go build main.go
	chmod +x main
	cd ../..
	echo -e "gau(){
		tools/gau/./main \$1
	}" >> .profile
	echo -e "${green}Done${reset}\n"
fi

read -p "${yellow}Do you want to install ffuf[y/n]: ${reset}" input
if [[ $input == 'y' ]]; then
	echo "${cyan}Installing ffuf... ${reset}"
	if [ ! -d tools ]; then
		mkdir tools
	fi
	cd tools
	git clone https://github.com/ffuf/ffuf.git
	cd ffuf
	go build main.go help.go
	chmod +x main
	cd ../..
	echo -e "ffuf(){
		tools/ffuf/./main -u \$1 -w \$2 -c -t 50 
	}" >> .profile
	echo -e "${green}Done${reset}\n"
fi

read -p "${yellow}Do you want to install OpenRedireX[y/n]:  ${reset}" input
if [[ $input == 'y' ]]; then
	echo "${cyan}Installing OpenRedireX... ${reset}"
	if [ ! -d tools ]; then
		mkdir tools
	fi
	cd tools 
	git clone https://github.com/devanshbatham/OpenRedireX.git
	cd ..
	echo -e "openredirex(){
		python3 tools/OpenRedireX/openredirex.py -l \$1 -p \$2
	}" >> .profile
	echo -e "${green}Done${reset}\n"
fi
if [ -d tools ]; then
	source .profile
	echo "Your tools are installed under the tools directory"
fi
