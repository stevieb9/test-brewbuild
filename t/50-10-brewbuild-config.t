#!/usr/bin/perl
use strict;
use warnings;

use Mock::Sub;
use Test::BrewBuild;
use Test::More;

my $mod = 'Test::BrewBuild';

my $m = Mock::Sub->new;
my $set_plugin = $m->mock('Test::BrewBuild::_set_plugin');

{ # good conf file
    $ENV{BB_CONF} = "t/conf/bb-brewbuild.conf";

    my $bb = $mod->new;
    is ($bb->{args}{timeout}, 99, "config file timeout took");
    is ($bb->{args}{remove}, 1, "config file remove took");
    like ($bb->{args}{plugin}, qr/UnitTest/, "config file plugin took");
    is ($bb->{args}{save}, 1, "config file save took");
    is ($bb->{args}{debug}, 1, "config file debug took");
    is ($bb->{args}{legacy}, 1, "config file legacy took");

    $ENV{BB_CONF} = '';
}

$set_plugin->unmock;

done_testing();
