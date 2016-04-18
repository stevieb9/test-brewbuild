#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild::Dispatch;
use Test::BrewBuild::Tester;

my $d = Test::BrewBuild::Dispatch->new(debug => 7);
my $t = Test::BrewBuild::Tester->new(debug => 7);

$t->start;
my $ret = $d->dispatch(
    cmd => 'brewbuild',
    repo => 'https://stevieb9@github.com/stevieb9/mock-sub',
    testers => [qw(127.0.0.1:7800)],
);

$t->stop;

print $ret;

