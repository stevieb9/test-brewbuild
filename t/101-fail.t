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

{ # FAIL

    my $ae = Archive::Extract->new(archive => 't/modules/bb-fail.zip');
    $ae->extract(to => '.');

    chdir 'BB-Fail';
    my $ret = `brewbuild --remove`;
    chdir '..';

    my @res = split /\n/, $ret;
    @res = grep /\S/, @res;

    is (@res, 2, "got proper result count");

    is ( $res[1], "5.22.1 :: FAIL", "FAIL ok" );

    remove_tree('BB-Fail');
    is (-d 'BB-Fail', undef, "pass dir removed ok");
}

done_testing();

