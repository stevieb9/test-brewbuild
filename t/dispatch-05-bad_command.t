#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild::Dispatch;
use Test::More;

my $d = Test::BrewBuild::Dispatch->new;

$d->dispatch(
    'asdf',
    'https://stevieb9@github.com/stevieb9/mock-sub',
    [qw(127.0.0.1:7800)],
);

done_testing();
