#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild;
use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

{ # --version

    my $ret = `brewbuild --version 5.20.3`;

    my @res = split /\n/, $ret;
    @res = grep /\S/, @res;
    print "*$_*\n" for @res;





#    is (@res, 2, "--remove flag works");

#    is (
#        $res[0],
#        "- removing previous installs...",
#        "$res[0] ok with --remove",
#    );

#    is ( $res[1], "5.22.1 :: PASS", "$res[1] ok" );

}

done_testing();

