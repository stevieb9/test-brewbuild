#!/usr/bin/perl
use strict;
use warnings;

use Capture::Tiny qw(capture_stdout);
use Test::BrewBuild::Dispatch;
use Test::BrewBuild::Tester;
use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

my $t = Test::BrewBuild::Tester->new;
my $d = Test::BrewBuild::Dispatch->new;

$t->start;

my $stdout = capture_stdout {
    $d->dispatch(
        'brewbuild',
        'https://stevieb9@github.com/stevieb9/test-fail',
        [ qw(127.0.0.1:7800) ],
    )
};

$t->stop;

my @ret = split /\n/, $stdout;

ok (@ret > 3, "line count ok");
is ($ret[0], '', "blank line");
like ($ret[1], qr/127\.0\.0\.1 - /, "remote tester info");
is ($ret[2], '', "blank line");
like ($ret[3], qr/.*?:: FAIL/, "FAIL ok");

done_testing();
