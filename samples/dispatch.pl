#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild::Dispatch;

my $d = Test::BrewBuild::Dispatch->new(debug => 7);

$d->dispatch(
    cmd => 'brewbuild -R -S',
    repo => 'https://stevieb9@github.com/stevieb9/mock-sub',
    testers => [qw(127.0.0.1:7800)],
);
