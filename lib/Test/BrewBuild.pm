package Test::BrewBuild;

use 5.006;
use strict;
use warnings;

use Data::Dumper;
use File::Temp;

our $VERSION = '0.03';

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    %{ $self->{args} } = %args;
    return $self;
}
sub perls_available {
    my ($self, $brew_info) = @_;

    my @perls_available = $self->is_win
        ? $brew_info =~ /(\d\.\d+\.\d+_\d+)/g
        : $brew_info =~ /(perl-\d\.\d+\.\d+)/g;

    if ($self->is_win){
        for (@perls_available){
            s/perl-//;
        }
    }
    return @perls_available;
}
sub perls_installed {
    my ($self, $brew_info) = @_;

    return $self->is_win
        ? $brew_info =~ /(\d\.\d{2}\.\d(?:_\d{2}))(?!=_)\s+\[installed\]/ig
        : $brew_info =~ /i.*?(perl-\d\.\d+\.\d+)/g;
}
sub instance_remove {
    my ($self, @perls_installed) = @_;

    if ($self->{args}{debug}) {
        print "$_\n" for @perls_installed;
        print "\nremoving previous installs...\n";
    }

    my $remove_cmd = $self->is_win
        ? 'berrybrew remove'
        : 'perlbrew uninstall';

    for (@perls_installed){
        my $ver = $^V;
        $ver =~ s/v//;

        if ($_ =~ /$ver$/){
            print "skipping version we're using, $_\n" if $self->{args}{debug};
            next;
        }
        `$remove_cmd $_`;
    }

    print "\nremoval of existing perl installs complete...\n"
      if $self->{args}{debug};
}
sub instance_install {
    my $self = shift;
    my $count = shift;
    my @perls_available = @_;

    my $install_cmd = $self->is_win
        ? 'berrybrew install'
        : 'perlbrew install --notest -j 4';

    my @new_installs;

    if ($self->{args}{version}->[0]){
        for my $version (@{ $self->{args}{version} }){
            $version = $self->is_win
                ? $version
                : "perl-$version";

            push @new_installs, $version;
        }
    }
    else {
        if ($count) {
            while ($count > 0){
                push @new_installs, $perls_available[rand @perls_available];
                $count--;
            }
        }
    }

    if ($self->{args}{debug}){
        print "preparing to install...\n" if @new_installs;
        print "$_\n" for @new_installs;
    }

    if (@new_installs){
        for (@new_installs){
            print "installing $_...\n" if $self->{args}{debug};
            `$install_cmd $_`;
        }
    }
    else {
        print "\nusing existing versions only\n" if $self->{args}{debug};
    }
}
sub results {
    my $self = shift;

    local $SIG{__WARN__} = sub {};

    my $result = $self->exec;

    my @ver_results = $result =~ /[Pp]erl-\d\.\d+\.\d+.*?Result:\s+\w+\n/gs;

    print "\n\n";

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
            print $_;
            exit;
        }
        print "$ver :: $res\n";
    }
}
sub run {
    my $self = shift;
    my $count = shift;

    $count = 0 if ! $count;

    my $brew_info = $self->brew_info;

    my @perls_available = $self->perls_available($brew_info);

    $count = scalar @perls_available if $count < 0;

    my @perls_installed = $self->perls_installed($brew_info);

    if ($self->{args}{debug}){
        print "$_ installed\n" for @perls_installed;
        print "\n";
    }

    $self->instance_remove(@perls_installed) if $self->{args}{reload};
    $self->instance_install($count, @perls_available) if $count;

    $brew_info = $self->brew_info;
    @perls_installed = $self->perls_installed($brew_info);

    if (! @perls_installed) {
        print "no perls installed... exiting\n";
        exit;
    }

    $self->results();
}
sub is_win {
    return $^O =~ /Win/ ? 1 : 0;
}
sub exec {
    my (@a, @b);
    my $self = shift;

    my $wfh = File::Temp->new(UNLINK => 1);
    my $fname = $wfh->filename;

    while(<DATA>){
        print $wfh $_;
    }
    close $wfh;

    my $brew = $self->is_win ? 'berrybrew' : 'perlbrew';
    return `$brew exec perl $fname`;
}
sub brew_info {
    my $self = shift;

    my $brew_info = $self->is_win
        ? `berrybrew available`
        : `perlbrew available`;

    return $brew_info;
}
1;

=head1 NAME

Test::BrewBuild - Perl/Berry brew unit testing automation across installed perl
versions (Windows and Unix).

=head1 SYNOPSIS

You must be in the root directory of the distribution you want to test. Note
that all arguments passed into the script have single-letter counterparts. Also
note that each time the command is run, your unit tests will be run on all
installed *brew instances.

    # run all unit tests against all installed instances with no other action

    brewbuild

    # install three new instances of perl, randomly

    brewbuild --count 3

    # enable debugging, and run against all installed instances (can be used
    # in conjunction with all other args)

    brewbuild --debug

    # remove all perl instances (less the currently used one), install two
    # new random versions, and run tests against all installed perls

    brewbuild --reload --count 2

    # install all available perl versions, and run tests against all of them

    brewbuild --count -1

    # print usage information

    brewbuild --help

    # install a specific version and run tests on all instances (include just
    # the number portion of the version per "perlbrew available" or "berrybrew
    # available"

    brewbuild --version 5.20.3

    # multiple versions can be passed in at once

    brewbuild -v 5.20.3 -v 5.14.4 -v 5.23.5

=head1 DESCRIPTION

The C<brewbuild> script installed by this module allows you to perform your
unit tests across all of your Perlbrew (Unix) or Berrybrew (Windows) Perl
instances.

For Windows, you'll need to install Berrybrew (see L<SEE ALSO> for details).
For Unix, you'll need Perlbrew.

It allows you to remove and reinstall on each test run, install random versions
of perl, or install specific versions.

All unit tests are run against all installed instances.

The actual module is just a helper for the installed script, and isn't designed
for end-user use.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 BUGS

L<https://github.com/stevieb9/p5-test-brewbuild/issues>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::BrewBuild

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

1; # End of Test::BrewBuild

__DATA__
#!/usr/bin/perl
use warnings;
use strict;

if ($^O ne 'MSWin32'){
    system "cpanm --installdeps . && make && make test";
}
else {
    system "cpanm --installdeps . && dmake && dmake test";
}
