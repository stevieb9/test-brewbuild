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

    my $ver = $^O =~ /MSWin/ ? '5.18.4_64' : '5.18.4';

    chdir $dir;
    `brewbuild -r`;
    my $ret = `brewbuild --install $ver --revdep`;
    chdir '..';

    my @res = split /\n/, $ret;
    @res = grep /\S/, @res;

    if ($^O =~ /MSWin/){
        is (@res, 14, "proper result count");
        like ($res[0], qr/working on/, "first like is the list of revdeps" );
        like ($res[1], qr/- installing/, "line 2 is ok");
        like ($res[2], qr/\w+::\w+/, "is a module name");
        like ($res[3], qr/:: \w+/, "is a valid result");
        like ($res[4], qr/:: \w+/, "is a valid result");
        like ($res[5], qr/\w+::\w+/, "is a module name");
        like ($res[6], qr/:: \w+/, "is a valid result");
        like ($res[7], qr/:: \w+/, "is a valid result");
        like ($res[8], qr/\w+::\w+/, "is a module name");
        like ($res[9], qr/:: \w+/, "is a valid result");
        like ($res[10], qr/:: \w+/, "is a valid result");
        like ($res[11], qr/\w+::\w+/, "is a module name");
        like ($res[12], qr/:: \w+/, "is a valid result");
        like ($res[13], qr/:: \w+/, "is a valid result");
    }
    else {
        is (@res, 14, "proper result count");
        like ($res[0], qr/working on/, "first line is the list of revdeps" );
        like ($res[1], qr/- installing/, "line 2 ok");
        like ($res[2], qr/\w+::\w+/, "is a module name");
        like ($res[3], qr/5.18.4 :: \w+/, "is a valid result");
        like ($res[4], qr/5.22.1 :: \w+/, "is a valid result");
        like ($res[5], qr/\w+::\w+/, "is a module name");
        like ($res[6], qr/5.18.4 :: \w+/, "is a valid result");
        like ($res[7], qr/5.22.1 :: \w+/, "is a valid result");
        like ($res[8], qr/\w+::\w+/, "is a module name");
        like ($res[9], qr/5.18.4 :: \w+/, "is a valid result");
        like ($res[10], qr/5.22.1 :: \w+/, "is a valid result");
        like ($res[11], qr/\w+::\w+/, "is a module name");
        like ($res[12], qr/5.18.4 :: \w+/, "is a valid result");
        like ($res[13], qr/5.22.1 :: \w+/, "is a valid result");
    }

    remove_tree($dir);
    is (-d $dir, undef, "$dir removed ok");
}

done_testing();

