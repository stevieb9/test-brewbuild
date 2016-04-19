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

{ # --new & -n

    my $ae = Archive::Extract->new(archive => 't/modules/bb-pass.zip');
    $ae->extract(to => '.');

    chdir 'BB-Pass';

    `brewbuild -r`;
    `brewbuild --new 1`;
    my $ret = `brewbuild -n 1`;

    chdir '..';

    my @res = split /\n/, $ret;
    @res = grep /\S/, @res;

    is (@res, 5, "--new 1 & -n 1 combined results in ok output");

    like ($res[0], qr/- installing /, "$res[0] installing ok");
    like ($res[1], qr/- installing /, "$res[1] installing ok");
    like ($res[2], qr/5\.\d{1,2}\.\d :: PASS/, "PASS run ok");
    like ($res[3], qr/5\.\d{1,2}\.\d :: PASS/, "PASS run ok");
    like ($res[4], qr/5\.\d{1,2}\.\d :: PASS/, "PASS run ok");

    remove_tree('BB-Pass');
    is (-d 'BB-Pass', undef, "--new pass dir removed ok");
}

done_testing();

