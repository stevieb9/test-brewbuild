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

{ #

    my $ae = Archive::Extract->new(archive => 't/modules/bb-522.zip');
    $ae->extract(to => '.');

    chdir 'BB-522';

    `brewbuild --remove`;
    my $ret = `brewbuild --version 5.10.1`;

    chdir '..';

    my @res = split /\n/, $ret;
    @res = grep /\S/, @res;

    is (@res, 3, "pass and fail simultaneously has proper count");
    is ($res[1], '5.10.1 :: PASS', "pass & fail $res[1] line 1 ok");
    is ($res[2], '5.22.1 :: PASS', "pass & fail $res[2] line 2 ok");

    remove_tree('BB-522');
    is (-d 'BB-522', undef, "pass_with_fail dir removed ok");
}

done_testing();

