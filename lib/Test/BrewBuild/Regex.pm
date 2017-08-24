package Test::BrewBuild::Git;
use strict;
use warnings;

use Capture::Tiny qw(:all);
use Carp qw(croak);
use Logging::Simple;
use LWP::Simple qw(head);

our $VERSION = '2.20';

my $log;

1;

=head1 NAME

Test::BrewBuild::Regex - Various regexen for the Test::BrewBuild platform

=head1 SYNOPSIS

=head1 DESCRIPTION

Single location for all regexen used throughout Test::BrewBuild.

=head1 METHODS

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
 
