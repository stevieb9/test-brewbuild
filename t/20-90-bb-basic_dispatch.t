#!/usr/bin/perl
use strict;
use warnings;

use Archive::Extract;
use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

`bbtester start`;

my $ret = `brewbuild -D -t localhost`;

`bbtester stop`;

print $ret;

done_testing();

