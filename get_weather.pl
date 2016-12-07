#!/usr/bin/perl
my $VERSION = 0.01;
use strict;
use warnings; 

use JSON::XS;
use LWP;
use Data::Dumper;
use English '-no_match_vars';
use IO::Socket::INET;
use MIME::Base64 qw(encode_base64);
use Getopt::Long;
use LWP::Protocol::https;

use Encode;
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");


use constant {
    TIMEOUT   => 10,
};


my $api_key = 'key_here';

my $lat;# = '59.3969625';
my $lon;# = '55.672944';
my $debug=0;
#zabbix server
my $zabbixserver = '127.0.0.1';
my $hostname;#     = "CCK_LOCAL";
my $lang = 'ru';

GetOptions(
    "api_key=s" =>  \$api_key,
    "debug!"       => \$debug,
    "lat=f"     => \$lat,
    "lon=f" => \$lon,
    "zabbixserver=s" => \$zabbixserver,
    "hostname=s" => \$hostname,
    "lang=s" => \$lang,
) or die("Error in command line arguments\n");


die "Please provide --lat and --lon\n" unless ($lat and $lon);
die "Please provide --hostname for zabbix_send\n" unless ($hostname);


openweather();
#yandexweather();
print "OK\n";


sub openweather {
    
    my $url = URI->new('http://api.openweathermap.org/data/2.5/weather');

    $url->query_form(
        'units'     => 'metric',
        'lat'       => $lat,
        'lon'       => $lon,
        'APPID'     => $api_key,
        'lang'      => $lang
    );    
    
    my $resp = get_with_retries($url);
    
    
    my $td; #key-values for zabbix_sender
    my $time = time;

    $td->{temp}=$resp->{main}->{temp};
    $td->{humidity}=$resp->{main}->{humidity};
    if (defined $resp->{visibility}) {$td->{visibility}=$resp->{visibility}};
    
    if (defined $resp->{sys}->{sunrise} and defined $resp->{sys}->{sunset}) {
        if ($time > $resp->{sys}->{sunrise} and $time < $resp->{sys}->{sunset})
        {
            $td->{is_dark}=0;  #DAY
        }
        else {
            $td->{is_dark}=1;  #"NIGHT";
        }
    }
    $td->{'wind.speed'} = $resp->{wind}->{speed};

    $td->{'weather'} = $resp ->{weather}->[0]->{main};
    $td->{'weather.description'} = $resp ->{weather}->[0]->{description};

    foreach my $key (keys %{ $td }) {
        print $key." " if $debug;
        print $td->{$key}."\n" if $debug;
        zabbix_send( $zabbixserver, $hostname, $key, $td->{$key} );
    }

}


sub yandexweather {
    
    my $url = URI->new('https://api.weather.yandex.ru/v1/forecast');
    #add yandex key!
    $url->query_form(
        'lat'       => $lat,
        'lon'       => $lon,
        'l10n'      => 'true'
    );  
    my $resp = get_with_retries($url);
    

    my $td; #key-values for zabbix_sender

    $td->{temp}=$resp->{fact}->{temp};
    $td->{humidity}=$resp->{fact}->{humidity};
    if (defined $resp->{visibility}) {$td->{visibility}=$resp->{visibility}};
    
    if (defined $resp->{fact}->{daytime}) {
        if ($resp->{daytime} eq 'd')
        {
            $td->{is_dark}=0;  #DAY
        }
        elsif ($resp->{daytime} eq 'n'){
            $td->{is_dark}=1;  #"NIGHT";
        }
    }
    $td->{'wind.speed'} = $resp->{fact}->{wind_speed};

    
    $td->{'weather'} = $resp ->{l10n}->{$resp->{fact}->{condition}};

    foreach my $key (keys %{ $td }) {
        print $key." " if $debug;
        print $td->{$key}."\n" if $debug;
        zabbix_send( $zabbixserver, $hostname, $key, $td->{$key} );
    }

}


sub get_with_retries {
    my $url           = shift;
    ##my $retry_counter = RETRY_DEFAULT;
    #my $retry_after   = RETRY_WAIT_SECS;
    my $response;
    my $ua = LWP::UserAgent->new( );
    $ua->timeout(TIMEOUT);
    
    eval {#bug workaround for https: see https://rt.cpan.org/Public/Bug/Display.html?id=3316
        local $SIG{ALRM} = sub { die "500 Can't connect to the host (timeout)\n" };
        alarm ($ua->timeout+1);
        $response = $ua->get($url);
        alarm 0;
    };
    
    my $json_response;

    if (!$response->is_success) {
        my $die_msg = $response->status_line;
        $die_msg.=" ".$response->content if $debug;
        die $die_msg."\n";
    }
    
    eval {$json_response = JSON::XS->new->utf8->decode( $response->content );};
    if ($@) {
        die $response->content."\n";
    }
    return $json_response;
}

sub zabbix_send {
    my $zabbixserver = shift;
    my $hostname     = shift;
    my $item         = shift;
    my $data         = shift;
    my $SOCK_TIMEOUT     = 10;
    my $SOCK_RECV_LENGTH = 1024;

    my $result;

    my $request =
      sprintf
      "<req>\n<host>%s</host>\n<key>%s</key>\n<data>%s</data>\n</req>\n",
      encode_base64($hostname), encode_base64($item), encode_base64(encode('utf8',$data));

    my $sock = IO::Socket::INET->new(
        PeerAddr => $zabbixserver,
        PeerPort => '10051',
        Proto    => 'tcp',
        Timeout  => $SOCK_TIMEOUT
    );

    die "Could not create socket: $ERRNO\n" unless $sock;
    $sock->send($request);
    my @handles = IO::Select->new($sock)->can_read($SOCK_TIMEOUT);
    if ( $debug > 0 ) { print "item - $item, data - $data\n"; }

    if ( scalar(@handles) > 0 ) {
        $sock->recv( $result, $SOCK_RECV_LENGTH );
        if ( $debug > 0 ) {
            print "answer from zabbix server $zabbixserver: $result\n";
        }
    }
    else {
        if ( $debug > 0 ) { print "no answer from zabbix server\n"; }
    }
    $sock->close();
    return;
}