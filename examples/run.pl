#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use Test::BrewBuild::Listen;
use Win32::Daemon;

Win32::Daemon::RegisterCallbacks( {
        start       =>  \&Callback_Start,
            running     =>  \&Callback_Running,
            stop        =>  \&Callback_Stop,
            pause       =>  \&Callback_Pause,
            continue    =>  \&Callback_Continue,
    } );

my %Context = (
    last_state => SERVICE_STOPPED,
    start_time => time(),
);

my $tester = Test::BrewBuild::Listen->new;

# Start the service passing in a context and
# indicating to callback using the "Running" event
# every 2000 milliseconds (2 seconds).
Win32::Daemon::StartService( \%Context, 2000 );

sub Callback_Running
{
    my( $Event, $Context ) = @_;

    if( SERVICE_RUNNING == Win32::Daemon::State() )
    {
        $tester->listen;
    }
}

sub Callback_Start
{
    my( $Event, $Context ) = @_;
    $Context->{last_state} = SERVICE_RUNNING;
    Win32::Daemon::State( SERVICE_RUNNING );
}

sub Callback_Pause
{
    my( $Event, $Context ) = @_;
    $Context->{last_state} = SERVICE_PAUSED;
    Win32::Daemon::State( SERVICE_PAUSED );
}

sub Callback_Continue
{
    my( $Event, $Context ) = @_;
    $Context->{last_state} = SERVICE_RUNNING;
    Win32::Daemon::State( SERVICE_RUNNING );
}

sub Callback_Stop
{
    my( $Event, $Context ) = @_;
    $Context->{last_state} = SERVICE_STOPPED;
    Win32::Daemon::State( SERVICE_STOPPED );

    # We need to notify the Daemon that we want to stop callbacks and the service.
    Win32::Daemon::StopService();

}