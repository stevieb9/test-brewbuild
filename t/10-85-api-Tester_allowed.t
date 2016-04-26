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

my $mod = 'Test::BrewBuild::Tester';

{ # allowed
    my $d = Test::BrewBuild::Dispatch->new();
    my $t = $mod->new(debug => 7);

    $t->allowed([qw(127.0.0.1)]);
    is ($t->firewall, 1, "firewall enabled when allowed() is called");

    $t->start;

    my $ret = $d->dispatch(
        testers => ['localhost'],
        cmd => 'brewbuild -N',
        repo => 'https://github.com/stevieb9/p5-logging-simple',
    );

    $t->stop;

    print $ret;
}

done_testing();

