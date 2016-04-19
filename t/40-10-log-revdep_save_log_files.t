#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild::Dispatch;
use Test::BrewBuild::Git;
use Test::BrewBuild::Tester;

use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

# clean out log dir

if ($^O =~ /MSWin/){
    my @logs = glob 'c:/brewbuild/bblog/*';
    for (@logs){
        unlink $_ or die $!;
    }
}
else {
    my @logs = glob "$ENV{HOME}/brewbuild/*";
    for (@logs){
        unlink $_ or die $!;
    }
}

my $t = Test::BrewBuild::Tester->new;
my $d = Test::BrewBuild::Dispatch->new;

$t->start;

$d->dispatch(
    cmd => 'brewbuild -r -R -S',
    repo => 'https://stevieb9@github.com/stevieb9/mock-sub',
    testers => [qw(127.0.0.1:7800)],
);

$t->stop;

if ($^O =~ /MSWin/){
    my @logs = glob 'c:/brewbuild/bblog/*';
    is (@logs, 3, "got proper log file count");
    for (@logs){
        like ($_, qr/127\.0\.0\.1_.*-5\.22\.1-PASS\.bblog/, "log $_ ok");
        unlink $_ or die $!;
    }
}
else {
    my @logs = glob "$ENV{HOME}/brewbuild/*";
    is (@logs, 3, "got proper log file count");
    for (@logs){
        like ($_, qr/127\.0\.0\.1_.*-5\.22\.1-PASS\.bblog/, "log $_ ok");
        unlink $_ or die $!;
    }
}

done_testing();
