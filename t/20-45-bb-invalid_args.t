#!/usr/bin/perl
use strict;
use warnings;

use Archive::Extract;
use File::Path qw(remove_tree);
use Test::BrewBuild;
use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

{ # invalid args

    my $ret = `brewbuild --bad`;

    like ($ret, qr/Usage/, "we print help and exit on bad param");
}

done_testing();

