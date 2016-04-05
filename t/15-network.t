#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild::Dispatch;
#use Test::More;

my $d = Test::BrewBuild::Dispatch->new;

$d->dispatch([qw(54.187.92.0:7800)], 'ls');

#done_testing();

