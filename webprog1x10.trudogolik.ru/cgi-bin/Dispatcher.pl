#!/usr/bin/perl -w

use lib '.';
use autouse 'Data::Dumper' => qw(Dumper);
require 'io_cgi.pl';

eval
{
  my $io_cgi = 'io_cgi'->new();
  $io_cgi->get_params();

  my $class = $io_cgi->param('class');
  my $event = $io_cgi->param('event');

  my $group_id    = $io_cgi->param('group_id');
  my $group_title = $io_cgi->param('group_title');

  eval "require $class";
  my $obj = $class->new( $group_id, $group_title );
  $obj->$event();

};

# Handler for errors
if ($@)
{
  print "Content-Type: text/html\n";
  print "Charset: windows-1251\n\n";  
  print $@;
}