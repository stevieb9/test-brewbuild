package Test::BrewBuild::Plugin::DefaultExec;

# default exec command set plugin for Test::BrewBuild

our $VERSION = '0.06';

sub brewbuild_exec {
    return <DATA>;
}

1;

=pod

=head1 NAME

Test::BrewBuild::Plugin::DefaultExec - The default 'exec' command plugin.

=head1 DESCRIPTION

To create a temporary or test plugin, simply create a C<*.pm> file just like
this one with the same subroutine, and in the data section, include the code
you need executed by C<*brew exec>.

To use, if you've actually installed your plugin:

    berrybrew --plugin My::ExecPlugin

If you have it in a local directory (ie. not installed) (note the path can be
relative):

    berrybrew --plugin /path/to/ExecPlugin.pm

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=cut

__DATA__
if ($^O eq 'MSWin32'){
    my $make = -e 'Makefile.PL' ? 'dmake' : 'Build';
    system "cpanm --installdeps . && $make && $make test";
}
else {
    my $make = -e 'Makefile.PL' ? 'make' : './Build';
    system "cpanm --installdeps . && $make && $make test";
}



