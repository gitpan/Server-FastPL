package Server::FastPL::Client;

$VERSION = do {
   my @r=(q$Revision: 1.00 $=~/\d+/g);
   sprintf "%d."."%02d"x$#r,@r
}; 

use IO::Socket;
use strict;

=head1 NAME

Server::FastPL::Client - A Client to the Server::FastPL::Server module.

=head1 VERSION

This document refers to version 1.00 of Server::FastPL::Client,
released April 10, 2000.

=head1 SYNOPSIS

    use Server::FastPL::Client;
    
    $server = new Server::FastPL::Client(SERVER => "/tmp/Test");
    
    ...

=head1 DESCRIPTION

=head2 Overview

This module connect to a Unix Socket Server, waits for a one line reply that
indicate a new Socket to connect, and then returns the Socket FileHandle to
the definitive server.

=head2 Constructor and Initialization

$server = new Server::FastPL::Client(SERVER=>"/tmp/Teste");

There is only one parameter, SERVER. This indicates the primary socket that
the module will connect, this function returns the socket filehandle of the
definitive server.

=head1 SEE ALSO

Any Information about how it works is on
Server::FastPL::Server

=head1 AUTHOR

Daniel Ruoso
(daniel@ruoso.com)

=head1 COPYRIGHT

Copyright (c) 2000, Daniel Ruoso. All Rights Reserved.
This modules is free software. It may be userd, redistributed
and/or modified under the same terms of Perl itself.

=cut


sub _send_signal {

	my $name = shift;
	open (PIDFILE, "$name.pid") || die "Couldn't open pidfile $name.pid";
	my $pid = <PIDFILE>;
	chomp $pid;
	close PIDFILE;
	kill 'USR2', $pid;
	die "Sent signal to $pid reload.\n";
	
}

sub new {
    my $self = shift;
    my $class = ref($self) || $self;
    
    my %params = @_;
    
    my $socket = IO::Socket::UNIX->new(
       Peer => $params{SERVER},
       Type => SOCK_STREAM
    ) || &_send_signal($params{SERVER});
    
    my $redirect = <$socket>;
    close $socket;
    
    chomp $redirect;
    
    my $socket = IO::Socket::UNIX->new(
       Peer => $redirect,
       Type => SOCK_STREAM
    ) || &_send_signal($redirect);
    
    return $socket;
}

1;
