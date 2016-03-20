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
    my $info = $bb->brew_info;

    my @installed = $bb->perls_installed($info);

    if ($info =~ /i/){
        ok (@installed, "if a perl is installed, it shows");
        for (@installed){
            like ($_, qr/\d\.\d{1,2}/, "each installed perl is a perl $_");
        }
    }
    else {
        is (@installed, 0, 'with no perls installed, empty array is returned');
    }
}

done_testing();

