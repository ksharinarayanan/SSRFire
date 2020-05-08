urls=$1
while IFS= read -r url
do	
	last=${url:${#url}-1:1}
	myserver=$2
	if [[ ${myserver:0:4} != "http" && ${myserver:0:4} != "FUZZ" ]]; then
		myserver="http://${myserver}"
	fi
	echo ${url%'='*${last}}=$myserver
done < "$urls"
