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

{ # --remove

    my $ae = Archive::Extract->new(archive => 't/modules/bb-pass.zip');
    $ae->extract(to => '.');

    chdir 'BB-Pass';
    my $ret = `brewbuild --remove`;
    chdir '..';

    my @res = split /\n/, $ret;
    @res = grep /\S/, @res;

    ok (@res >= 2, "--remove flag works");

    is (
        $res[0],
        "- removing previous installs...",
        "$res[0] ok with --remove",
    );

    is ( $res[1], "5.22.1 :: PASS", "$res[1] ok" );

    remove_tree('BB-Pass');
    is (-d 'BB-Pass', undef, "pass dir removed ok");
}
{ # --r

    my $ae = Archive::Extract->new(archive => 't/modules/bb-pass.zip');
    $ae->extract(to => '.');

    chdir 'BB-Pass';
    my $ret = `brewbuild --r`;
    chdir '..';

    my @res = split /\n/, $ret;
    @res = grep /\S/, @res;

    ok (@res >= 2, "--r flag works");

    is (
        $res[0],
        "- removing previous installs...",
        "$res[0] ok with -r",
    );

    is ( $res[1], "5.22.1 :: PASS", "$res[1] ok" );

    remove_tree('BB-Pass');
    is (-d 'BB-Pass', undef, "pass dir removed ok");
}

done_testing();

