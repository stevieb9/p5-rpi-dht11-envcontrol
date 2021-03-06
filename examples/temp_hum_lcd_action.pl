use warnings;
use strict;

use RPi::DHT11::EnvControl;
use RPi::WiringPi;
use RPi::WiringPi::Constant qw(:all);

our $VERSION = '0.07';

my $continue = 1;
$SIG{INT} = sub { $continue = 0; };

use constant {
    SENSOR_PIN => 13,
    TEMP_PIN => 27,
    HUMIDITY_PIN => 0,
};

# get a Pi object

my $pi = RPi::WiringPi->new(
    fatal_exit => 0,
);

my $temp_high = 74;
my $humidity_low = 20;

# get an environment object

my $env = RPi::DHT11::EnvControl->new(
    spin => SENSOR_PIN,
    tpin => TEMP_PIN,
    hpin => HUMIDITY_PIN,
);

# fetch an LCD object, and initialize it

my $lcd = $pi->lcd;

my %lcd_args = (
    rows => 2, cols => 16,
    bits => 4, rs => 2, strb => 25,
    d0 => 14, d1 => 26, d2 => 23, d3 => 15,
    d4 => 0, d5 => 0, d6 => 0, d7 => 0,
);

$lcd->init(%lcd_args);

my $degree = 'f';

while ($continue){
    my $temp = $env->temp($degree);
    my $humidity = $env->humidity;

    # temp is too hot

    $lcd->position(0, 0); # first column, first row
    
    if ($temp > $temp_high){
        if (! $env->status(TEMP_PIN)){
            $env->control(TEMP_PIN, ON);
            print "turned on temp control device\n";
        }
        #           "................"
        $lcd->print("${temp}/${temp_high}".uc($degree));
    }
    else {
        if ($env->status(TEMP_PIN)){
            $env->control(TEMP_PIN, OFF);
            print "turned off temp control device\n";
        }
        $lcd->print("${temp}/${temp_high}".uc($degree));
    }

    # humidity is too low

    $lcd->position(0, 1); # first column, second row

    if ($humidity < $humidity_low){
        if (! $env->status(HUMIDITY_PIN)){
            $env->control(HUMIDITY_PIN, ON);
            print "turned on humidifier\n";
        }
        $lcd->print("${humidity}/${humidity_low}%     *");
    }
    else {
        if ($env->status(HUMIDITY_PIN)){
            $env->control(HUMIDITY_PIN, OFF);
            print "turned off humidifier";
        }
        $lcd->print("${humidity}/${humidity_low}%");
    }
    sleep 300;
}

$lcd->clear;
$pi->cleanup;
