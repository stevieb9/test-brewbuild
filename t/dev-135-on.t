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
if ($^O =~ /MSWin/){
    plan skip_all => "berrybrew exec doesn't have a --with flag";
    exit;
}
{ # --on and -o

    my $ae = Archive::Extract->new(archive => 't/modules/bb-pass.zip');
    $ae->extract(to => '.');

    chdir 'BB-Pass';

    my $ret = `brewbuild --on 5.22.1 -o 5.10.1`;

    print "*$ret*\n";
    chdir '..';

    my @res = split /\n/, $ret;
    @res = grep /\S/, @res;

    is (@res, 2, "--new 1 & -n 2 combined results in ok output");

    like ($res[0], qr/5.10.1 :: PASS/, "$res[0] --on ok");
    like ($res[1], qr/5.22.1 :: PASS/, "$res[1] -o ok");

    remove_tree('BB-Pass');
    is (-d 'BB-Pass', undef, "--version pass dir removed ok");
}

done_testing();

