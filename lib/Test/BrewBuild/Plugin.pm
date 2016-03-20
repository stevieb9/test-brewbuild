package Test::BrewBuild::Plugin;
use strict;
use warnings;

use Carp qw(croak);
use Data::Dumper;
use Logging::Simple;
use Module::Load;

our $VERSION = '0.06';

my $log;

BEGIN {
    no strict 'refs';
    no warnings 'redefine';

    *Test::BrewBuild::plugin = sub {
        my ($obj, $check) = @_;

        $log = $obj->log()->child('Plugin');

        $log->_7("ref obj: ".ref $obj);
        $log->_7("looking for plugin: $check") if $check;

        return _load_plugin($check);
    };
};

sub _load_plugin {
    my $plugin = shift;

    my $log = $log->child('_load_plugin');

    if ($plugin) {

        $log->_7("checking $plugin plugin");

        if ($plugin =~ /(.*)\W(\w+)\.pm/){
            if (! $2){
                unshift @INC, '.';
                $plugin = $1;
            }
            else {
                unshift @INC, $1,
                $plugin = $2;
            }
        }

        my $loaded = eval { load $plugin; 1; };

        if ($loaded) {

            $log->_7("loaded $plugin plugin");

            if ($plugin->can('brewbuild_exec')) {

                $log->_7("brewbuild_exec() found in plugin");

                return $plugin;
            }
        }
    }

    $log->_7("attempt to load default plugin");

    $plugin = 'Test::BrewBuild::Plugin::DefaultExec';

    my $loaded = eval { load $plugin; 1; };

    if (! $loaded){
        $log->_7("FATAL: couldn't load the default plugin");
        croak "couldn't load the default plugin. This is fatal.\n";
    }

    $log->_7("loaded default plugin");

    return $plugin;
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

=head2 _local_load_plugin($plugin_name)

If the C<plugin()> method in C<Test::BrewBuild> is called with an additional
parameter of C<1>, we'll bypass normal checks and look for the plugin in
C<@INC>. Note that this must be a single-name module (ie: C<MyPlugin>), or this
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


