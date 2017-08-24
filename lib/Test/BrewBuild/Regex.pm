package Test::BrewBuild::Git;
use strict;
use warnings;

use Carp qw(croak);
use Exporter qw(import);

our $VERSION = '2.20';

our @EXPORT_OK = qw(
    brewbuild
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

my %brewbuild = (
    extract_result => qr{
        [Pp]erl-\d\.\d+\.\d+(?:_\w+)?\s+===
        .*?
        (?=(?:[Pp]erl-\d\.\d+\.\d+(?:_\w+)?\s+===|$))
    },
);

sub brewbuild {
    my $re = shift;
    _check(__SUB__, $re);
    return $brewbuild{$re};
}
sub _check {
    my ($module, $re) = @_;
    croak "regex '$re' doesn't exist for brewbuild()"
      if ! exists $module{$re};
}
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
 

rt
