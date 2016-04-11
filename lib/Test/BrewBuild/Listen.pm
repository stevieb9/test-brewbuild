package Test::BrewBuild::Listen;
use strict;
use warnings;

use Carp qw(croak);
use Config;
use Data::Dumper;
use IO::Socket::INET;
use Storable;
use Test::BrewBuild;

our $VERSION = '1.05';

$| = 1;

sub new {
    my $class = shift;
    my $log = shift;
    my $self = bless {log => $log}, $class;
    return $self;
}
sub listen {
    my ($self, $ip, $port) = @_;

    $ip = '0.0.0.0' if ! $ip;
    $port = '7800' if ! $port;

    my $sock = new IO::Socket::INET (
        LocalHost => $ip,
        LocalPort => $port,
        Proto => 'tcp',
        Listen => 5,
        Reuse => 1,
    );
    die "cannot create socket $!\n" unless $sock;

    while (1){
        if ($^O =~ /MSWin/){
            mkdir "c:/brewbuild" if ! -d "c:/brewbuild";
            chdir "c:/brewbuild";
        }

        my $res = {
            platform => $Config{archname},
        };

        my $dispatch = $sock->accept;

        # ack
        my $ack;
        $dispatch->recv($ack, 1024);

        $dispatch->send($ack);

        my $cmd;
        $dispatch->recv($cmd, 1024);
        $res->{cmd} = $cmd;

        my @args = split /\s+/, $cmd;
        if ($args[0] ne 'brewbuild'){
            die "only brewbuild is allowed as a command\n";
        }
        else{
            shift @args;
        }
        $dispatch->send('ok');

        my $repo = '';
        $dispatch->recv($repo, 1024);
        $res->{repo} = $repo;

        if ($repo){
            my $repo_dir = $self->_clone_repo($repo);
            chdir $repo_dir;

            push @args, '--return';
            {
                my %opts = Test::BrewBuild->options(\@args);
                my $bb = Test::BrewBuild->new(%opts);
                $res->{data} = $bb->run;
            }

            if (-d 'bblog'){
                chdir 'bblog';
                my @entries = glob '*';
                for (@entries){
                    next if ! -f || ! /\.bblog/;
                    open my $fh, '<', $_ or die $!;
                    @{ $res->{files}{$_} } = <$fh>;
                    close $fh;
                }
                chdir '..';
            }
            Storable::nstore_fd($res, $dispatch);
            chdir '..';

        }
    }
    $sock->close();
}
sub _clone_repo {
    my ($self, $repo) = @_;

    my $sep = $^O =~ /MSWin/ ? ';' : ':';
    my $git = $^O =~ /MSWin/ ? 'git.exe' : 'git';

    if (!grep { -x "$_/$git"} split /$sep/, $ENV{PATH}) {
        croak "$git not found\n";
    }

    if ($repo =~ m!.*/(.*?)(?:\.git)*$!){
        if (! -d $1){
            my $clone_ok = system("git clone $repo");
        }
        else {
            chdir $1;
            system("git pull");
            chdir '..';
        }
        return $1;
    }
}
1;

=head1 NAME

Test::BrewBuild::Listen - Daemonized testing service for dispatched test run
execution, Windows & Unix.

=head1 DESCRIPTION

This is the helper module for the L<bbtester> daemon/service that listens for
incoming L<brewbuild> dispatcher remote build requests.

It is not designed for end-user use.

=head1 METHODS

=head2 new

Returns a new Test::BrewBuild::Listen object.

=head2 listen($ip, $port)

Sets the IP and TCP ports up to listen on. By default, we listen on all IPs and
TCP port 7800.

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
 
