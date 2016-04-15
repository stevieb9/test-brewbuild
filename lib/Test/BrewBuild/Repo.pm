package Test::BrewBuild::Repo;
use strict;
use warnings;

use Carp qw(croak);
use Capture::Tiny qw(:all);

our $VERSION = '1.05';

sub new {
    return bless {}, shift;
}
sub git {
    my $self = shift;
    my $cmd = $^O =~ /MSWin/
        ? (split /\n/, `where git.exe`)[0]
        : 'git';
    return $cmd;
}
sub link {
    my $self = shift;
    my $git = $self->git;
    return (split /\n/, `"$git" config --get remote.origin.url`)[0];
}
sub name {
    my ($self, $repo) = @_;
    if ($repo =~ m!.*/(.*?)(?:\.git)*$!){
        return $1;
    }
}
sub clone {
    my ($self, $repo) = @_;
    my $git = $self->git;

    my $output = capture_merged {
        `"$git" clone $repo`;
    };
    return $output;
}
sub pull {
    my $self = shift;
    my $git = $self->git;

    my $output = capture_stdout {
        `"$git" pull`;
    };
    return $output;
}
1;

=head1 NAME

Test::BrewBuild::Repo - Git repository manager for the L<Test::BrewBuild> test
platform system.

=head1 DESCRIPTION

Manages Git repositories, including gathering names, cloning, pulling etc.

=head1 METHODS

=head2 new

Returns a new C<Test::BrewBuild::Repo> object.

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
 
