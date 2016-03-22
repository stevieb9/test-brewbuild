#!/usr/bin/perl
use strict;
use warnings;

use Mock::Sub;
use Test::BrewBuild;
use Test::More;

my $mock = Mock::Sub->new;

my $brew_info = $mock->mock(
    'Test::BrewBuild::brew_info',
    return_value => 1
);

if ($^O =~ /MSWin/){
    my $instance_install = $mock->mock('Test::BrewBuild::instance_install');
    my $instance_remove = $mock->mock('Test::BrewBuild::instance_remove');
    my $perls_available = $mock->mock('Test::BrewBuild::perls_available');
    $perls_available->return_value(qw(5.20.0 5.22.1 5.8.9));
    my $perls_installed = $mock->mock('Test::BrewBuild::perls_installed');
    $perls_installed->return_value(qw(5.20.0));
    my $results = $mock->mock('Test::BrewBuild::results', return_value => 'done');

    { # default
        my $bb = Test::BrewBuild->new;
        my $ret = $bb->run;
        is ($ret, 'done', "win: run() all default ok");

        for ($perls_available, $perls_installed, $results){
            is ($_->called, 1, "win: run() default all subs called");
        }
    }
    { # w/new
        my $bb = Test::BrewBuild->new(new => 1);
        $bb->run;
        is ($instance_install->called, 1, "win: instance_install called w/new");
    }
    { # no perls installed
        my $bb = Test::BrewBuild->new(debug => 0);
        $perls_installed->return_value(0);
        $results->reset;
        $bb->run;
        is ($results->called, 0, "win: if no perls installed, we exit");
    }
    { # w/remove
        my $bb = Test::BrewBuild->new(remove => 1);
        $perls_installed->return_value(1);
        $bb->run;
        is ($instance_remove->called, 1, "win: instance_remove called w/remove");
    }
    for ($instance_install, $instance_remove, $brew_info, $perls_available, $results){
        $_->unmock;
        is ($_->mocked_state, 0, $_->name ." is unmocked");
    }
}
else {
    my $instance_install = $mock->mock('Test::BrewBuild::instance_install');
    my $instance_remove = $mock->mock('Test::BrewBuild::instance_remove');
    my $perls_available = $mock->mock('Test::BrewBuild::perls_available');
    $perls_available->return_value(qw(5.20.0 5.22.1 5.8.9));
    my $perls_installed = $mock->mock('Test::BrewBuild::perls_installed');
    $perls_installed->return_value(qw(5.20.0));
    my $results = $mock->mock('Test::BrewBuild::results', return_value => 'done');
    { # default
        my $bb = Test::BrewBuild->new;
        my $ret = $bb->run;
        is ($ret, 'done', "nix: run() all default ok");

        for ($perls_installed, $perls_installed, $results){
            is ($_->called, 1, "nix: run() default all subs called");
        }
    }
    { # w/new
        my $bb = Test::BrewBuild->new(new => 1);
        $bb->run;
        is ($instance_install->called, 1, "nix: instance_install called w/new");
    }
    { # no perls installed
        my $bb = Test::BrewBuild->new(debug => 0);
        $perls_installed->return_value(0);
        $results->reset;
        $bb->run;
        is ($results->called, 0, "nix: if no perls installed, we exit");
    }
    { # w/remove
        my $bb = Test::BrewBuild->new(remove => 1);
        $perls_installed->return_value(1);
        $bb->run;
        is ($instance_remove->called, 1, "nix: instance_remove called w/remove");
    }
    for ($instance_install, $instance_remove, $brew_info, $perls_available, $results){
        $_->unmock;
        is ($_->mocked_state, 0, $_->name ." is unmocked");
    }
}


done_testing();

