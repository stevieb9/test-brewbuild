#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild::Dispatch;
#use Test::More;

my $d = Test::BrewBuild::Dispatch->new;

$d->dispatch(
    'brewbuild',
#   'https://stevieb9@github.com/stevieb9/mock-sub',
    'https://stevieb9@github.com/stevieb9/test-fail',
    [qw(54.187.92.0:7800 54.187.108.206:7800)],
#    [qw(54.187.92.0:7800)],
);

#done_testing();

