package Server::FastPL::Client;

$VERSION = "1.0.1";

use IO::Socket;
use strict;

=head1 NAME

Server::FastPL::Client - Client interface for the Server::FastPL::Server module.

=head1 VERSION

This document refers to version 1.00 of Server::FastPL::Client,
released April 10, 2000.

=head1 SYNOPSIS

    use Server::FastPL::Client;
    
    $server = new Server::FastPL::Client(SERVER => "/tmp/Test");
    
    ...

=head1 DESCRIPTION

=head2 Overview

This module provides a socket that serves as the interface between a client
script (using this module) and a server script (using Server::FastPL::Server).

=head2 Constructor and Initialization

$server = new Server::FastPL::Client(SERVER=>"/tmp/Test");

There is only one parameter, "SERVER". The value of this parameter is the
Server::FastPL::Server server socket filename. In truth, the socket
returned is a socket for one of the Server::FastPL::Server child processes.
You can then use this socket for communication between your client and server
scripts.

=head1 SEE ALSO

Server::FastPL::Server

=head1 AUTHOR

Daniel Ruoso
(daniel@ruoso.com)

=head1 COPYRIGHT

Copyright (c) 2000, Daniel Ruoso. All Rights Reserved.
This modules is free software. It may be userd, redistributed
and/or modified under the same terms of Perl itself.

=cut


sub new {
    my $self = shift;
    my $class = ref($self) || $self;
    
    my %params = @_;
    
    my $socket = IO::Socket::UNIX->new(
       Peer => $params{SERVER},
       Type => SOCK_STREAM
    ) || die;
    
    my $redirect = <$socket>;
    close $socket;
    
    chomp $redirect;
    
    my $socket = IO::Socket::UNIX->new(
       Peer => $redirect,
       Type => SOCK_STREAM
    ) || die;
    
    return $socket;
}

1;
