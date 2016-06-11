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

my $perlver = $ENV{PERLVER};

{ #

    my $ae = Archive::Extract->new(archive => 't/modules/bb-522.zip');
    $ae->extract(to => '.');

    chdir 'BB-522';

    my $ver = $^O =~ /MSWin/ ? '5.10.1_32' : '5.10.1';

    `brewbuild --remove`;
    my $ret = `brewbuild --install $ver`;
    chdir '..';

    print $ret;

    my @res = split /\n/, $ret;
    @res = grep /\S/, @res;

    if ($^O =~ /MSWin/){
        is (@res, 3, "pass and fail simultaneously has proper count");
        is ($res[1], '5.10.1_32 :: PASS', "PASS ok");
        is ($res[2], "$perlver_64 :: FAIL", "FAIL ok");
    }
    else {
        is (@res, 3, "pass and fail simultaneously has proper count");
        is ($res[1], '5.10.1 :: PASS', "PASS ok");
        is ($res[2], "$perlver :: FAIL", "FAIL ok");
    }

    remove_tree('BB-522');
    is (-d 'BB-522', undef, "pass_with_fail dir removed ok");
}

done_testing();

