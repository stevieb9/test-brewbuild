#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild;
use Test::More;

my $mod = 'Test::BrewBuild';
my $bb = $mod->new;

my $win_os = ($] =~ /MSWin/) ? 1 : 0;

if ($win_os){
    is ($bb->is_win, 1, "on windows, is_win() is ok");
}
if (! $win_os){
    is ($bb->is_win, 0, "on non windows, is_win() is ok");
}
done_testing();

