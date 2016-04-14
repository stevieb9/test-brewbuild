#!/usr/bin/perl
use strict;
use warnings;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

use Capture::Tiny qw(capture_stdout);
use Test::BrewBuild::Dispatch;
use Test::More;

my $d = Test::BrewBuild::Dispatch->new;

my $stdout = capture_stdout {
    $d->dispatch(
        'brewbuild',
        'https://stevieb9@github.com/stevieb9/test-fail',
        [ qw(127.0.0.1:7800) ],
    )
};

my @ret = split /\n/, $stdout;

ok (@ret > 3, "line count ok");
is ($ret[0], '', "blank line");
like ($ret[1], qr/127\.0\.0\.1 - /, "remote tester info");
is ($ret[2], '', "blank line");
like ($ret[3], qr/.*?:: FAIL/, "FAIL ok");

done_testing();
