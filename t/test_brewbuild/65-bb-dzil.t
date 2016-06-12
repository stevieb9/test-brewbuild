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

my $path_sep = $^O =~ /MSWin/ ? ';' : ':';

if (! grep {-x "$_/dzil"} split /$path_sep/, $ENV{PATH} ){
    plan skip_all => "dzil not found for Dist::Zilla tests";
}

{ # PASS

    my $ae = Archive::Extract->new(archive => 't/modules/dzil-test.zip');
    $ae->extract(to => '.');

    chdir 'Dzil-Test';
    my $ret = `brewbuild --remove`;
    chdir '..';

    my @res = split /\n/, $ret;
    @res = grep /\S/, @res;

    print "*$_*\n" for @res;
    is (@res, 2, "dzil proper result count");

    like ( $res[1], qr/:: PASS/, "dzil PASS ok" );

    remove_tree('Dzil-Test');
    is (-d 'Dzil-Test', undef, "dzil dir removed ok");
}

done_testing();

