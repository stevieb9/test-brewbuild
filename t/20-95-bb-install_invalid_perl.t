#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

my $ret = `brewbuild -N -i 5.99.99`;

like ($ret, qr/is not a valid perl version/, "we log and next if a perl is invalid");

done_testing();

