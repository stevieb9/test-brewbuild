package Test::BrewBuild::Git;
use strict;
use warnings;

use Capture::Tiny qw(:all);

our $VERSION = '2.10';

sub new {
    return bless {}, shift;
}
sub git {
    my $self = shift;
    my $cmd;

    if ($^O =~ /MSWin/){
        for (split /;/, $ENV{PATH}){
            if (-x "$_/git.exe"){
                $cmd = "$_/git.exe";
                last;
            }
        }
    }
    else {
        $cmd = 'git';
    }
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

    my $output = `"$git" pull`;
#    my $output = capture_merged {
#    };
    return $output;
}
1;

=head1 NAME

Test::BrewBuild::Git - Git repository manager for the C<Test::BrewBuild> test
platform system.

=head1 SYNOPSIS

    use Test::BrewBuild::Git;

    my $git = Test::BrewBuild::Git->new;

    my $repo_link = $git->link;

    my $repo_name = $git->name($link);

    $git->clone($repo_link);

    $git->pull;

=head1 DESCRIPTION

Manages Git repositories, including gathering names, cloning, pulling etc.

=head1 METHODS

=head2 new

Returns a new C<Test::BrewBuild::Git> object.

=head2 git

Returns the C<git> command for the local platform.

=head2 link

Fetches and returns the full link to the master repository from your current
working directory. This is the link you used to originally clone the repo.

=head2 name($link)

Extracts the repo name from the full link path.

=head2 clone($repo)

Clones the repo into the current working directory.

=head2 pull

While in a repository directory, pull down any updates.

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
 
