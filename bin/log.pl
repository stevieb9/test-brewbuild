#!/usr/bin/perl
use strict;
use warnings;
use Capture::Tiny qw(capture_stdout);
use Test::BrewBuild::Dispatch;
use Test::BrewBuild::Tester;

my $return;

my $stdout = capture_stdout {
    my $d = Test::BrewBuild::Dispatch->new(debug => 7);
    my $t = Test::BrewBuild::Tester->new(debug => 7);

    $t->start;

    $return = $d->dispatch(
        cmd     => 'brewbuild -r -i 5.10.1_32 -d 7',
        repo    => 'https://stevieb9@github.com/stevieb9/p5-logging-simple',
        testers => [ qw(10.1.1.1) ],
    );

    $t->stop;
};

$return .= $stdout;

print $return;