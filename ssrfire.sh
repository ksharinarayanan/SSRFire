usage(){
	echo "Usage: ./find.sh -d domain.com -s yourserver.com -f custom_file.txt -c cookies"
	echo "domain.com        --- The domain for which you want to test"
	echo "yourserver.com    --- Your server which detects SSRF. Eg. Burp colloborator"
	echo "custom_file.txt   --- Optional argument. You give your own custom URLs instead of using gau"
	echo "cookies           --- Optional argument. To send requests as an authenticated user"
}
if [ -f .profile ]; then
	source .profile
elif [ -f ${HOME}/.profile ]; then
	source ${HOME}/.profile
	#Enter your .profile location if you haven't installed the tools through setup.sh
	#If installed through setup.sh, no changes are required
fi
black=`tput setaf 0`
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

cookie=""
domain=""
server=""
file=""
while getopts "d:s:c:f:" opt
do
	case "${opt}" in 
		d) 
			domain="${OPTARG}"
			;;
		s)
			server="${OPTARG}"
			;;
		c) 
			cookie="${OPTARG}" 
			;;
		f)
			file="${OPTARG}"
			;;
	esac
done
#echo "The value of cookies is ${cookie}"

if [[ $domain == "" ]]; then
	echo "${red}Please specify the domain name${reset}"
	usage
	exit 2
elif [[ $server == "" ]]; then
	echo "${red}Please specify the server name. Eg. Burp colloborator/ your instance of ssrftest.com${reset}"
	usage
	exit 2
fi

if [[ $file != "" ]]; then
	if [ ! -f $file ]; then
		echo "${red}The given file does not exist${reset}"
		exit 2
	fi
fi

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

echo -e "\n${yellow}Important note: This works only if you have ffuf, gau and qsreplace installed and have set their paths accordingly. If you want to check for open redirects using openredirex, you must have openredirex too.(Run setup.sh to and install all the tools to do that automatically)\n ${reset}"
mkdir output/$domain

if [[ $file == "" ]]; then
	read -p "Do want to check the subdomains too?[y/n]: " sub
	echo "${cyan}Fetching URLs using GAU (This may take some time depending on the domain. You can check the output generated till now at output/$domain/raw_urls.txt)"
	echo -e "\n${yellow}If you don't want to wait, and want to test for the output generated till now.\n1. Exit this process\n2. Copy the output/$domain/raw_urls.txt to some other location outside of $domain folder\n3. Supply the file location as the third argument.\nEg ./ssrfx.sh domain.com server.com path/to/raw_urls.txt"
	if [[ $sub == 'y' || $sub == 'Y' ]]; then
		gau_s $domain > output/$domain/raw_urls.txt
	else 
		gau $domain > output/$domain/raw_urls.txt
	fi

	echo -e "${green}Done${reset}\n"
else 
	cat $file > output/$domain/raw_urls.txt
fi

echo "${cyan}Sorting out the URLs with parameters and replacing the parameter's original value with your server${reset}"

if [[ ${server:0:4} != "http" ]]; then
	server="http://${server}"
fi

uniq output/$domain/raw_urls.txt | grep "?" | sort | qsreplace ""  > output/$domain/temp-parameterised_urls.txt
cat output/$domain/temp-parameterised_urls.txt | grep "=" >> output/$domain/parameterised_urls.txt
rm output/$domain/temp-parameterised_urls.txt

while IFS= read -r url; do
	if [[ $(echo $server | grep "burp") != "" ]]; then  
		rs="${server}/${url}"
	else
		rs="${server}"
	fi
	echo $url | qsreplace $rs | grep '=' >> output/$domain/final_urls.txt
done < output/$domain/parameterised_urls.txt

echo -e "${green}Done${reset}\n"

total_urls=$(grep "" -c output/$domain/final_urls.txt)
echo -e "${green}The final URL list is at output/$domain/final_urls.txt${reset}\n"
echo "${yellow}Total URLs fetched with parameters: ${total_urls}${reset}"

read -p "${magenta}Do you want to check for SSRF: [y/n] ${reset}" input

if [[ $input == 'y' ]]; then
	echo -e "\n${cyan}Firing requests, check your server for any traffic!${reset}"

	ffuf FUZZ output/$domain/final_urls.txt $cookie > output/$domain/temp.txt
	rm output/$domain/temp.txt

	echo "${green}Done!${reset}"
fi

echo -e "${red}\nWARNING: Testing for XSS generates a lot of noise. You must test only those sites on which you are authorised to.${reset}"
read -p "${magenta}Do you want to check for XSS: [y/n] ${reset}" input

if [[ $input == 'y' ]]; then
	echo -e "\n${red}You should not blindly trust the results. There may be a lot of false positives.${reset}\n"
	echo -e "\n${yellow}Ignore the output below, if there are any suspects, the final list of suspected URLs will be at output/$domain/xss-suspects.txt${reset}\n"
	count=0
	while IFS= read -r url; do
		 echo $url | qsreplace "michaelben<>" > output/$domain/temp.txt
		 rm output/$domain/temp.txt
		 if [[ $cookie != "" ]]; then
			 if [[ $(curl --silent --cookie $cookie $url | grep "michaelben<>" ) != '' ]]; then
				echo $url >> output/$domain/xss-suspects.txt
			 fi
		 else
			 if [[ $(curl --silent $url | grep "${server}<>") != '' ]]; then
				 echo $url >> output/$domain/xss-suspects.txt
			 fi
		 fi
		 count=$((count+1))
		 echo "${cyan}Progress: ${count}/${total_urls} URLs${reset}"
	done < output/$domain/parameterised_urls.txt
	echo "${reset}"
	if [[ -f output/$domain/xss-suspects.txt ]]; then
		echo -e "\n${red}Number of suspected URLs: $(grep "" -c output/$domain/xss-suspects.txt)\n"
		echo "${green}The suspected URLs are stored in output/$domain/xss-suspects.txt${reset}"
	else
		echo "${yellow}No reflections found! :( ${reset}"
	fi

fi

read -p "${magenta}Do you want to check for open redirects?[y/any other character]${reset}" input
if [[ $input == 'y' ]]; then
	cat output/$domain/final_urls.txt | qsreplace "FUZZ" > output/$domain/fuzz.txt
	cat output/$domain/fuzz.txt | grep "FUZZ" > output/$domain/fuzz_urls.txt
	
	read -p "Enter the payload file location:[Press ENTER if you want to use the default]" payload
	if [[ $payload == "" ]]; then
		payload="payloads.txt"
	fi
		
	openredirex output/$domain/fuzz_urls.txt $payload

else
	exit 2
fi

