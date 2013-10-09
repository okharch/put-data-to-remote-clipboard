# Clipboard module copypasted here
package Clipboard;
our $VERSION = '0.13';
our $driver;

sub copy { my $self = shift; $driver->copy(@_); }
sub cut { goto &copy }
sub paste { my $self = shift; $driver->paste(@_); }

sub bind_os { my $driver = shift; map { $_ => $driver } @_; }
sub find_driver {
    my $self = shift;
    my $os = shift;
    my %drivers = (
        # list stolen from Module::Build, with some modifications (for
        # example, cygwin doesn't count as Unix here, because it will
        # use the Win32 clipboard.)
        bind_os(Xclip => qw(linux bsd$ aix bsdos dec_osf dgux
            dynixptx hpux irix dragonfly machten next os2 sco_sv solaris sunos
            svr4 svr5 unicos unicosmk)),
        bind_os(MacPasteboard => qw(darwin)),
        bind_os(Win32 => qw(mswin ^win cygwin)),
    );
    $os =~ /$_/i && return $drivers{$_} for keys %drivers;
    die "The $os system is not yet supported by Clipboard.pm.  Please email rking\@panoptic.com and tell him about this.\n";
}

sub import {
    my $self = shift;
    my $drv = Clipboard->find_driver($^O);
    #require "Clipboard/$drv.pm";
    $driver = "Clipboard::$drv";
}

package Clipboard::Win32;
my $clip = eval q{use Win32::Clipboard;1};
our $board = $clip?Win32::Clipboard():();
sub copy {
	die "Win32::Clipboard not found!" unless $clip;
    my $self = shift;
    $board->Set($_[0]);
}
sub paste {
	die "Win32::Clipboard not found!" unless $clip;
    my $self = shift;
    $board->Get();
}
package Clipboard::MacPasteboard;
my $clip = eval q{use Mac::Pasteboard;1};
our $board = $clip?Mac::Pasteboard->new():undef;
$board->set( missing_ok => 1 ) if $board;
sub copy {
	die "was not able to find Mac::Pasteboard" unless $board;
    my $self = shift;
    $board->clear();
    $board->copy($_[0]);
}
sub paste {
	die "was not able to find Mac::Pasteboard" unless $board;
    my $self = shift;
    return scalar $board->paste();
}
package Clipboard::Xclip;
sub copy {
    my $self = shift;
    my ($input) = @_;
    $self->copy_to_selection($self->favorite_selection, $input);
}
sub copy_to_selection {
    my $self = shift;
    my ($selection, $input) = @_;
    my $cmd = '|xclip -i -selection '. $selection;
    my $r = open my $exe, $cmd or die "Couldn't run `$cmd`: $!\n";
    print $exe $input;
    close $exe or die "Error closing `$cmd`: $!";
}
sub paste {
    my $self = shift;
    for ($self->all_selections) {
        my $data = $self->paste_from_selection($_); 
        return $data if length $data;
    }
    undef
}
sub paste_from_selection {
    my $self = shift;
    my ($selection) = @_;
    my $cmd = "xclip -o -selection $selection|";
    open my $exe, $cmd or die "Couldn't run `$cmd`: $!\n";
    my $result = join '', <$exe>;
    close $exe or die "Error closing `$cmd`: $!";
    return $result;
}
# This ordering isn't officially verified, but so far seems to work the best:
sub all_selections { qw(primary buffer clipboard secondary) }
sub favorite_selection { my $self = shift; ($self->all_selections)[0] }

# now goes script area
package main;
use strict;
use warnings;
use IO::Socket::INET;

Clipboard->import;

use Getopt::Long;
my $EOL = Clipboard->find_driver($^O) eq 'Win32'?"\015\012":"\n";
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
	Clipboard->copy($data);
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

