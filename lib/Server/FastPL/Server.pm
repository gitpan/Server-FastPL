package Server::FastPL::Server;

$VERSION = "1.0.0";

use IO::Socket;
use POSIX qw(:sys_wait_h);
use strict;

=head1 NAME

Server::FastPL::Server -  Add client-server behavior to scripts.

=head1 VERSION

This document refers to version 1.00 of Server::FastPL::Server,
released April 10, 2000.

=head1 SYNOPSIS

   use Server::FastPL::Server
   
   my $fps = new Server::FastPL::Server(NAME=>"Test",MAX_CHILDS=>5,DEBUG=>1);
      
   while ($client = $fps->receive_connect()) {
      ...
   }

=head1 DESCRIPTION

=head2 Overview

This module adds server behavior to non-server scripts. It works by forking your 
script into MAX_CHILDS child processes. Unix sockets are used for communicating
between the server children and the client script (see Server::FastPL::Client). 
The model loosely resembles CGI::Fast.

=head2 Contructor and initialization

$fps = new Server::FastPL::Server(
 # REQUIRED: This is the name of the socket file
 NAME => "Test",
 # Socket files dir. "/tmp/" as default. 
 SOCKET_DIR => "/tmp/",
 # Number of children to fork, 5 as default.
 MAX_CHILDS => 5,      
 # Debug flag for child processes. 0 as default.
 DEBUG => 0 
) || die $!;                     

=head2 Class and object methods

$client = $fps->receive_connect();

This method waits for a connection and returns a FileHandle (a Socket) for
input/output to the server.

=head1 ENVIRONMENT

Signals:

This module uses two signals: USR1 and CHLD. Do not use these in your
script or the server will not work.

Child processes:

The number of running child processes, established by MAX_CHLD, is maintained by 
the mother process.

=head1 DIAGNOSTICS

All error messages are passed to $!. Use it in your script to detect errors.

=head1 BUGS

Currently the environment hash (%ENV) is not automatically passed from 
the client to the server. If you want this functionality you must do this 
yourself (using this object's socket :) .

=head1 FILES

The module creates the folowing files in directory SOCKET_DIR:

=item NAME
The main socket

=item NAME.x
A socket for each child

=item NAME.fifo
Communication between the mother and children processes.

=head1 SEE ALSO

Server::FastPL::Client
IO::Socket

=head1 AUTHOR

Daniel Ruoso
(daniel@ruoso.com)

=head1 COPYRIGHT

Copyright (c) 2000, Daniel Ruoso. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms of Perl itself

=cut

sub _erro {
   my $erro = shift;
   $! = $erro;
   return undef;
}

sub new {
   my $self = shift;
   my $class = ref($self) || $self;
   my %params = @_;
   local $!;
   $self = {};
   bless $self, $class;
   $self->{NAME} = $params{NAME} || return &_erro("You must specify the name of the server.");
   $self->{MAX_CHILDS} = $params{MAX_CHILDS} || 5;
   $self->{SERVER_DEBUG} = $params{SERVER_DEBUG} || $params{DEBUG} || 0;
   $self->{SOCKET_DIR} = $params{SOCKET_DIR} || "/tmp/";
   $self->{MOTHER_PID} = $$;
   
   # STARTING CHILD PROCCESS
   
   $SIG{"CHLD"} = sub {
       my $pid;
       $pid = waitpid(-1, &WNOHANG );  
       if ($pid == -1) {
          # NOTHING TO DO.
       } elsif ($pid > 0) {
          # I WANT TO RESTART THE DIED CHILDREN
	  my $counter = $self->{MOTHER_PIDS}{$pid};
	  $self->{MOTHER_CHILDS}{$counter} = 0;
	  push @{$self->{MOTHER_RESTART}}, $counter;
	  warn "Server::FastPL::Server (".time.")  $self->{NAME}: CHILD $counter DIED, WILL RESTART AT NEXT REQUEST.\n" if $self->{SERVER_DEBUG};
       } else {
          # NOTHING TO DO.
       }
   };
   
   $SIG{"USR1"} = sub {
      if (open (FIFO, "+<".$self->{SOCKET_DIR}.$self->{NAME}.".fifo")) {
          flock(FIFO,2);
	  my @lines = <FIFO>;
	  foreach my $line (@lines) {
	     chomp $line;
	     my ($child,$free) = split(/:/,$line);
	     ${$self->{MOTHER_CHLD}}{$child} = $free;
	     warn "Server::FastPL::Server (".time.")  $self->{NAME}: CHILD $child = $free\n" if $self->{SERVER_DEBUG};
	  }
	  seek (FIFO,0,0);
	  truncate (FIFO,tell(FIFO));
	  close (FIFO);
      }
   };
   
   my $counter;
   for $counter (1..$self->{MAX_CHILDS}) {
      $self->{THIS_SOCKET_NAME} = $self->{SOCKET_DIR}.$self->{NAME}.".".$counter;
      $self->{THIS_SOCKET_NUMBER} = $counter;
      my $pid;
      if ($pid = fork()) {
          ${$self->{MOTHER_PIDS}}{$pid} = $counter;
	  ${$self->{MOTHER_CHLD}}{$counter} = 0;
	  warn "Server::FastPL::Server (".time.")  $self->{NAME}: CREATED CHILD $counter: $pid.\n" if $self->{SERVER_DEBUG};
	  next;
      } elsif (defined $pid) {
          unlink $self->{THIS_SOCKET_NAME};
	  $self->{SOCKET} = IO::Socket::UNIX->new(
	    Local   => $self->{THIS_SOCKET_NAME},
	    Type    => SOCK_STREAM,
	    Listen  => 10,10
	  ) || return &_erro("Error while creating socket ($self->{THIS_SOCKET_NAME}): $@.");
	  return $self;
      } else { return &_erro("Error while forking child number $counter.") }
   }
   # ONLY THE MOTHER PROCCESS GETS HERE
   $self->{MOTHER_SOCKET_NAME} = $self->{SOCKET_DIR}.$self->{NAME};
   unlink $self->{MOTHER_SOCKET_NAME};
   $self->{MOTHER_SOCKET} = IO::Socket::UNIX->new(
       Local  => $self->{MOTHER_SOCKET_NAME},
       Type   => SOCK_STREAM,
       Listen => 10,10
   ) || die;
   
   my $i = 0;
   while ( my $client = $self->{MOTHER_SOCKET}->accept() ) {
       # DO I HAVE TO RESTART CHILDREN ?
       while ( my $counter = shift @{$self->{MOTHER_RESTART}} ) {
           $self->{THIS_SOCKET_NAME} = $self->{SOCKET_DIR}.$self->{NAME}.".".$counter;
	   $self->{THIS_SOCKET_NUMBER} = $counter;
	   my $pid;
	   if ($pid = fork()) {
	       ${$self->{MOTHER_PIDS}}{$pid} = $counter;
	       ${$self->{MOTHER_CHLD}}{$counter} = 0;
	       warn "Server::FastPL::Server (".time.")  $self->{NAME}: CHILD $counter RESTARTED, NOW PID $pid.\n" if $self->{SERVER_DEBUG};
	       next;
	   } elsif (defined $pid) {
	       unlink $self->{THIS_SOCKET_NAME};
	       $self->{SOCKET} = IO::Socket::UNIX->new(
	           Local   => $self->{THIS_SOCKET_NAME},
		   Type    => SOCK_STREAM,
	           Listen  => 10,10
	       ) || return &_erro("Error while creating socket ($self->{THIS_SOCKET_NAME})");
	       return $self;
	   } else {
	       return &_erro("Error while creating socket ($self->{THIS_SOCKET_NAME})");
	   }
       }
       my $atendido = 0;
       while (!$atendido) {
	  $i++;
	  if ($i > $self->{MAX_CHILDS}) {$i = 1};
          if ( ${$self->{MOTHER_CHLD}}{$i} == 1 ) {
	     print $client $self->{SOCKET_DIR}.$self->{NAME}.".".$i."\n";
	     $atendido = 1;
	     last;
	  }
       }
       close $client;
   }   
   exit;
}

sub receive_connect {
   
   my $self = shift;
   
   open (FIFO, ">>".$self->{SOCKET_DIR}.$self->{NAME}.".fifo") || die $!;
   flock (FIFO,2);
   print FIFO $self->{THIS_SOCKET_NUMBER}.":1\n";
   close FIFO;
   warn "Server::FastPL::Server (".time.")  $self->{NAME}: CHILD $self->{THIS_SOCKET_NUMBER} SENDING SIGNAL, SET ONE NOW.\n" if $self->{SERVER_DEBUG};
   kill 'USR1', $self->{MOTHER_PID};
   
   my $client = $self->{SOCKET}->accept();
   
   open (FIFO, ">>".$self->{SOCKET_DIR}.$self->{NAME}.".fifo") || die $!;
   flock (FIFO,2);
   print FIFO $self->{THIS_SOCKET_NUMBER}.":0\n";
   close FIFO;
   warn "Server::FastPL::Server (".time.")  $self->{NAME}: CHILD $self->{THIS_SOCKET_NUMBER} SENDING SIGNAL, SET ZERO NOW.\n" if $self->{SERVER_DEBUG};
   kill 'USR1', $self->{MOTHER_PID};

   return $client;

}



1;
