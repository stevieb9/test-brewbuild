package Test::BrewBuild;
use strict;
use warnings;

use Carp qw(croak);

use File::Copy;
use File::Copy::Recursive qw(dircopy);
use File::Find;
use File::Path qw(remove_tree);
use File::Temp;
use Logging::Simple;
use Module::Load;
use Plugin::Simple default => 'Test::BrewBuild::Plugin::DefaultExec';
use Test::BrewBuild::BrewCommands;
use Test::BrewBuild::Dispatch;
use Test::BrewBuild::Tester;

our $VERSION = '1.05';

BEGIN {
   remove_tree 'bblog' or die "can't remove bblog/\n" if -d 'bblog';
}
my $log;
my $bcmd;

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    %{ $self->{args} } = %args;

    $log = $self->_create_log($args{debug});
    $log->_6("in new(), constructing " . __PACKAGE__ . " object");

    $bcmd = Test::BrewBuild::BrewCommands->new($log);

    $self->_set_plugin();

    $self->tempdir;
    $log->_7("using temp bblog dir: " . $self->tempdir);

    return $self;
}
sub brew_info {
    my $self = shift;

    my $log = $log->child('brew_info');

    my $brew_info = $bcmd->info;

    $log->_6("brew info set to:\n$brew_info") if $brew_info;

    return $brew_info;
}
sub perls_available {
    my ($self, $brew_info) = @_;

    my $log = $log->child('perls_available');

    my @perls_available = $bcmd->available($self->{args}{legacy}, $brew_info);

    $log->_6("perls available: " . join ', ', @perls_available);

    return @perls_available;
}
sub perls_installed {
    my ($self, $brew_info) = @_;

    my $log = $log->child('perls_installed');
    $log->_6("checking perls installed");

    return $bcmd->installed($self->{args}{legacy}, $brew_info);
}
sub instance_install {
    my ($self, $new, $perls_available, $perls_installed) = @_;

    my $log = $log->child('instance_install');

    my $install_cmd = $bcmd->install;

    my @new_installs;

    if ($self->{args}{install}->[0]){
        for my $version (@{ $self->{args}{install} }){
            $version = "perl-$version" if ! $self->is_win && $version !~ /perl/;
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
sub instance_remove {
    my ($self, @perls_installed) = @_;

    my $log = $log->child('instance_remove');

    $log->_6("perls installed: " . join ', ', @perls_installed);
    $log->_0("removing previous installs...");

    my $remove_cmd = $bcmd->remove;

    $log->_4( "using '$remove_cmd' remove command" );

    for my $installed_perl (@perls_installed){

        my $using = $bcmd->using( $self->brew_info );

        if ($using eq $installed_perl) {
            $log->_5( "not removing version we're using: $using" );
            next;
        }

        $log->_5( "exec'ing $remove_cmd $installed_perl" );

        if ($bcmd->is_win) {
            `$remove_cmd $installed_perl 2>nul`;
        }
        else {
            `$remove_cmd $installed_perl 2>/dev/null`;

        }
    }

    $log->_4("removal of existing perl installs complete...");
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

    if ($new || $self->{args}{install}) {
        $self->instance_install($new, \@perls_available, \@perls_installed);
    }

    # refetch installed in case we have installed a new instance

    @perls_installed = $self->perls_installed($self->brew_info);

    if (! $perls_installed[0]){
        $log->_0("no perls installed... exiting");
    }
    else {
        if ($self->{args}{revdep}){
            delete $self->{args}{revdep};
            return $self->revdep(%{ $self->{args} });
        }
        else {
            return $self->test;
        }
    }
}
sub test {
    my $self = shift;

    exit if $self->{args}{notest};

    my $log = $log->child('test');

    local $SIG{__WARN__} = sub {};
    $log->_6("warnings trapped locally");

    my $failed = 0;

    my $results = $self->exec;

    $log->_7("\n*****\n$results\n*****");

    my @ver_results = $results =~ /
        [Pp]erl-\d\.\d+\.\d+(?:_\w+)?\s+===
        .*?
        (?=(?:[Pp]erl-\d\.\d+\.\d+(?:_\w+)?\s+===|$))
        /gsx;

    $log->_5("got " . scalar @ver_results . " results");

    my (@pass, @fail);

    for my $result (@ver_results){
        my $ver;

        if ($result =~ /^([Pp]erl-\d\.\d+\.\d+)/){
            $ver = $1;
            $ver =~ s/[Pp]erl-//;
        }
        my $res;

        if ($result =~ /Successfully tested / && $result !~ /FAIL/){
            $log->_6("$ver PASSED...");
            $res = 'PASS';
            push @pass, "$ver :: $res\n";
        }
        else {
            $log->_6("$ver FAILED...");
            $res = 'FAIL';
            $failed = 1;
            push @fail, "$ver :: $res\n";

            my $tested_mod = $self->{args}{plugin_arg};

            if (defined $tested_mod){
                $tested_mod =~ s/::/-/g;
                my $fail_log = "$self->{tempdir}/$tested_mod-$ver.bblog";
                open my $wfh, '>', $fail_log, or die $!;

                print $wfh $result;

                if (! $self->is_win){
                    my %errors = $self->_process_stderr;

                    if (defined $errors{0}){
                        print $wfh "\nCPANM ERROR LOG\n";
                        print $wfh "===============\n";
                        print $wfh $errors{0};
                    }
                    else {
                        for (keys %errors){
                            if (version->parse($_) == version->parse($ver)){
                                print $wfh "\nCPANM ERROR LOG\n";
                                print $wfh "===============\n";
                                print $wfh $errors{$_};
                            }
                        }
                    }
                }
                close $wfh;
                $self->_attach_build_log($fail_log);
            }
            else {
                my $fail_log = "$self->{tempdir}/$ver.bblog";
                open my $wfh, '>', $fail_log or die $!;
                print $wfh $result;

                if (! $self->is_win){
                    my %errors = $self->_process_stderr;
                    for (keys %errors){
                        if (version->parse($_) == version->parse($ver)){
                            print $wfh "\nCPANM ERROR LOG\n";
                            print $wfh "===============\n";
                            print $wfh $errors{$_};
                        }
                    }
                }
                close $wfh;
                $self->_attach_build_log($fail_log) if ! $self->is_win;
            }
        }
    }

    $self->_copy_logs;

    $log->_5(__PACKAGE__ ." run finished");

    my $ret = "\n";
    $ret .= "$self->{args}{plugin_arg}\n" if $self->{args}{plugin_arg};
    $ret .= $_ for @pass;
    $ret .= $_ for @fail;

    return $ret;
}
sub exec {
    my $self = shift;

    my $log = $log->child('exec');

    $log->_6("creating temp file");

    if ($self->{args}{plugin_arg}) {
        $log->_5( "" .
            "fetching instructions from the plugin with arg " .
            $self->{args}{plugin_arg}
        );
    }
    
    my @exec_cmd = $self->{exec_plugin}->(
        __PACKAGE__,
        $self->log,
        $self->{args}{plugin_arg}
    );

    $log->_6("instructions to be executed:\n" . join ', ', @exec_cmd);

    my $brew = $bcmd->brew;

    if ($self->{args}{on}){
        my $vers = join ',', @{ $self->{args}{on} };
        $log->_5("versions to run on: $vers");
        $log->_5("exec'ing: $brew exec --with $vers " . join ', ', @exec_cmd);

        my $wfh = File::Temp->new(UNLINK => 1);
        my $fname = $wfh->filename;
        open $wfh, '>', $fname or die $!;
        for (@exec_cmd){
            s/\n//g;
        }
        my $cmd = join ' && ', @exec_cmd;
        $cmd = "system(\"$cmd\")";
        print $wfh $cmd;
        close $wfh;

        $self->_dzil_shim($fname);
        return `$brew exec --with $vers perl $fname 2>$self->{tempdir}/stderr.bblog`;
        $self->_dzil_unshim if $self->{is_dzil};
    }
    else {
        $log->_5("exec'ing: $brew exec:\n". join ', ', @exec_cmd);

        if ($bcmd->is_win){

            # all of this shit because berrybrew doesn't get the path right
            # when calling ``berrybrew exec perl ...''

            my %res_hash;

            $self->_dzil_shim;

            for (@exec_cmd){
                my $res = `$brew exec $_`;

                my @results = $res =~ /
                    [Pp]erl-\d\.\d+\.\d+(?:_\w+)?\s+===
                    .*?
                    (?=(?:[Pp]erl-\d\.\d+\.\d+(?:_\w+)?\s+===|$))
                    /gsx;

                for (@results){
                    if ($_ =~ /
                        ([Pp]erl-\d\.\d+\.\d+(?:_\w+)?\s+=+?)
                        (\s+.*?)
                        (?=(?:[Pp]erl-\d\.\d+\.\d+(?:_\w+)?\s+===|$))
                        /gsx)
                    {
                        push @{ $res_hash{$1} }, $2;
                    }
                }
            }

            $self->_dzil_unshim if $self->{is_dzil};

            my $result;

            for (keys %res_hash){
                $result .= $_ . join '', @{ $res_hash{$_} };
            }

            return $result;
        }
        else {
            my $wfh = File::Temp->new(UNLINK => 1);
            my $fname = $wfh->filename;
            open $wfh, '>', $fname or die $!;
            for (@exec_cmd){
                s/\n//g;
            }
            my $cmd = join ' && ', @exec_cmd;
            $cmd = "system(\"$cmd\")";
            print $wfh $cmd;
            close $wfh;

            $self->_dzil_shim($fname);
            return `$brew exec perl $fname 2>$self->{tempdir}/stderr.bblog`;
            $self->_dzil_unshim if $self->{is_dzil};
        }
    }
}
sub tempdir {
    my $self = shift;
    return $self->{tempdir} if $self->{tempdir};

    my $dir = File::Temp->newdir;
    my $dir_name = $dir->dirname;
    $self->{temp_handle} = $dir;
    $self->{tempdir} = $dir_name;
    return $self->{tempdir};
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

sub revdep {
    my ($self, %args) = @_;

    delete $self->{args}{args};

    # these args should only be exercised on first call

    delete $args{revdep};

    delete $self->{args}{delete};
    delete $args{remove};
    delete $args{install};
    delete $args{new};

    $args{plugin} = 'Test::BrewBuild::Plugin::TestAgainst';

    my @revdeps = $self->revdeps;

    my @ret;

    my $rlist = "\nreverse dependencies: " . join ', ', @revdeps;
    $rlist .= "\n\n";
    push @ret, $rlist;

    for (@revdeps){
        $args{plugin_arg} = $_;
        my $bb = __PACKAGE__->new(%args);
        push @ret, $bb->run;
    }
    return \@ret;
}
sub revdeps {
    my $self = shift;

    my $log = $log->child('revdeps');
    $log->_6('running --revdep');

    load 'CPAN::ReverseDependencies';

    my @modules;

    find({
            wanted => sub {
                $log->_7("finding modules");
                if (-f && $_ =~ /\.pm$/){
                    push @modules, $_;
                }
            },
            no_chdir => 1,
        },
        'lib/'
    );

    my $mod = $modules[0];

    $log->_7("using '$mod' as the project we're working on");

    $mod =~ s|lib/||;
    $mod =~ s|/|-|g;
    $mod =~ s|\.pm||;

    $log->_7("working module translated to $mod");

    my $rvdep = CPAN::ReverseDependencies->new;
    my @revdeps = $rvdep->get_reverse_dependencies($mod);

    @revdeps = grep {$_ ne 'Test-BrewBuild'} @revdeps;

    for (@revdeps){
        s/-/::/g;
    }

    return @revdeps;
}
sub setup {
    print "\n";
    my @setup = <DATA>;
    print $_ for @setup;
    exit;
}
sub help {
     print <<EOF;

Usage: brewbuild [OPTIONS]

Local usage options:

-o | --on       Perl version number to run against (can be supplied multiple times). Can not be used on Windows
-R | --revdep   Run tests, install, then run tests on all CPAN reverse dependency modules
-n | --new      How many random versions of perl to install (-1 to install all)
-r | --remove   Remove all installed perls (less the current one)
-i | --install  Number portion of an available perl version according to "*brew available". Multiple versions can be sent in at once
-N | --notest   Do not run tests. Allows you to --remove and --install without testing
-l | --legacy   Operate on perls < 5.8.x. The default plugins won't work with this flag set if a lower version is installed

Help options:

-s | --setup    Display test platform setup instructions
-h | --help     Print this help message

Special options:

-p | --plugin   Module name of the exec command plugin to use
-a | --args     List of args to pass into the plugin (one arg per loop)
-T | --selftest Testing only: prevent recursive testing on Test::BrewBuild
-d | --debug    0-7, sets logging verbosity, default is 0

EOF
exit;
}
sub _validate_opts {
    my $args = shift;

    my @valid_args = qw(
        on o new n remove r revdep R plugin p args a debug d install i help h
        N notest setup s legacy l selftest T listen L
        tester-port t testers
        );

    my $bad_opt = 0;

    if (@$args) {
        my @args = grep /^-/, @$args;
        for my $arg (@args) {
            $arg =~ s/^-{1,2}//g;
            if (!grep { $arg eq $_ } @valid_args) {
                $bad_opt = 1;
                last;
            }
        }
    }

    help() if $bad_opt;
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
sub _copy_logs {
    my $self = shift;
    dircopy $self->{tempdir}, "bblog" if $self->{tempdir};
    unlink 'bblog/stderr.bblog' if -e 'bblog/stderr.bblog';
}
sub _set_plugin {
    my $self = shift;
    my $log = $log->child('_set_plugin');
    my $plugin = $self->{args}{plugin} ? $self->{args}{plugin} : $ENV{TBB_PLUGIN};

    $log->_5("plugin param set to: " . defined $plugin ? $plugin : 'default');

    $plugin = $self->plugins($plugin, can => ['brewbuild_exec']);

    my $exec_plugin_sub = $plugin .'::brewbuild_exec';
    $self->{exec_plugin} = \&$exec_plugin_sub;

    $log->_4("successfully loaded $plugin plugin");
}
sub _process_stderr {
    my $self = shift;
    
    my $errlog = "$self->{tempdir}/stderr.bblog";

    if (-e $errlog){
        open my $errlog_fh, '<', $errlog or die $!;
    
        my $error_contents;
        {
            local $/ = undef;
            $error_contents = <$errlog_fh>;
        }
        close $errlog_fh;

        my @errors = $error_contents =~ /
                cpanm\s+\(App::cpanminus\)
                .*?
                (?=(?:cpanm\s+\(App::cpanminus\)|$))
            /xgs;

        my %error_map;

        for (@errors){
            if (/cpanm.*?perl\s(5\.\d+)\s/){
                $error_map{$1} = $_;
            }
        }
        
        if (! keys %error_map){
            $error_map{0} = $error_contents;
        }
        return %error_map;
    }
}
sub _attach_build_log {
    my ($self, $bblog) = @_;

    my $bbfile;
    {
        local $/ = undef;
        open my $bblog_fh, '<', $bblog or die $!;
        $bbfile = <$bblog_fh>;
        close $bblog_fh;
    }
    
    if ($bbfile =~ m|failed.*?See\s+(.*?)\s+for details|){
        my $build_log = $1;
        open my $bblog_wfh, '>>', $bblog or die $!;
        print $bblog_wfh "\n\nCPANM BUILD LOG\n";
        print $bblog_wfh "===============\n";

        open my $build_log_fh, '<', $build_log or die $!;

        while (<$build_log_fh>){
            print $bblog_wfh $_;
        }
        close $bblog_wfh;
    }
}
sub _dzil_shim {
    my ($self, $cmd_file) = @_;

    # return early if possible

    return if -e 'Build.PL' || -e 'Makefile.PL';

    return if ! -e 'dist.ini';

    my $path_sep = $self->is_win ? ';' : ':';

    if (! grep {-x "$_/dzil"} split /$path_sep/, $ENV{PATH} ){
        croak "this appears to be a Dist::Zilla module, but the dzil binary " .
              "can't be found\n";
    }

    $self->{is_dzil} = 1;

    open my $fh, '<', 'dist.ini' or die $!;

    my ($dist, $version);

    while (<$fh>){
        if (/^name\s+=\s+(.*)$/){
            $dist = $1;
        }
        if (/^version\s+=\s+(.*)$/){
            $version = $1;
        }
        last if $dist && $version;
    }

    `dzil clean`;
    `dzil build`;

    my $dir = "$dist-$version";
    copy $cmd_file, $dir if defined $cmd_file;
    chdir $dir;
}
sub _dzil_unshim {
    my $self = shift;
    $self->{is_dzil} = 0;
    chdir '..';
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
        on          => undef,
        revdep      => undef,
        new         => undef,
        remove      => undef,
        install     => undef,
        notest      => undef,
        legacy      => undef,
        plugin      => undef,
        plugin_arg  => undef, # derived from ``args''
        selftest    => undef,
        debug       => undef,
        setup       => undef,
        help        => undef,
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

=head2 args(\%args)

Returns 0 if all arguments are valid, and 1 if not.

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

If 'install' param is set, will install that specific version. If 'new' param
is set to a positive integer, will install that many random versions of perl.

=head2 instance_remove

Uninstalls all currently installed perls, less the one you are currently
'switch'ed or 'use'd to.

=head2 run

Prepares the run and calls C<exec()> to run all tests against all installed
perls.

=head2 test

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

=head2 tempdir

Sets up the object with a temporary directory that will be removed after run.

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

__DATA__

Test::BrewBuild test platform configuration guide

*** Unix ***

Install perlbrew and related requirements:
    cpanm App::perlbrew
    perlbrew install-patchperl
    perlbrew install-cpanm

Install and switch to your base perl instance, and install C<Test::BrewBuild>:
    perlbrew install 5.22.1
    perlbrew switch 5.22.1
    cpanm Test::BrewBuild

*** Windows ***

Note that the key here is that your %PATH% must be free and clear of anything
Perl. That means that if you're using an existing box with Strawberry or
ActiveState installed, you *must* remove all traces of them in the PATH
environment variable for ``brewbuild'' to work correctly.

Easiest way to guarantee a working environment is using a clean-slate Windows
server with nothing on it. For a Windows test platform, I mainly used an
Amazon AWS t2.small server.

Download/install git for Windows:
    https://git-scm.com/download/win)

Create a repository directory, and enter it:
    mkdir c:\repos
    cd c:\repos

Clone and configure berrybrew
    git clone https://github.com/dnmfarrell/berrybrew
    cd berrybrew
    bin\berrybrew.exe config (type 'y' when asked to install in PATH)

Close the current CMD window and open a new one to update env vars

Check available perls, and install one that'll become your core base install
    berrybrew available
    berrybrew install 5.22.1_64
    berrybrew switch 5.22.1_64
    close CMD window, and open new one

Make sure it took
    perl -v

Install Test::BrewBuild
    cpanm Test::BrewBuild

