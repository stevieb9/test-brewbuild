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
    my @perls_available = $bb->perls_available($bb->brew_info);

    plan skip_all => "no brew info" if ! @perls_available;

    ok (@perls_available, 'perls are available');

    for (@perls_available){
        like ($_, qr/\d\.\d{1,2}/, "avail contains a perl: $_");
    }
}
else {
    plan skip_all => "$cmd not available... skipping";
}

done_testing();

