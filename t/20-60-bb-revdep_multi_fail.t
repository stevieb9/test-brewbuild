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

{ # revdep

    $ENV{BBDEV_TESTING} = 0;

    my $ae = Archive::Extract->new(archive => 't/modules/mock-sub-bad.zip');
    $ae->extract(to => '.');

    my $ver = $^O =~ /MSWin/ ? '5.18.4_64' : '5.18.4';

    chdir $dir;
    `brewbuild -r`;
    my $ret = `brewbuild --install $ver --revdep --selftest`;
    chdir '..';

    my @res = split /\n/, $ret;
    @res = grep /\S/, @res;

    print "*$_*\n" for @res;

    if ($^O =~ /MSWin/){
        is (@res, 11, "proper result count");
        like ($res[0], qr/- installing/, "installing");
        like ($res[1], qr/reverse dependencies/, "deps" );
        like ($res[2], qr/\w+::\w+/, "is a module name");
        like ($res[3], qr/5.18.4.*? :: PASS/, "PASS");
        like ($res[4], qr/5.22.1.*? :: FAIL/, "FAIL");
        like ($res[5], qr/\w+::\w+/, "is a module name");
        like ($res[6], qr/5.18.4.*? :: PASS/, "PASS");
        like ($res[7], qr/5.22.1.*? :: FAIL/, "FAIL");
        like ($res[8], qr/\w+::\w+/, "is a module name");
        like ($res[9], qr/5.18.4.*? :: PASS/, "PASS");
        like ($res[10], qr/5.22.1.*? :: FAIL/, "FAIL");
    }
    else {
        is (@res, 11, "proper result count");
        like ($res[0], qr/- installing/, "installing");
        like ($res[1], qr/reverse dependencies/, "deps" );
        like ($res[2], qr/\w+::\w+/, "is a module name");
        like ($res[3], qr/5.18.4 :: PASS/, "PASS");
        like ($res[4], qr/5.22.1 :: FAIL/, "FAIL");
        like ($res[5], qr/\w+::\w+/, "is a module name");
        like ($res[6], qr/5.18.4 :: PASS/, "PASS");
        like ($res[7], qr/5.22.1 :: FAIL/, "FAIL");
        like ($res[8], qr/\w+::\w+/, "is a module name");
        like ($res[9], qr/5.18.4 :: PASS/, "PASS");
        like ($res[10], qr/5.22.1 :: FAIL/, "FAIL");
    }

    remove_tree($dir);
    is (-d $dir, undef, "$dir removed ok");

    $ENV{BBDEV_TESTING} = 0;
}

done_testing();

