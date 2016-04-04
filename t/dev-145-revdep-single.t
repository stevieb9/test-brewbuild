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

my $dir = 'Mock-Sub-1.06';

{ # revdep single

    my $ae = Archive::Extract->new(archive => 't/modules/mock-sub.tgz');
    $ae->extract(to => '.');

    $ENV{BBDEV_TESTING} = 0;

    chdir $dir;
    `brewbuild -r`;
    my $ret = `brewbuild --revdep -T`;
    chdir '..';

    my @res = split /\n/, $ret;
    @res = grep /\S/, @res;

    is (@res, 7, "proper result count");
    like ($res[0], qr/working on/, "first like is the list of revdeps" );
    like ($res[1], qr/\w+::\w+/, "$res[1] is a module name");
    like ($res[2], qr/5.22.1 :: \w+/, "$res[2] is a valid result");
    like ($res[3], qr/\w+::\w+/, "$res[3] is a module name");
    like ($res[4], qr/5.22.1 :: \w+/, "$res[4] is a valid result");
    like ($res[5], qr/\w+::\w+/, "$res[5] is a module name");
    like ($res[6], qr/5.22.1 :: \w+/, "$res[6] is a valid result");

    remove_tree($dir);
    is (-d $dir, undef, "$dir removed ok");

    $ENV{BBDEV_TESTING} = 1;
}

done_testing();

