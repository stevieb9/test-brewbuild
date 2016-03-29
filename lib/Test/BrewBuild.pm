package Test::BrewBuild;
use strict;
use warnings;

use File::Temp;
use Logging::Simple;
use Plugin::Simple default => 'Test::BrewBuild::Plugin::DefaultExec';
use Test::BrewBuild::BrewCommands;

our $VERSION = '1.04';

my $log;
my $bcmd;

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    %{ $self->{args} } = %args;

    $log = $self->_create_log($args{debug});
    $log->_6("in new(), constructing " . __PACKAGE__ . " object");

    $bcmd = Test::BrewBuild::BrewCommands->new($log);

    my $plugin = $args{plugin} ? $args{plugin} : $ENV{TBB_PLUGIN};

    $log->_5("plugin param set to: " . defined $plugin ? $plugin : 'default');

    $plugin = $self->plugins($plugin, can => ['brewbuild_exec']);

    my $exec_plugin_sub = $plugin .'::brewbuild_exec';
    $self->{exec_plugin} = \&$exec_plugin_sub;

    $log->_4("successfully loaded $plugin plugin");

    return $self;
}
sub perls_available {
    my ($self, $brew_info) = @_;

    my $log = $log->child('perls_available');

    my @perls_available = $bcmd->available($brew_info);

    $log->_6("perls available: " . join ', ', @perls_available);

    return @perls_available;
}
sub perls_installed {
    my ($self, $brew_info) = @_;

    my $log = $log->child('perls_installed');
    $log->_6("checking perls installed");

    return $bcmd->installed($brew_info);
}
sub instance_remove {
    my ($self, @perls_installed) = @_;

    my $log = $log->child('instance_remove');

    $log->_6("perls installed: " . join ', ', @perls_installed);
    $log->_0("removing previous installs...");

    my $remove_cmd = $bcmd->remove;

    $log->_4( "using '$remove_cmd' remove command" );

    for (@perls_installed){
        my $using = $bcmd->using( $self->brew_info );

        if ($using eq $_) {
            $log->_5( "skipping version we're using: $using" );
            next;
        }

        $log->_5( "exec'ing $remove_cmd $_" );

        if ($bcmd->is_win) {
            `$remove_cmd $_ 2>nul`;
        }
        else {
            `$remove_cmd $_ 2>/dev/null`;

        }
    }

    $log->_4("removal of existing perl installs complete...");
}
sub instance_install {
    my ($self, $new, $perls_available, $perls_installed) = @_;

    my $log = $log->child('instance_install');

    my $install_cmd = $bcmd->install;

    my @new_installs;

    if ($self->{args}{version}->[0]){
        for my $version (@{ $self->{args}{version} }){
            if (grep { $version eq $_ } @{ $perls_installed }){
                $log->_6("$version is already installed... skipping");
                next;
            }
            push @new_installs, $version;
        }
    }
    else {
        if ($new){

            $log->_5("looking to install $new perl instance(s)");

            while ($new > 0){

                my $candidate = $perls_available->[rand @{ $perls_available }];

                if (grep { $_ eq $candidate } @{ $perls_installed }) {
                    $log->_6( "$candidate already installed... skipping" );
                    next;
                }

                push @new_installs, $candidate;
                $new--;
            }
        }
    }

    if (@new_installs){
        $log->_4("preparing to install..." . join ', ', @new_installs);

        for my $ver (@new_installs){
            $log->_0("installing $ver...");
            $log->_5("...using cmd: $install_cmd");
            `$install_cmd $ver`;
        }
    }
    else {
        $log->_5("using existing versions only");
    }
}
sub results {
    my $self = shift;

    my $log = $log->child('results');

    local $SIG{__WARN__} = sub {};
    $log->_6("warnings trapped locally");

    my $result = $self->exec;

    $log->_7("\n*****\n$result\n*****");

    my @ver_results = $result =~ /[Pp]erl-\d\.\d+\.\d+(?:_\w+)?\s+===.*?(?=(?:[Pp]erl-\d\.\d+\.\d+(?:_\w+)?\s+===|$))/gs;

    $log->_5("got " . scalar @ver_results . " results");

    my (@pass, @fail);

    for (@ver_results){
        my $ver;

        if (/^([Pp]erl-\d\.\d+\.\d+)/){
            $ver = $1;
            $ver =~ s/[Pp]erl-//;
        }
        my $res;

        if (/Successfully tested /){
            $log->_6("$ver PASSED...");
            $res = 'PASS';
            push @pass, "$ver :: $res\n";
        }
        else {
            $log->_6("$ver FAILED...");
            $res = 'FAIL';
            push @fail, "$ver :: $res\n";

            my $tested_mod = $self->{args}{plugin_arg};

            if (defined $tested_mod){
                $tested_mod =~ s/::/-/g;
                open my $wfh, '>', "$tested_mod-$ver.bblog"  or die $!;
                print $wfh $_;
                close $wfh;
            }
            else {
                open my $wfh, '>', "$ver.bblog"  or die $!;
                print $wfh $_;
                close $wfh;
            }
        }
    }

    print "\n";
    print "$self->{args}{plugin_arg}\n" if $self->{args}{plugin_arg};
    print $_ for @pass;
    print $_ for @fail;

    $log->_5(__PACKAGE__ ." run finished");
}
sub run {
    my $self = shift;

    my $new = defined $self->{args}{new} ? $self->{args}{new} : 0;

    my $log = $log->child('run');
    $log->_5("commencing run()");

    my $brew_info = $self->brew_info;

    my @perls_available = $self->perls_available($brew_info);

    $new = scalar @perls_available if $new < 0;

    my @perls_installed = $self->perls_installed($brew_info);

    $log->_4("installed perls: " . join ', ', @perls_installed);

    if ($self->{args}{remove}){
        $self->instance_remove(@perls_installed);

    }

    if ($new || $self->{args}{version}) {
        $self->instance_install($new, \@perls_available, \@perls_installed);
    }

    # refetch $brew_info in case we have installed a new one

    @perls_installed = $self->perls_installed($self->brew_info);

    if (! $perls_installed[0]){
        $log->_0("no perls installed... exiting");
        print "no perls installed... exiting" if $log->level;
    }
    else {
        $self->results();
    }
}
sub exec {
    my $self = shift;

    my $log = $log->child('exec');

    $log->_6("creating temp file");

    my $wfh = File::Temp->new(UNLINK => 1);
    my $fname = $wfh->filename;

    $log->_6("temp filename: $fname");
    if ($self->{args}{plugin_arg}) {
        $log->_5( "fetching instructions from the plugin with arg $self->{args}{plugin_arg}" );
    }
    
    my @exec_cmd = $self->{exec_plugin}->(
        __PACKAGE__,
        $self->log,
        $self->{args}{plugin_arg}
    );

    $log->_6("instructions to be executed:\n" . join ', ', @exec_cmd);

    for (@exec_cmd){
        $log->_6($_);
        print $wfh $_;
    }
    close $wfh;

    $log->_6("temp file handle closed");

    my $brew = $bcmd->brew;

    if ($self->{args}{on}){
        my $vers = join ',', @{ $self->{args}{on} };
        $log->_5("versions to run on: $vers");
        $log->_5("exec'ing: $brew exec --with $vers perl $fname");

        if ($bcmd->is_win){
            return `$brew exec --with $vers perl $fname 2>brewbuild_err.bblog`;

        }
        else {
            return `$brew exec --with $vers perl $fname 2>brewbuild_err.bblog`;
        }
    }
    else {
        $log->_5("exec'ing: $brew exec perl $fname");

        if ($bcmd->is_win) {
            return `$brew exec perl $fname 2>brewbuild_err.bblog`;
        }
        else {
            return `$brew exec perl $fname 2>brewbuild_err.bblog`;
        }
    }
}
sub brew_info {
    my $self = shift;

    my $log = $log->child('brew_info');

    my $brew_info = $bcmd->available;

    $log->_6("brew info set to:\n$brew_info") if $brew_info;

    return $brew_info;
}
sub _create_log {
    my ($self, $level) = @_;

    $self->{log} = Logging::Simple->new(
        name  => 'Test::BrewBuild',
        level => defined $level ? $level : 0,
    );

    $self->{log}->_6("in _create_log()");

    if ($self->{log}->level < 6){
        $self->{log}->display(0);
        $self->{log}->custom_display("-");
        $self->{log}->_5("set log level to " . defined $level ? $level : 0);
    }

    return $self->{log};
}
sub log {
    my $self = shift;
    $self->{log}->_6(ref($self) ." class/obj retrieving a log object");
    return $self->{log};
}
sub is_win {
    my $is_win = ($^O =~ /Win/) ? 1 : 0;
    return $is_win;
}
1;

=head1 NAME

Test::BrewBuild - Perl/Berry brew unit testing automation across installed perl
versions (Windows and Unix).

=for html
<a href="http://travis-ci.org/stevieb9/p5-test-brewbuild"><img src="https://secure.travis-ci.org/stevieb9/p5-test-brewbuild.png"/>
<a href='https://coveralls.io/github/stevieb9/p5-test-brewbuild?branch=master'><img src='https://coveralls.io/repos/stevieb9/p5-test-brewbuild/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>


=head1 DESCRIPTION

This module is the backend for the C<brewbuild> script that is accompanied by
this module. For almost all cases, you should be using that script instead of
using this module directly (so go read that documentation for real use cases),
as this module is just a helper for the installed script, and isn't designed
for end-user use.

It provides you the ability to perform your unit tests across all of your
Perlbrew (Unix) or Berrybrew (Windows) Perl instances.

For Windows, you'll need to install Berrybrew (see L<SEE ALSO> for details).
For Unix, you'll need Perlbrew.

It allows you to remove and reinstall on each test run, install random versions
of perl, or install specific versions.

All unit tests are run against all installed instances.



=head1 SYNOPSIS

    use Test::BrewBuild;

    # default settings

    my %args = (
        debug   => undef,
        remove  => undef,
        version => undef,
        new     => undef,
        plugin  => undef,
        on      => undef,
    );

    my $bb = Test::BrewBuild->new(%args);

    my @perls_available = $bb->perls_available;
    my @perls_installed = $bb->perls_installed;

    # remove all currently installed instances of perl, less the one you're
    # using

    $bb->instance_remove;

    # install a specific version (uses 'version' param, or 'new'. If 'new'
    # is set to a positive integer, we'll randomly install that many instances)

    $bb->instance_install;

    # execute across all perl instances, and dump the output

    $bb->run;

=head1 METHODS

=head2 new(%args)

Returns a new C<Test::BrewBuild> object. See the documentation for the
C<berrybrew> script to understand what the arguments are and do.

=head2 plugin('Module::Name')

Fetches and installs a custom plugin which contains the code that
C<perlbrew/berrybrew exec> will execute. If not used or the module specified
can't be located (or it contains errors), we fall back to the default bundled
L<Test::BrewBuild::Plugin::DefaultExec> (which is the canonical example for
writing new plugins).

Note that you can send in a custom plugin C<*.pm> filename to plugin as opposed
to a module name if the module isn't installed. If the file isn't in the
current working directory, send in the relative or full path.

=head2 perls_available

Returns an array containing all perls available, whether already installed or
not.

=head2 perls_installed

Returns an array of the names of all perls currently installed under your *brew
setup.

=head2 instance_install

If 'version' param is set, will install that specific version. If 'new' param
is set to a positive integer, will install that many random versions of perl.

=head2 instance_remove

Uninstalls all currently installed perls, less the one you are currently
'switch'ed or 'use'd to.

=head2 run

Prepares the run and calls C<exec()> to run all tests against all installed
perls.

=head2 results

Only called by C<run()>. Processes and displayes test results.

=head2 exec

Generates the test executable in a format ready to run against all installed
perls, and processes it against C<*brew exec>.

=head2 is_win

Helper method, returns true if the current OS is Windows, false if not.

=head2 brew_info

Helper method, returns the appropriate *brew calls relative to the platform
we're working on.

=head2 log

Developer method, returns an instance of the packages log object for creating
child log objects.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 CONTRIBUTING

Any and all feedback and help is appreciated. A Pull Request is the preferred
method of receiving changes (L<https://github.com/stevieb9/p5-test-brewbuild>),
but regular patches through the bug tracker, or even just email discussions are
welcomed.

=head1 BUGS

L<https://github.com/stevieb9/p5-test-brewbuild/issues>

=head1 SUPPORT

You can find documentation for this module and its accompanying script with the
perldoc command:

    perldoc Test::BrewBuild

    perldoc brewbuild

=head1 SEE ALSO

Berrybrew for Windows:

L<https://github.com/dnmfarrell/berrybrew>

Perlbrew for Unixes:

L<http://perlbrew.pl>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1;
