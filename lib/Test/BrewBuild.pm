package Test::BrewBuild;
use strict;
use warnings;

use File::Temp;
use Logging::Simple;
use Test::BrewBuild::Plugin;

our $VERSION = '0.05';

my $log;

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    %{ $self->{args} } = %args;

    $log = $self->log($args{debug});
    $log->_7("in new(), constructing " . __PACKAGE__ . " object");

    my $exec_plugin_name = $args{plugin} ? $args{plugin} : $ENV{TBB_PLUGIN};

    if ($exec_plugin_name){
        $log->_7("plugin param set to: $exec_plugin_name");
    }

    $exec_plugin_name = $self->plugin($exec_plugin_name);

    my $exec_plugin_sub = $exec_plugin_name .'::brewbuild_exec';
    $self->{exec_plugin} = \&$exec_plugin_sub;

    $log->_7("using plugin $exec_plugin_name");

    return $self;
}
sub perls_available {
    my ($self, $brew_info) = @_;

    $log->_7("in perls_available()");

    my @perls_available = $self->is_win
        ? $brew_info =~ /(\d\.\d+\.\d+_\d+)/g
        : $brew_info =~ /(perl-\d\.\d+\.\d+)/g;

    $log->_7("perls available: " . join ', ', @perls_available);

    if ($self->is_win){
        for (@perls_available){
            s/perl-//;
        }
    }
    return @perls_available;
}
sub perls_installed {
    my ($self, $brew_info) = @_;

    $log->_7("in perls_installed()");

    return $self->is_win
        ? $brew_info =~ /(\d\.\d{2}\.\d(?:_\d{2}))(?!=_)\s+\[installed\]/ig
        : $brew_info =~ /i.*?(perl-\d\.\d+\.\d+)/g;
}
sub instance_remove {
    my ($self, @perls_installed) = @_;

    $log->_7("in instance_remove()");

    if ($self->{args}{debug}) {
        $log->_5("perls installed: " . join ', ', @perls_installed);
        $log->_5("removing previous installs...");
    }

    my $remove_cmd = $self->is_win
        ? 'berrybrew remove'
        : 'perlbrew uninstall';

    $log->_7("using $remove_cmd remove command");

    for (@perls_installed){
        my $ver = $^V;
        $ver =~ s/v//;

        if ($_ =~ /$ver$/){
            $log->_5("skipping version we're using, $_");
            next;
        }
        `$remove_cmd $_`;
    }

    $log->_5("removal of existing perl installs complete...");
}
sub instance_install {
    my $self = shift;
    my $count = shift;
    my $perls_available = shift;
    my $perls_installed = shift;

    $log->_7("in instance_remove()");

    my $install_cmd = $self->is_win
        ? 'berrybrew install'
        : 'perlbrew install --notest -j 4';

    $log->_7("using $install_cmd install command");

    my @new_installs;

    if ($self->{args}{version}->[0]){
        for my $version (@{ $self->{args}{version} }){
            $version = $self->is_win
                ? $version
                : "perl-$version";

            if (grep { $version eq $_ } @{ $perls_installed }){
                $log->_5("$version is already installed... skipping");
                next;
            }
            push @new_installs, $version;
        }
    }
    else {
        if ($count){
            $log->_7("installing $count perl instances");
            while ($count > 0){
                my $candidate = $perls_available->[rand @{ $perls_available }];
                if (grep { $_ eq $candidate } @{ $perls_installed }) {
                    if ($self->{args}{debug}) {
                        warn "$candidate already installed... skipping\n";
                    }
                    next;
                }
                push @new_installs, $candidate;
                $count--;
            }
        }
    }

    if (@new_installs){
        $log->_5("preparing to install..." . join ', ', @new_installs);

        for my $ver (@new_installs){
            $log->_5("installing $ver...");
            `$install_cmd $ver`;
        }
    }
    else {
        $log->_5("\nusing existing versions only");
    }
}
sub results {
    my $self = shift;

    $log->_7("in results()");

    local $SIG{__WARN__} = sub {};

    my $result = $self->exec;

    my @ver_results = $result =~ /[Pp]erl-\d\.\d+\.\d+.*?Result:\s+\w+\n/gs;

    my @pass;

    for (@ver_results){
        my $ver;

        if (/^([Pp]erl-\d\.\d+\.\d+)/){
            $ver = $1;
        }
        my $res;

        if (/Result:\s+(PASS)/){
            $res = $1;
        }
        else {
            $log->_7("$ver FAIL");
            print $_;
            exit;
        }

        $log->_7("$ver :: $res");
        push @pass, "$ver :: $res\n";
    }

    print "\n";
    print $_ for @pass;

    $log->_7(__PACKAGE__ ."run finished");
}
sub run {
    my $self = shift;
    my $count = shift;

    $count = 0 if ! $count;

    my $brew_info = $self->brew_info;

    my @perls_available = $self->perls_available($brew_info);

    $count = scalar @perls_available if $count < 0;

    my @perls_installed = $self->perls_installed($brew_info);

    $log->_5("installed perls: " . join ', ', @perls_installed);

    $self->instance_remove(@perls_installed) if $self->{args}{remove};
    if ($count) {
        $self->instance_install($count, \@perls_available, \@perls_installed);
    }

    $brew_info = $self->brew_info;
    @perls_installed = $self->perls_installed($brew_info);

    if (! @perls_installed) {
        $log->_0("no perls installed... exiting");
        print "no perls installed... exiting" if $log->level;
        exit;
    }

    $self->results();
}
sub is_win {
    $log->_7("in is_win()");
    return $^O =~ /Win/ ? 1 : 0;
}
sub exec {
    my (@a, @b);
    my $self = shift;

    $log->_7("in exec()");

    my $wfh = File::Temp->new(UNLINK => 1);
    my $fname = $wfh->filename;

    my @exec_cmd = $self->{exec_plugin}->();
    for (@exec_cmd){
        print $wfh $_;
    }
    close $wfh;

    my $brew = $self->is_win ? 'berrybrew' : 'perlbrew';
    return `$brew exec perl $fname`;
}
sub brew_info {
    my $self = shift;

    $log->_7("in brew_info()");

    my $brew_info = $self->is_win
        ? `berrybrew available`
        : `perlbrew available`;

    return $brew_info;
}
sub log {
    my ($self, $level) = @_;

    $self->{log} = Logging::Simple->new(
        name  => 'Test::BrewBuild',
        level => $level,
    );

    $self->{log}->_7("in log()");

    if (defined $level && $level < 6){
        $self->{log}->display(0);
        $self->{log}->custom_display("-");
        $self->{log}->_7("setting log level to $level");
        $self->{log}->_7("log object created with level $level");
    }

    return $self->{log};
}
1;

=head1 NAME

Test::BrewBuild - Perl/Berry brew unit testing automation across installed perl
versions (Windows and Unix).

=for html
<a href="http://travis-ci.org/stevieb9/p5-test-brewbuild"><img src="https://secure.travis-ci.org/stevieb9/p5-test-brewbuild.png"/>
<a href='https://coveralls.io/github/stevieb9/p5-test-brewbuild?branch=master'><img src='https://coveralls.io/repos/stevieb9/p5-test-brewbuild/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>


=head1 DESCRIPTION

This module is the backend for the C<brewbuild> script that is accompanied
this module. For almost all cases, you should be using that script instead of
using this module directly (so go read that documentation for real use cases),
as this module is just a helper for the installed script, and isn't designed
for end-user use.

It facilitates perform your unit tests across all of your Perlbrew (Unix) or
Berrybrew (Windows) Perl instances.

For Windows, you'll need to install Berrybrew (see L<SEE ALSO> for details).
For Unix, you'll need Perlbrew.

It allows you to remove and reinstall on each test run, install random versions
of perl, or install specific versions.

All unit tests are run against all installed instances.



=head1 SYNOPSIS

    use Test::BrewBuild;

    # default settings

    my %args = (
        debug   => 0,
        remove  => 0,
        version => '',
        count   => 0,
    );

    my $bb = Test::BrewBuild->new(%args);

    my @perls_available = $bb->perls_available;
    my @perls_installed = $bb->perls_installed;

    # remove all currently installed instances of perl, less the one you're
    # using

    $bb->instance_remove;

    # install a specific version (uses 'version' param, or 'count'. If 'count'
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

=head2 perls_available

Returns an array containing all perls available, whether already installed or
not.

=head2 perls_installed

Returns an array of the names of all perls currently installed under your *brew
setup.

=head2 instance_install

If 'version' param is set, will install that specific version. If 'count' param
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
