# zabbix-weather
Collect weather conditions from openweathermap.org or weather.yandex.ru using host coordinates


## Get key  
### openweathermap  
http://openweathermap.org/appid  
### yandex weather 
This is currently commercial service only, key is requested by email.  



##Dependencies  

The script is written in Perl and you will need common modules in order to run it:  
```
LWP
JSON::XS
```
There are numerous ways to install them:  

| in Debian  | In Centos | using CPAN | using cpanm|  
|------------|-----------|------------|------------|  
|  `apt-get install libwww-perl libjson-xs-perl` | `yum install perl-JSON-XS perl-libwww-perl perl-LWP-Protocol-https` | `PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install Bundle::LWP'` and  `PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install JSON::XS`| `cpanm install LWP` and `cpanm install JSON::XS`| 

## Setup
1. place get_weather.pl into externalscripts folder  
then:  
`chmod +x get_weather.pl`  
`chown zabbix:zabbix get_weather.pl`  
2. Check that it is working  
`./get_weather.pl -lat 55.672944 -lon 38.478944 --hostname TEST --api_key YOURKEY`  
You should receive `OK` as script output.  

3.	Add global Macro
`{$WEATHER_APIKEY} = YOURKEY`  
![image](https://cloud.githubusercontent.com/assets/14870891/21132462/354687f6-c125-11e6-9995-256aac0ebd89.png)


4. Import example template  (or create own)  


# TODO  
- Add error handling for zabbix_send  
