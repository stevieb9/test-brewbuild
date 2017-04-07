package Test::BrewBuild::Git;
use strict;
use warnings;

use Capture::Tiny qw(:all);
use Carp qw(croak);
use Logging::Simple;
use LWP::Simple qw(head);

our $VERSION = '2.14';

my $log;

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;

    $log = Logging::Simple->new(
        name => 'Test::BrewBuild::Git',
        level => 0
    );

    if (defined $args{debug}){
        $log->level($args{debug});
    }

    $log->_5("instantiating new Test::BrewBuild::Git object");

    return $self;
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

    $log->child('git')->_6("git command set to '$cmd'");

    return $cmd;
}
sub link {
    my $self = shift;
    my $git = $self->git;
    my $link = (split /\n/, `"$git" config --get remote.origin.url`)[0];
    $log->child('link')->_6("found $link for the repo");
    return $link
}
sub name {
    my ($self, $repo) = @_;

    $log->child('name')->_6("converting repository link to repo name");

    if ($repo =~ m!.*/(.*?)(?:\.git)*$!){
        $log->child('name')->_6("repo link converted to $1");
        return $1;
    }
}
sub clone {
    my ($self, $repo) = @_;

    $log->child('clone')->_7("initiating remote repo clone");

    if ($repo =~ /http/ && ! head($repo)){
        $log->child('clone')->_2("git clone failed, repo doesn't exist");
        croak "repository $repo doesn't exist; can't clone...\n";
    }

    my $git = $self->git;

    my $output = capture_merged {
        `"$git" clone $repo`;
    };

    return $output;
}
sub pull {
    my $self = shift;
    my $git = $self->git;

    $log->child('clone')->_6("initiating git pull");

    my $output = `"$git" pull`;
    return $output;
}
sub revision {
    my ($self, %args) = @_;

    my $repo = $args{repo} || $self->link;
    my $remote = $args{remote};

    my $git = $self->git;

    $log->child('revision')->_6("initiating git revision");
#    https://api.github.com/repos/$user/$repo/commits

    my $csum;

    if (! $remote) {
        $csum = `$git rev-parse HEAD`;
    }
    else {
        $csum = `$git rev-parse origin/master`;
    }

    chomp $csum;
    return $csum;
}
sub _separate_url {
    my ($self, $repo) = @_;

    if (! defined $repo){
        $repo = $self->link;
    }

    my ($user, $repo_name) = (split /\//, $repo)[-2, -1];

    return ($user, $repo_name);
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

Parameters:

    debug => $level

Optional, Integer. $level vary between 0-7, 0 being the least verbose.

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
 
