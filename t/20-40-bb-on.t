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

my $perlver = $ENV{PERLVER};

{ # --on and -o

    my $ae = Archive::Extract->new(archive => 't/modules/bb-pass.zip');
    $ae->extract(to => '.');

    chdir 'BB-Pass';

    my $ret = `brewbuild --on $perlver -o 5.10.1`;

    chdir '..';

    my @res = split /\n/, $ret;
    @res = grep /\S/, @res;

    is (@res, 2, "-o and --on have proper return count");

    like ($res[0], qr/$perlver :: PASS/, "--on ok");
    like ($res[1], qr/5.10.1 :: PASS/, "-o ok");

    remove_tree('BB-Pass');
    is (-d 'BB-Pass', undef, "--on pass dir removed ok");
}

done_testing();

