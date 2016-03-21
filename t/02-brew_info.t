#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild;
use Test::More;


my $mod = 'Test::BrewBuild';
my $bb = $mod->new;

my $cmd = $bb->is_win ? 'berrybrew' : 'perlbrew';

if (! grep { -x "$_/$cmd"}split /:/,$ENV{PATH}){
    plan skip_all => "$cmd not installed... skipping";
}

my $avail =  eval { `$cmd`; 1; };

if ($avail){
    my $info = $bb->brew_info;

    plan skip_all => "no brew info found" if ! $info;

    my @binfo = split /\n/, $info;

    for (@binfo){
        next if /^$/;
        next if /(?:currently|following)/i;
        like ($_, qr/\d\.\d{1,2}/, "$_ in brew_info contains a perl");
    }
}
else {
    plan skip_all => "$cmd not available... skipping";
}

done_testing();

