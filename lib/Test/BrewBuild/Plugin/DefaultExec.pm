package Test::BrewBuild::Plugin::DefaultExec;

# default exec command set plugin for Test::BrewBuild

our $VERSION = '1.03_03';

sub brewbuild_exec {
    shift; # throw away the class
    my $log = shift;
    my $clog = $log->child( __PACKAGE__.'::brewbuild_exec' );
    $clog->_6( 'performing plugin duties' );

    return <DATA>;
}

1;

=pod

=head1 NAME

Test::BrewBuild::Plugin::DefaultExec - The default 'exec' command plugin.

=head1 SYNOPSIS

To use, if you've actually installed your plugin:

    berrybrew --plugin My::ExecPlugin

If you have it in a local directory (ie. not installed) (note the path can be
relative):

    berrybrew --plugin /path/to/ExecPlugin.pm

Send in arguments to your plugin. The C<--args, -a> flag sets an array. For
each argument, C<brewbuild> is called once, passing in the next element of the
array.

    berrybrew -p My::Plugin --args 1 -a 2

=head1 CREATION

To create a temporary or test plugin, simply create a C<*.pm> file just like
this one with the same subroutine, and in the C<__DATA__> section, include the
code you need executed by C<*brew exec>.

The first argument you will receive is the C<Logging::Simple> log object of
the core C<Test::BrewBuild>. You can ignore this, or create a child and log
throughout your plugin.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=cut

__DATA__
cpanm --installdeps .
cpanm -v --test-only .
