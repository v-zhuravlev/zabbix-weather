# zabbix-weather
Collect weather conditions from openweathermap.org or weather.yandex.ru using host coordinates.  


## Get key  
### openweathermap  
http://openweathermap.org/appid  
### yandex weather 
https://tech.yandex.ru/weather/  
This is currently commercial service only, key is requested by email.  



## Dependencies  
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

2.1. If you need to use http proxy:  
Make sure that you have environment variables `http_proxy` and `https_proxy` defined under user `zabbix`  
For example:  
```
export http_proxy=http://proxy_ip:3129/
export https_proxy=$http_proxy  
./get_weather.pl -lat 55.672944 -lon 38.478944 --hostname TEST --api_key YOURKEY  
```


3.	Add global Macro
`{$WEATHER_APIKEY} = YOURKEY`  
![image](https://cloud.githubusercontent.com/assets/14870891/21132462/354687f6-c125-11e6-9995-256aac0ebd89.png)
add another global macro as prefered language for weather descriptions:  
`{$WEATHER_LANG} = en`  

4. Import example template  (or create own):  
Currently supported items:  

| Item       |       key |        OWM |     Yandex |  
|------------|-----------|------------|------------|  
| Temperature | temp | Y | Y |  
|Humidity|humidity|Y|Y|  
|Visibility|visibility|Y|Y|  
|Is dark|is_dark|Y|Y|  
|Wind speed|wind.speed|Y|Y|  
|Weather status|weather|Y|Y|  
|Weather description|weather.description|Y| |  
|Weather condition id |weather.condition.id|Y| |  

5. Setup host  
Add macros {$LAT} and {$LON} for each host that require weather monitoring:  
![image](https://cloud.githubusercontent.com/assets/14870891/21159303/c87f61a2-c191-11e6-8f49-638d877b06a6.png)

And that is it:  
![screencapture--1481663617632](https://cloud.githubusercontent.com/assets/14870891/21159567/c8e270de-c192-11e6-9452-cf1ed5251f60.png)


Note: It would more logical to use Latitue and Longitude Inventory fields and not user macros, but {INVENTORY.*} values cannot be used in items keys.  
A feature request to change that is here: https://support.zabbix.com/browse/ZBXNEXT-2546.


# TODO  
- Add error handling for zabbix_send  
