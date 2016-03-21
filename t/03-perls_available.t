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

my @perls_available = $bb->perls_available($bb->brew_info);

plan skip_all => "no brew info" if ! @perls_available;

ok (@perls_available, 'perls are available');

for (@perls_available){
    like ($_, qr/\d\.\d{1,2}/, "avail contains a perl: $_");
}

done_testing();

