#!/usr/bin/perl
use strict;
use warnings;

use Mock::Sub;
use Test::BrewBuild;
use Test::More;

my $mock = Mock::Sub->new;
my $brew = $mock->mock(
    'Test::BrewBuild::BrewCommands::brew',
    return_value => 'asdfasdf'
);

{ # no --on
    my $bb = Test::BrewBuild->new(debug => 7);

    if (! $bb->is_win) {
        $bb->exec;
        is ( $brew->called, 1, "nix: brew is called in exec()" );

        $brew->reset;
        $brew->return_value( 'asdfasdf' );
    }
    else {
        $bb->exec;
        is ($brew->called, 1, "win: brew is called in exec()");

        $brew->reset;
        $brew->return_value( 'asdfasdf' );
    }

}
{ # --on
    my $bb = Test::BrewBuild->new(debug => 7, on => [qw(5.20.3)]);

    if (! $bb->is_win){
        $bb->exec;
        is ($brew->called, 1, "nix: brew is called in exec()");

        $brew->reset;
        $brew->return_value( 'asdfasdf' );
    }
    else {
        $bb->exec;
        is ($brew->called, 1, "win: brew is called in exec()");

        $brew->reset;
        $brew->return_value( 'asdfasdf' );
    }
}
done_testing();

