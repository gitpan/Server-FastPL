package Server::FastPL;

$VERSION = "1.0.2";

use Server::FastPL::Server;
use Server::FastPL::Client;
use sctrict;

=head1 NAME

Server::FastPL - Add client-server behavior to scripts.

=head1 VERSION

This document refers to version 1.00 of Server::FastPL,
released April 10, 2000

=head1 SYNOPSIS

--- server ---

use Server::FastPL;

my $fps = new Server::FastPL(TYPE=>"SERVER",NAME=>"Test");

while ($client = $fps->receive_connect()) {
   ...
}

--- client ---

use Server::FastPL;

my $server = new Server::FastPL(TYPE=>"CLIENT",SERVER=>"/tmp/Test");

...

=head1 DESCRIPTION

=head2 Overview

This module is just a convenience wrapper for Server::FastPL::Server and
Server::FastPL::Client. You might prefer to use these modules instead of this one.

See Server::FastPL::Server and Server::FastPL::Client for instructions.

=head1 SEE ALSO

Server::FastPL::Server;
Server::FastPL::Client;

=head1 COPYRIGHT

Copyright (c) 2000, Daniel Ruoso. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms of Perl itself

=cut

sub new {
  local $!;
  my $self = shift;
  my $class = ref($self) || $self;
  my %params = @_;
  $self = {};
  bless $self, $class;
  if ($params{TYPE} eq "CLIENT") {
     $self = new Server::FastPL::Client(%params);
  } elsif ($params{TYPE} eq "SERVER") {
     $self = new Server::FastPL::Server(%params);
  } else {
     $! = "You must specify TYPE=(SERVER|CLIENT)";
     return undef;
  }
  return $self;
}
