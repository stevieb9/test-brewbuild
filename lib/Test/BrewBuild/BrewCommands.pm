package Test::BrewBuild::BrewCommands;
use strict;
use warnings;

sub new {
    return bless {}, shift;
}
sub brew {
    my $self = shift;
    return $self->is_win ? 'berrybrew' : 'perlbrew';
}
sub installed {
    my ($self, $info) = @_;

    return $self->is_win
    ? $info =~ /(\d\.\d{2}\.\d(?:_\d{2}))(?!=_)\s+\[installed\]/ig
    : $info =~ /i.*?(perl-\d\.\d+\.\d+)/g;
}
sub available {
    my ($self, $info) = @_;

    if ($info) {
        my @avail = $self->is_win
            ? $info =~ /(\d\.\d+\.\d+_\d+)/g
            : $info =~ /(perl-\d\.\d+\.\d+)/g;

        if ($self->is_win) {
            for (@avail) {
                s/perl-//;
            }
        }
        return @avail;
    }
    else {
        return $self->is_win
            ? `berrybrew available`
            : `perlbrew available`;
    }
}
sub install {
    my $self = shift;

    my $install_cmd = $self->is_win
        ? 'berrybrew install'
        : 'perlbrew install --notest -j 4';
}
sub remove {
    my $self = shift;

    return $self->is_win
        ? 'berrybrew remove'
        : 'perlbrew uninstall';
}
sub version {
    my ($self, $ver) = shift;

    return $self->is_win
        ? $ver
        : "perl-$ver";
}
sub is_win {
    my $is_win = ($^O =~ /Win/) ? 1 : 0;
    return $is_win;
}

1;

=head1 NAME

Test::BrewBuild::BrewCommands - Provides Windows/Unix *brew command
translations.

=head1 METHODS

=head2 new

Returns a new Test::BrewBuild::BrewCommands object.

=head2 brew

Returns 'perlbrew' if on Unix, and 'berrybrew' if on Windows.

=head2 installed($info)

Takes the output of '*brew available' in a string form. Returns the currently
installed versions, formatted in a platform specific manner.

=head2 available($info)

Similar to C<installed()>, but returns all perls available.

=head2 install

Returns the current OS's specific *brew install command.

=head2 remove

Returns the current OS's specific *brew remove command.

=head2 version

Returns the platform specific perl version string.

=head2 is_win

Returns 0 if on Unix, and 1 if on Windows.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 CONTRIBUTING

Any and all feedback and help is appreciated. A Pull Request is the preferred
method of receiving changes (L<https://github.com/stevieb9/p5-test-brewbuild>),
but regular patches through the bug tracker, or even just email discussions are
welcomed.

=head1 BUGS

L<https://github.com/stevieb9/p5-test-brewbuild/issues>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

