#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild;
use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

my $ret = `brewbuild --notest`;
is ($ret, '', "--notest works");

$ret = `brewbuild -N`;
is ($ret, '', "-N works");

done_testing();

