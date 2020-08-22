#!/usr/bin/perl -w

use lib '.';
use autouse 'Data::Dumper' => qw(Dumper);
require 'io_cgi.pl';

  my $io_cgi = 'io_cgi'->new();
  $io_cgi->get_params();

  my $class = $io_cgi->param('class');
  my $event = $io_cgi->param('event');

  my $group_id    = $io_cgi->param('group_id*');
  my $group_title = $io_cgi->param('group_title');

print Dumper $group_id;