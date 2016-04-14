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
{ # PASS

    my $ae = Archive::Extract->new(archive => 't/modules/bb-pass.zip');
    $ae->extract(to => '.');

    chdir 'BB-Pass';
    my $ret = `brewbuild`;
    chdir '..';

    my @res = split /\n/, $ret;
    @res = grep /\S/, @res;

    if ($^O =~ /MSWin/) {
        is (@res, 2, "proper result count for mutli PASS");
        like ( $res[0], qr/ :: PASS/, "PASS ok (multi perl)" );
        like ( $res[1], qr/ :: PASS/, "PASS ok (multi perl)" );
    }
    else {
        is (@res, 2, "proper result count for mutli PASS");
        is ( $res[0], "5.20.3 :: PASS", "5.20.3 PASS ok (multi perl)" );
        is ( $res[1], "5.22.1 :: PASS", "5.22.1 PASS ok (multi perl)" );
    }

    remove_tree('BB-Pass');
    is (-d 'BB-Pass', undef, "pass dir removed ok");
}
{ # FAIL

    my $ae = Archive::Extract->new(archive => 't/modules/bb-fail.zip');
    $ae->extract(to => '.');

    chdir 'BB-Fail';
    my $ret = `brewbuild`;
    chdir '..';

    my @res = split /\n/, $ret;
    @res = grep /\S/, @res;

    if ($^O =~ /MSWin/) {
        is (@res, 2, "got proper result count for multi FAIL");
        like ( $res[0], qr/:: FAIL/, "5.22.1 FAIL ok (multi perl)" );
        like ( $res[1], qr/:: FAIL/, "5.20.3 FAIL ok (multi perl)" );
    }
    else {
        is (@res, 2, "got proper result count for multi FAIL");
        is ( $res[0], "5.20.3 :: FAIL", "5.20.3 FAIL ok (multi perl)" );
        is ( $res[1], "5.22.1 :: FAIL", "5.22.1 FAIL ok (multi perl)" );
    }

    remove_tree('BB-Fail');
    is (-d 'BB-Fail', undef, "pass dir removed ok");
}

done_testing();
