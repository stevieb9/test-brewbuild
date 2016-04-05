#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild::Dispatch;
#use Test::More;

my $d = Test::BrewBuild::Dispatch->new;

$d->dispatch('ls', 'https://stevieb9@github.com/stevieb9/mock-sub', [qw(54.187.92.0:7800)]);

#done_testing();

