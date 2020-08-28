# SSRFIRE
An automated [SSRF](https://en.wikipedia.org/wiki/Server-side_request_forgery) finder. Just give the domain name and your server and chill! ;)
It also has options to find XSS and open redirects.

![SSRFIRE](https://github.com/michaelben6/SSRFIRE/blob/master/static/ssrfire.png)

### Syntax
./ssrfire.sh -d domain.com -s yourserver.com -f custom_file.txt -c cookies


**domain.com**        --->  The domain for which you want to test

**yourserver.com**    --->  Your server which detects SSRF. Eg. Burp collaborator

**custom_file.txt**   --->  Optional argument. You give your own custom URLs instead of using gau

**cookies**           --->  Optional argument. To send requests as an authenticated user


If you don't have burpsuite professional, you can use [ssrftest.com](https://www.ssrftest.com) as your server.

### Requirements
Since this uses GAU, FFUF, qsreplace and OpenRedirex, you need GO and python 3.7+. You need not have the tools installed, as the script **setup.sh** would install everything.
You just need to install python and GO.
Even if you have the tools installed I would highly recommend you to install them again so that there no conflicts while setting the paths.

If you don't want to install the tools again, paste this code in your .profile in your home directory and source .profile them.
Also, you have to make a small change in the ssrfire.sh on line 10, where you have to replace source /home/hari/.profile without
your .profile path. **(Only if you are not installing tools through setup.sh)**
```
#Replace /path/to/ with the specific directory where the tool is installed
#If you already have configured paths for any of the tools, replace that code with the below one.
ffuf(){
        echo "Usage: ffuf https://www.domain.com/FUZZ payloads.txt"
        /path/to/ffuf/./main -u $1 -w $2 -b $3 -c -t 100
}

gau(){
        echo "Usage: gau domain.com"
        /path/to/gau/./main $1
}

gau_s(){
	/path/to/gau/./main --subs $1
}

openredirex(){
        echo "Usage: openredirex urls.txt payloads.txt"
        python3 /path/to/OpenRedireX/openredirex.py -l $1 -p $2 --keyword FUZZ
}
qsreplace(){
		/path/to/qsreplace/./main $1
}
```
## Usage
```
chmod +x setup.sh
./setup.sh (preferably yes for all ---> **highly recommended**)
./ssrfire.sh domain.com yourserver.com
```
### Finding SSRF
Now, gau gets into action by fetching all the URLs of the domain. This may take a lot of time.
You can check the output generated till now at output/domain.com/raw_urls.txt

Let it run for at least 10-15 minutes, and then if you want to continue, you can.
But if you want to test the URLs fetched till now, quit the process.
Copy the raw_urls.txt inside of output/domain.com and place it outside the domain.com folder
Now run
```
./ssrfire.sh domain.com yourserver.com /path/to/copied_raw_urls.txt
```
Select yes when asked whether to delete the existing folder.

This will skip the process of GAU fetching URLs.

Now the all the URLs with the parameters will be filtered and yourserver.com will be placed into their parameter values.(final_urls.txt)

The next step is to fire request to all the final URLs.

### Finding XSS

**Warning: This generates a lot of traffic. Do not use this against the sites which you are not authorised to test**

This tests all the URLs fetched, and based on how the input is reflected in the response, it adds that particular URL to the output/domain.com/xss-suspects.txt **(This may contain false positives)**

For further testing this, you can input this list to the XSS detection tools like XSStrike to find XSS.

### Finding open redirects

Just enter the path to a payload file or use the default payload.
I personally prefer openredirex, as it is specifically designed to check for open redirects by loading the URLs from the list
and it looks a lot cleaner, and doesn't flood your terminal.

## Tools used:

GAU - [https://github.com/lc/gau](https://github.com/lc/gau)

ffuf - [https://github.com/ffuf/ffuf](https://github.com/ffuf/ffuf)

qspreplace - [https://github.com/tomnomnom/qsreplace](https://github.com/tomnomnom/qsreplace)

OpenRedireX - [https://github.com/devanshbatham/OpenRedireX](https://github.com/devanshbatham/OpenRedireX)

Thanks to all the authors of the tools.

***

