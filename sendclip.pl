#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::INET;
use Getopt::Long;
my $host='127.0.0.1';
my $port=7778;
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
my $req = join "\012",map {chomp;$_} <>;
my $size = $socket->send(pack("L",length($req)).$req);
print STDERR "sent data of length $size\n" if $verbose;
 
# notify server that request has been sent
shutdown($socket, 1);
 
$socket->close();

