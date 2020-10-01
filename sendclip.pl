#!/usr/bin/env perl
# sendinig STDIN to clipboard
use strict;
use warnings;
use IO::Socket::INET;
use Getopt::Long;
my $host='127.0.0.1';
my $port=7778;
my $max_chunk = 512;
my $verbose;
GetOptions('host=s'=>\$host,'port=i'=>\$port,'verbose'=>\$verbose);

die "please cpecify host to receive clip" unless $host;
 
# auto-flush on socket
$| = 1;
 
# create a connecting socket
my $socket = new IO::Socket::INET (
    PeerHost => $host,
    PeerPort => $port,
    Proto => 'tcp',
);
die "cannot connect to the server $!\n" unless $socket;
print STDERR "connected to the server $host:$port\n" if $verbose;
 
# data to send to a server
while (<>) {
	my $l = length;
	my $i = 0;
	while ($i < $l) {
		$socket->send(substr($_,$i,$max_chunk));
		$i += $max_chunk;
	}
}
 
# notify server that request has been sent
shutdown($socket, 1);
 
$socket->close();

