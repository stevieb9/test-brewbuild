#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild::Dispatch;
use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}
my $d = Test::BrewBuild::Dispatch->new;

my $ret = $d->dispatch(
    'asdf',
    'https://stevieb9@github.com/stevieb9/mock-sub',
    [qw(127.0.0.1:7800)],
);
print $ret;
done_testing();
