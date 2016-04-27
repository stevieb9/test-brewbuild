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

    my @res = split /\n/, $ret;
    @res = grep /\S/, @res;

    is (@res, 2, "got proper result count");

    like ( $res[1], qr/5.22.1.*? :: FAIL/, "FAIL ok" );


    my $log;
    if ($^O =~ /MSWin/){
        is (-e 'bblog/5.22.1_64-FAIL.bblog', 1, "fail log for 5.22.1 created ok");
        open $log, '<', 'bblog/5.22.1_64-FAIL.bblog' or die $!;
    }
    else {
        is (-e 'bblog/5.22.1-FAIL.bblog', 1, "fail log for 5.22.1 created ok");
        open $log, '<', 'bblog/5.22.1-FAIL.bblog' or die $!;
    }
    my @entries = <$log>;
    chomp @entries;
    close $log;

    if ($^O !~ /MSWin/){
        is ((scalar grep {$_ eq 'CPANM ERROR LOG'} @entries), 1, "error log got attached"); 
        is ((scalar grep {$_ eq 'CPANM BUILD LOG'} @entries), 1, "build log got attached"); 
    }

    chdir '..';
    remove_tree('BB-Fail');
    is (-d 'BB-Fail', undef, "pass dir removed ok");
}

done_testing();

