use warnings;
use strict;

use IO::Socket::INET;
use Storable;

my $sock = new IO::Socket::INET (
    PeerHost => 'localhost',
    PeerPort => 7800,
    Proto => 'tcp',
);
die "can't create socket\n" unless $sock;

$sock->send('cpanm Mock::Sub');

my $recv = Storable::fd_retrieve($sock);

print $$recv;
