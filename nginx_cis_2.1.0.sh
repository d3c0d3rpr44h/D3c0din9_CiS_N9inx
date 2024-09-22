#!/bin/bash

#This Script audits your Nginx server configuration against CIS Security Benchmark 2.1.0 released 06-28-2024. 

#Use Bash shell with sudo rights to execute.

#This script is to be used if Nginx is running on - Ubuntu OS

#CIS Benchmark Details: https://downloads.cisecurity.org/#/

#x.x.x - shows the section number along with the benchmark check


echo -ne "\n########## Running the NGINX CIS Checker ##########"

#Check admin rights for script execution

checkid() {
echo -e "\n\n##### Checking admin execution rights for NGINX CIS checker #####"
if [[ "${UID}" -ne 0 ]]
then
	echo "FAILURE\nPlease use sudo for script execution"
	exit 1
else
	echo -ne "SUCCESS"
fi
}
checkid

#Check if OS is Ubuntu based
echo -e "\n\n##### Checking if OS is Ubuntu #####"
checkos() {
OS=$(cat /etc/*release | grep -w NAME | cut -d = -f2 | tr -d '""')
if [[ (! "${OS}" == 'Ubuntu') && (! "${OS}" == 'ubuntu') && (! "${OS}" == 'UBUNTU') ]]
then
	echo -e "FAILURE\nThe base OS for this Nginx image is not Ubuntu. Please use appropriate script"
	exit 1
else
	echo -e "SUCCESS"
fi
}
checkos

echo -e "\n##### Analyzing the Server for CIS Benchmarks ######"
pass=0
fail=0

passed() {
((++pass))
}

failed() {
((++fail))
}

#1.1.1- Ensure NGINX is installed (Automated)
echo -e "\nCIS 1.1.1 - Ensure NGINX is installed (Automated)"
nginx -v 
echo -n "$version"
if  [[ "${?}" -ne 0 ]]
then
	echo -e "FAILURE\nNginx IS NOT installed on this server"
	failed
	exit 1
else
	echo -e "SUCCESS\nNginx IS installed"
	passed
fi

#1.1.2 Ensure NGINX is installed from source (Manual)

#1.2.1 Ensure package manager repositories are properly configured (Manual)

#1.2.2 Ensure the latest software package is installed (Manual)

#2.1.1 Ensure only required modules are installed (Manual)

#2.1.2 Ensure HTTP WebDAV module is not installed (Automated)
echo -e "\nCIS 2.1.2 - Ensure HTTP WebDAV module is not installed (Automated)"
nginx -V 2>&1 | grep http_dav_module > /dev/null
if  [[ "${?}" -ne 0 ]]
then
        echo -e "SUCCESS\nhttp_dav_module IS NOT installed on this server"
        passed
else
        echo -e "FAILURE\nhttp_dav_module IS installed on this server"
        failed
	echo -e "Remediation: NGINX does not support the removal of modules using the dnf method of installation. In order to remove modules from NGINX, you will need to compile NGINX from source. References: 1. http://nginx.org/en/docs/configure.html 2. https://tools.ietf.org/html/rfc4918"
fi

#2.1.3 Ensure modules with gzip functionality are disabled (Automated)
echo -e "\nCIS 2.1.3 - Ensure modules with gzip functionality are disabled (Automated)"
nginx -V 2>&1 | grep -E '(http_gzip_module|http_gzip_static_module)' > /dev/null
if  [[ "${?}" -ne 0 ]]
then
        echo -e "SUCCESS\n GZIP IS NOT installed on this server"
        passed
else
        echo -e "FAILURE\nGZIP IS installed on this server"
        failed
        echo -e "Remediation: In order to disable the http_gzip_module and the http_gzip_static_module, NGINX must be recompiled from source. This can be accomplished using the below command in the folder you used during your original compilation. This must be done without the --withhttp_gzip_static_module or --with-http_gzip_module configuration directives. ./configure --without-http_gzip_module --without-http_gzip_static_module. Default Value: The http_gzip_module is enabled by default in the source build, and the http_gzip_static_module is not. Only the http_gzip_static_module is enabled by default in the dnf package. References: 1. http://nginx.org/en/docs/configure.html 2. http://nginx.org/en/docs/configure.html 3. http://nginx.org/en/docs/http/ngx_http_gzip_module.html 4. http://nginx.org/en/docs/http/ngx_http_gzip_static_module.html"
fi


#2.1.4 Ensure the autoindex module is disabled (Automated)
echo -e "\nCIS 2.1.4 - Ensure the autoindex module is disabled (Automated)"
egrep -i '^\s*autoindex\s+' /etc/nginx/nginx.conf
egrep -i '^\s*autoindex\s+' /etc/nginx/conf.d/* 

#Verify nginx is being run as a dedicated user
grep -Pi -- '^\h*user\h+[^;\n\r]+\h*;.*$' /etc/nginx/nginx.conf

#Verify the nginx dedicated user is not privileged
sudo -l -U nginx

#Verify the nginx dedicated user is not part of any unexpected groups
groups nginx

#Verify the nginx service account is locked
passwd -S "$(awk '$1~/^\s*user\s*$/ {print $2}' /etc/nginx/nginx.conf | sed -
r 's/;.*//g')"

#To verify the nginx service account has an invalid shell

#To verify the ownership of the nginx configuration files
stat /etc/nginx

#To verify the nginx directory has other write permissions revoked
find /etc/nginx -type d -exec stat -Lc "%n %a" {} +

#To verify the nginx configuration files have other read, write and execute permissions revoked
find /etc/nginx -type f -exec stat -Lc "%n %a" {} +

#To verify the ownership and permissions of the nginx PID file
stat -L -c "%U:%G" /var/run/nginx.pid && stat -L -c "%a" /var/run/nginx.pid

#To verify the core dump configuration is secured
grep working_directory /etc/nginx/nginx.conf

#To audit all listening ports on the server:
grep -ir "listen[^;]*;" /etc/nginx

#To check which files are included in the nginx configuration file
grep include /etc/nginx/nginx.conf

#To verify host config
curl -k -v https://127.0.0.1 -H 'Host: invalid.host.com'

#To check the current setting for the keepalive_timeout directive
grep -ir keepalive_timeout /etc/nginx

#To check the current setting for the send_timeout directive
grep -ir send_timeout /etc/nginx

#verify the server_tokens directive is set to off
curl -I 127.0.0.1 | grep -i server

#To Locate the error page and index directives in the location block of your server config
grep -i nginx /usr/share/nginx/html/index.html
grep -i nginx /usr/share/nginx/html/50x.html

#To verify hidden files are disabled
grep location /etc/nginx/nginx.conf

#To Confirm that the headers are denied as part of the location block of the nginx config
grep proxy_hide_header /etc/nginx/nginx.conf

#To Verify your log format meets standards

#To verify access logging is enabled
grep -ir access_log /etc/nginx

#To verify the error logging configuration
grep error_log /etc/nginx/nginx.conf

#To verify the log rotation configuration
cat /etc/logrotate.d/nginx | grep weekly
cat /etc/logrotate.d/nginx | grep rotate

#To verify your server is configured for central logging
grep -ir syslog /etc/nginx


#to ensure the client IP address is passed to the endpoint the proxy is serving traffic to
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

#To verify your server listening configuration

#To find the file location of your certificate
grep -ir ssl_certificate /etc/nginx/

#To Verify the permissions on the key file are 400
find /etc/nginx/ -name '*.key' -exec stat -Lc "%n %a" {} +

#To verify which SSL/TLS protocols
grep -ir ssl_protocol /etc/nginx

#To verify the ssl_cipher and proxy_ssl_cipher directives meet standards
grep -ir ssl_ciphers /etc/nginx/
grep -ir proxy_ssl_ciphers /etc/nginx

#To Verify the option ssl_dhparam is explicitly provided
grep ssl_dhparam /etc/nginx/nginx.conf

#To verify OCSP stapling is enabled
grep -ir ssl_stapling /etc/nginx

#To check for HSTS headers
grep -ir Strict-Transport-Security /etc/nginx

#To Verify upstream server traffic is authenticated with a client certificate
grep -ir proxy_ssl_certificate /etc/nginx

#To Ensure the upstream traffic server certificate is trusted
grep -ir proxy_ssl_trusted_certificate /etc/nginx
grep -ir proxy_ssl_verify /etc/nginx


#To Ensure your domain is preloaded

#4.1.12 Ensure session resumption is disabled to enable perfect forward security
grep -ir ssl_session_tickets /etc/nginx

#4.1.13 Ensure HTTP/2.0 is used
grep -ir http2 /etc/nginx

#4.1.14 Ensure only Perfect Forward Secrecy Ciphers are Leveraged
grep -ir ssl_ciphers /etc/nginx/
grep -ir proxy_ssl_ciphers /etc/nginx

#5.1.1 Ensure allow and deny filters limit access to specific IP addresses

#5.1.2 Ensure only approved HTTP methods are allowed
curl -X DELETE http://localhost/index.html
curl -X GET http://localhost/index.html

#5.2.1 Ensure timeout values for reading the client header and body are set correctly
grep -ir timeout /etc/nginx

#5.2.2 Ensure the maximum request body size is set correctly
grep -ir client_max_body_size /etc/nginx

#5.2.3 Ensure the maximum buffer size for URIs is defined
grep -ir large_client_header_buffers /etc/nginx/

#5.2.4 Ensure the number of connections per IP address is limited
#5.2.5 Ensure rate limits by IP address are set

#5.3.1 Ensure X-Frame-Options header is configured and enabled
grep -ir X-Frame-Options /etc/nginx

#5.3.2 Ensure X-Content-Type-Options header is configured and enabled
grep -ir X-Content-Type-Options /etc/nginx

#5.3.3 Ensure that Content Security Policy (CSP) is enabled and configured properly
grep -ir Content-Security-Policy /etc/nginx

#5.3.4 Ensure the Referrer Policy is enabled and configured properly
grep -r Referrer-Policy /etc/nginx


