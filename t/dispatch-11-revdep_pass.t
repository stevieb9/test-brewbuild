#!/usr/bin/perl
use strict;
use warnings;

use Capture::Tiny qw(capture_stdout);
use Test::BrewBuild::Dispatch;
use Test::BrewBuild::Git;
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
        cmd => 'brewbuild -r -R',
        repo => 'https://stevieb9@github.com/stevieb9/mock-sub',
        testers => [qw(127.0.0.1:7800)],
    );
};

$t->stop;

my @ret = split /\n/, $stdout;
@ret = grep {$_ !~ /^\s*$/} @ret;

print "$_\n" for @ret;
is (@ret, 8, "return count is correct");

like ($ret[0], qr/127\.0\.0\.1 - /, "remote tester info");
like ($ret[1], qr/reverse dependencies:/, "line has has revdep info");

like ($ret[2], qr/.*?::.*?::.*?/, "Module name");
like ($ret[3], qr/.*?:: PASS/, "PASS ok");

like ($ret[4], qr/.*?::.*?::.*?/, "Module name");
like ($ret[5], qr/.*?:: PASS/, "PASS ok");

like ($ret[6], qr/.*?::.*?::.*?/, "Module name");
like ($ret[7], qr/.*?:: PASS/, "PASS ok");


done_testing();
