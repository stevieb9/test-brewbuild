package Test::BrewBuild::Plugin;
use strict;
use warnings;

use ExtUtils::Installed;
use Logging::Simple;
use Module::Load;

our $VERSION = '0.05';

my $log;

BEGIN {
    no strict 'refs';
    no warnings 'redefine';

    *Test::BrewBuild::plugin = sub {
        my ($obj, $check, $local) = @_;

        $log = $obj->log()->child('Plugin');

        $log->_7("ref obj: " . ref $obj);
        $log->_7("looking for plugin: $check") if $check;
        $log->_7("looking for plugin locally") if $local;

        if (! $local) {
            return _load_plugin($check);
        }
        return _local_load_plugin($check);
    };
};

sub _load_plugin {
    my $plugin = shift;

    my $log = $log->child('_load_plugin');

    my $inst = ExtUtils::Installed->new;
    my @modules = $inst->modules;

    if ($plugin && grep { $_ eq $plugin } @modules) {

        load $_;
        $log->_7("loaded $_ plugin");

        if ($_->can('brewbuild_exec')){
            $log->_7("brewbuild_exec() found in plugin");
            return $plugin;
        }
    }
    else {
        $log->_7("using default plugin");
        $plugin = 'Test::BrewBuild::Plugin::DefaultExec';
        load $plugin;
        return $plugin;
    }
}
sub _local_load_plugin {
    my $plugin = shift;

    $log = $log->child('_local_load_plugin');

    load $plugin;

    if ($plugin->can('brewbuild_exec')){
        $log->_7("brewbuild_exec found in local plugin");

        return $plugin;
    }
    else {
        $log->_7("plugin not found in local... using default plugin");
        $plugin = 'Test::BrewBuild::Plugin::DefaultExec';
        load $plugin;
        return $plugin;
    }
}
1;

=head1 NAME

Test::BrewBuild::Plugin - Plugin manager for Test::BerryBrew

=head1 DESCRIPTION

This module is not for end-user use.

It sets a new C<plugin()> subroutine into C<Test::BrewBuild>'s namespace, and
looks for, loads and retrieves the data that composes the commands that get
sent to C<*brew exec>.

=head1 FUNCTIONS

=head2 _load_plugin($plugin_name)

Sets the plugin executable code to what's found in the plugin's
C<brewbuild_exec()> function, and returns the name of the plugin the code was
installed from.

If the plugin in the C<$plugin_name> param can't be found, we return that of
the default built-in C<Test::BrewBuild::Plugin::DefaultExec> one.

=head2 _local_load_($plugin_name)

If the C<plugin()> method in C<Test::BerryBrew> is called with an additional
parameter of C<1>, we'll bypass normal checks and look for the plugin in
C<@INC>. Note that this must be a single-name module (ie: C<MyPlugin>, or this
will fail.

Before you call the C<plugin()> method with the local search param set,
configure something like C<use lib '.';> or equivalent.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut


