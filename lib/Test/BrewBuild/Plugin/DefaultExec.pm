package Test::BrewBuild::Plugin::DefaultExec;

# default exec command set plugin for Test::BrewBuild

our $VERSION = '0.05';

sub brewbuild_exec {
    return <DATA>;
}

1;

__DATA__
if ($^O eq 'MSWin32'){
    my $make = -e 'Makefile.PL' ? 'dmake' : 'Build';
    system "cpanm --installdeps . && $make && $make test";
}
else {
    my $make = -e 'Makefile.PL' ? 'make' : './Build';
    system "cpanm --installdeps . && $make && $make test";
}
