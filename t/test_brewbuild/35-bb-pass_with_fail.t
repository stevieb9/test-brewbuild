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

    my $ver = $^O =~ /MSWin/ ? '5.10.1_32' : '5.10.1';

    `brewbuild --remove`;
    my $ret = `brewbuild --install $ver`;
    chdir '..';

    print $ret;

    my @res = split /\n/, $ret;
    @res = grep /\S/, @res;

    if ($^O =~ /MSWin/){
        is (@res, 3, "pass and fail simultaneously has proper count");
        like ($res[1], qr/:: PASS/, "PASS ok");
        like ($res[2], qr/:: FAIL/, "FAIL ok");
    }
    else {
        is (@res, 3, "pass and fail simultaneously has proper count");
        like ($res[1], qr/:: PASS/, "PASS ok");
        like ($res[2], qr/:: FAIL/, "FAIL ok");
    }

    remove_tree('BB-522');
    is (-d 'BB-522', undef, "pass_with_fail dir removed ok");
}

done_testing();

