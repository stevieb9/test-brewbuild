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
@ret = grep {$_ !~ /^\s*$/} @ret;

print "$_\n" for @ret;
is (@ret, 11, "return count is correct");

like ($ret[0], qr/127\.0\.0\.1 - /, "remote tester info");
like ($ret[1], qr/reverse dependencies:/, "line has has revdep info");

like ($ret[2], qr/.*?::.*?::.*?/, "Module name");
like ($ret[3], qr/.*?:: PASS/, "PASS ok");
like ($ret[4], qr/.*?:: PASS/, "PASS ok");

like ($ret[5], qr/.*?::.*?::.*?/, "Module name");
like ($ret[6], qr/.*?:: PASS/, "PASS ok");
like ($ret[7], qr/.*?:: PASS/, "PASS ok");

like ($ret[8], qr/.*?::.*?::.*?/, "Module name");
like ($ret[9], qr/.*?:: PASS/, "PASS ok");
like ($ret[10], qr/.*?:: PASS/, "PASS ok");

done_testing();
