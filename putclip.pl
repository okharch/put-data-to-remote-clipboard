use strict;
use warnings;
use IO::Socket::INET;

my $crossplatformclip = eval q{use Clipboard;1};
my $CLIP  = Win32::Clipboard() if !$crossplatformclip && eval q{use Win32::Clipboard;1};
my $EOL = $^O eq 'MSWin32'?"\015\012":"\n";

die "Have no idea how to connect to clipboard" unless $CLIP || $crossplatformclip;

use Getopt::Long;
my $port=7778;
my $verbose;
GetOptions('port=i'=>\$port,'verbose'=>\$verbose);

 
# auto-flush on socket
$| = 1;
 
# creating a listening socket
my $socket = new IO::Socket::INET (
    LocalHost => '0.0.0.0',
    LocalPort => $port,
    Proto => 'tcp',
    Listen => 5,
    Reuse => 1
);
die "cannot create socket $!\n" unless $socket;
print "server waiting for client connection on port $port\n";
 
while(1)
{
    # waiting for a new client connection
    my $client_socket = $socket->accept(); 
    # get information about a newly connected client
    my $client_address = $client_socket->peerhost();
    my $client_port = $client_socket->peerport();
    print "connection from $client_address:$client_port\n"; 
	my $data = get_data($client_socket);
	put_data($data);
    # notify client that response has been sent
    shutdown($client_socket, 1);
}
 
$socket->close();

sub get_data {
	my $client_socket = shift;
	my $data = "";
	$client_socket->recv($data, 4);
	my $length = unpack("L", $data);
	my @data = ();
	while ($length > 0) {
		$data = "";
		my $read_length = $length > 1024? 1024 : $length;
		$client_socket->recv($data, $read_length);
		push @data,$data;
		$length -= $read_length;
	}
	$data = join "",@data;
	$data = join $EOL,split /\012/,$data unless $EOL eq "\012";
	return $data;
}

sub put_data {
	my $data = shift;
	if ($crossplatformclip) {
		Clipboard->copy($data);
	} else {
		$CLIP->Set($data);
	}
}
