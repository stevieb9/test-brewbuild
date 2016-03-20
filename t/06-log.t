#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild;
use Test::More;

my $mod = 'Test::BrewBuild';
my $bb = $mod->new;
my $cmd = $bb->is_win ? 'berrybrew' : 'perlbrew';

my $avail =  eval { `$cmd`; 1; };

if ($avail){
    is (ref $bb->log, 'Logging::Simple', "log() returns a proper obj");

}

done_testing();

