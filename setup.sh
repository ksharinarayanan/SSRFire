red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
cyan=`tput setaf 6`
reset=`tput sgr0`

chmod +x ssrfire.sh
if [ ! -d output ]; then
	mkdir output
fi

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
	}
	gau_s(){
		tools/gau/./main --subs \$1
	}
	" >> .profile
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
		tools/ffuf/./main -u \$1 -w \$2 -c -t 100 
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

read -p "${yellow}Do want to install qsreplace[y/n]: ${reset}" input
if [[ $input == 'y' ]]; then
	echo "${cyan}Installing qsreplace...${reset}"
	if [ ! -d tools ]; then
		mkdir tools
	fi
	cd tools 
	git clone https://github.com/tomnomnom/qsreplace
	cd qsreplace
	go build main.go
	cd ../..
	echo -e "qsreplace(){
		tools/qsreplace/./main \$1
	}" >> .profile
	echo -e "${green}Done${reset}\n"
fi
if [ -d tools ]; then
	source .profile
	echo "Your tools are installed under the tools directory"
	echo "${green}All set. Now just run SSRFire!${reset}"
else
	echo "${red}Make sure that you edit the 10th line in the ssrfire.sh file. Refer the github README for more details.${reset}"
fi
