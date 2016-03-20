#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild;
use Test::More;

my $mod = 'Test::BrewBuild';
my $bb = $mod->new;

if ($^O =~ /Win/){
    is ($bb->is_win, 1, "on windows, is_win() is ok");
}
else {
    is ($bb->is_win, 0, "on non windows, is_win() is ok");
}
done_testing();

