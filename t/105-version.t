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

{ # --version

    my $ae = Archive::Extract->new(archive => 't/modules/bb-pass.zip');
    $ae->extract(to => '.');

    chdir 'BB-Pass';
    `brewbuild -r`;
    my $ret = `brewbuild --version 5.20.3`;
    chdir '..';

    my @res = split /\n/, $ret;
    @res = grep /\S/, @res;

    is (@res, 3, "proper result count with --version");
    is ($res[0], '- installing 5.20.3...', "--version ok");
    is ($res[1], '5.20.3 :: PASS', "--version ok $res[1]");
    is ($res[2], '5.22.1 :: PASS', "--version ok $res[2]");

    remove_tree('BB-Pass');
    is (-d 'BB-Pass', undef, "--version pass dir removed ok");
}

done_testing();

