#!/usr/bin/perl
use strict;
use warnings;

use Capture::Tiny qw(capture_stdout);
use Test::BrewBuild::Dispatch;
use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

my $d = Test::BrewBuild::Dispatch->new;

my $stdout = capture_stdout {
    $d->dispatch(
        'brewbuild -R',
        'https://stevieb9@github.com/stevieb9/mock-sub',
        #    'https://stevieb9@github.com/stevieb9/test-fail',
        #    [qw(54.187.92.0:7800)],
        #    [qw(54.187.92.0:7800 127.0.0.1:7800)],
        [qw(127.0.0.1:7800)],
    );
};

my @ret = split /\n/, $stdout;
#@ret = grep {$_ !~ /^\s*$/} @ret;

is (@ret, 17, "return count is correct");

is ($ret[0], '', "blank line");

like ($ret[1], qr/127\.0\.0\.1 - /, "remote tester info");

is ($ret[2], '', "blank line");

like ($ret[3], qr/reverse dependencies:/, "line has has revdep info");

is ($ret[4], '', "blank line");
is ($ret[5], '', "blank line");

like ($ret[6], qr/.*?::.*?::.*?/, "Module name");
like ($ret[7], qr/.*?:: PASS/, "PASS ok");
like ($ret[8], qr/.*?:: PASS/, "PASS ok");

is ($ret[9], '', "blank line");

like ($ret[10], qr/.*?::.*?::.*?/, "Module name");
like ($ret[11], qr/.*?:: PASS/, "PASS ok");
like ($ret[12], qr/.*?:: PASS/, "PASS ok");

is ($ret[13], '', "blank line");

like ($ret[14], qr/.*?::.*?::.*?/, "Module name");
like ($ret[15], qr/.*?:: PASS/, "PASS ok");
like ($ret[16], qr/.*?:: PASS/, "PASS ok");

done_testing();
