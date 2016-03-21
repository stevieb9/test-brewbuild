#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild;
use Test::More;

my $mod = 'Test::BrewBuild';
my $bb = $mod->new;
my $cmd = $bb->is_win ? 'berrybrew' : 'perlbrew';
my $sep = $bb->is_win ? ';' : ':';

if (! grep { -x "$_/$cmd"}split /$sep/,$ENV{PATH}){
    plan skip_all => "$cmd not installed... skipping";
}

is (ref $bb->log, 'Logging::Simple', "log() returns a proper obj");

done_testing();

