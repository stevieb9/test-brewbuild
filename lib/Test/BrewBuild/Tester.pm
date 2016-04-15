package Test::BrewBuild::Tester;
use strict;
use warnings;

use Capture::Tiny qw(:all);
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
    my $self = bless {}, $class;
    $self->{log} = $log;
    $self->_pid_file;
    return $self;
}
sub stop {
    my $self = shift;

    if (! $self->status) {
        print "\nTest::BrewBuild test server is not running...\n";
        return;
    }

    my $pid_file = $self->_pid_file;

    open my $fh, '<', $pid_file or die $!;
    my $pid = <$fh>;
    close $fh;
    print "\nStopping the Test::BrewBuild test server at PID $pid...\n\n";
    kill 'KILL', ($pid);
    unlink $pid_file;
}
sub start {
    my $self = shift;

    my $pid_file = $self->_pid_file;

    if ($self->status){
        my $fh;
        open $fh, '<', $pid_file or die $!;
        my $existing_pid = <$fh>;
        close $fh;

        if ($existing_pid){
            if (kill(0, $existing_pid)){
                die "\nTest::BrewBuild test server already running " .
                    "on PID $existing_pid...\n";
            }
        }
    }

    my ($perl, @args, $work_dir);

    if ($^O =~ /MSWin/){
        $work_dir = 'c:/brewbuild';

        $perl = (split /\n/, `where perl.exe`)[0];
        my $brew = (split /\n/, `where brewbuild`)[0];

        @args = ($brew, '-L');
    }
    else {
        $work_dir = "$ENV{HOME}/brewbuild";

        $perl = 'perl';
        @args = qw(brewbuild -L);
    }

    mkdir $work_dir or die "can't create $work_dir dir: $!" if ! -d $work_dir;
    chdir $work_dir or die "can't change to dir $work_dir: $!";

    my $bg;

    if ($^O =~ /MSWin/){
        $bg = Proc::Background->new($perl, @args);
    }
    else {
        $bg = Proc::Background->new(@args);
    }

    my $pid = $bg->pid;

    my $ip = $self->ip;
    my $port = $self->port;

    print "\nStarted the Test::BrewBuild test server at PID $pid on IP " .
      "address $ip and TCP port $port...\n\n";

    open my $wfh, '>', $pid_file or die $!;
    print $wfh $pid;
    close $wfh;

    # error check for brewbuild

    if ($self->status){
        sleep 1;
        my $fh;
        open $fh, '<', $pid_file or die $!;
        my $existing_pid = <$fh>;
        close $fh;

        if ($existing_pid){
            if (! kill(0, $existing_pid)){
                die "error! run brewbuild -L at the command line and " .
                    "check for failure\n\n";
            }
        }
    }
}
sub status {
    my $self = shift;
    my $pid_file = $self->_pid_file;
    my $status = -f $pid_file ? 1 : 0;
    return $status;
}
sub listen {
    my $self = shift;
    my $log = $self->{log};

    my $sock = new IO::Socket::INET (
        LocalHost => $self->ip,
        LocalPort => $self->port,
        Proto => 'tcp',
        Listen => 5,
        Reuse => 1,
    );
    die "cannot create socket $!\n" unless $sock;

    # working dir

    if ($^O =~ /MSWin/){
        mkdir "c:/brewbuild" if ! -d "c:/brewbuild";
        chdir "c:/brewbuild";
    }
    else {
        mkdir "$ENV{HOME}/brewbuild" if ! -d "$ENV{HOME}/brewbuild";
        chdir "$ENV{HOME}/brewbuild";
    }

    while (1){

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
            my $err = "error: only brewbuild is allowed as a command\n";
            $dispatch->send($err);
            next;
        }
        else{
            shift @args;
            $dispatch->send('ok');
        }

        my $repo = '';
        $dispatch->recv($repo, 1024);
        $res->{repo} = $repo;

        if ($repo){
            my $repo_dir = $self->_clone_repo($repo);
            chdir $repo_dir;

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
sub ip {
    my ($self, $ip) = @_;
    return $self->{ip} if $self->{ip};
    $ip = '0.0.0.0' if ! $ip;
    $self->{ip} = $ip;
}
sub port {
    my ($self, $port) = @_;
    return $self->{port} if $self->{port};
    $port = '7800' if ! defined $port;
    $self->{port} = $port;
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
            my $clone_output = capture_merged { `git clone $repo`; };
        }
        else {
            chdir $1;
            my $pull_output = capture_merged { `git pull`; };
            chdir '..';
        }
        return $1;
    }
}
sub _pid_file {
    my $self = shift;

    return $self->{pid_file} if defined $self->{pid_file};

    $self->{pid_file} = $^O =~ /MSWin/
        ? 'c:/brewbuild/brewbuild.pid'
        : "$ENV{HOME}/brewbuild/brewbuild.pid";
}
1;

=head1 NAME

Test::BrewBuild::Tester - Daemonized testing service for dispatched test run
execution, Windows & Unix.

=head1 DESCRIPTION

This is the helper module for the L<bbtester> daemon/service that listens for
incoming L<brewbuild> dispatcher remote build requests.

It is not designed for end-user use.

=head1 METHODS

=head2 new

Returns a new Test::BrewBuild::Tester object.

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
 
