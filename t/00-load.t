#!perl -T
use 5.006;
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok( 'Test::BrewBuild' ) || print "Bail out!\n";
    use_ok( 'Test::BrewBuild::Plugin' ) || print "Bail out!\n";
    use_ok( 'Test::BrewBuild::Plugin::DefaultExec' ) || print "Bail out!\n";
    use_ok( 'Test::BrewBuild::Plugin::UnitTestPluginInst' ) || print "Bail out!\n";
}

{
    my $mod = 'Test::BrewBuild';

    my @subs = qw(
        new
        perls_available
        perls_installed
        instance_remove
        instance_install
        results
        run
        is_win
        exec
        brew_info
        log
    );

    push @subs, 'plugin'; # dynamically installed by Plugin.pm

    for (@subs){
        can_ok($mod, $_);
    }
}
{
    my $mod = 'Test::BrewBuild::Plugin';

    my @subs = qw(
        _load_plugin
    );

    for (@subs){
        can_ok($mod, $_);
    }
}
{
    my $mod = 'Test::BrewBuild::Plugin::DefaultExec';

    my @subs = qw(
        brewbuild_exec
    );

    for (@subs){
        can_ok($mod, $_);
    }
}
done_testing();