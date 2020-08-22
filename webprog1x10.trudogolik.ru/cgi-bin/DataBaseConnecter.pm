#!/usr/bin/perl -w

use DBI;
package DataBaseConnecter;
use strict;

use autouse 'Data::Dumper' => qw(Dumper);

my $dbh;
sub new
{
  my $this = shift;
  unless (defined $dbh) 
  {
    $dbh = bless {}, $this;
    my $DBNAME     = "webprog1x10_tgbot";
    my $DBUSERNAME = "webprog1x10_tgbot";
    my $DBPASSWORD = 'VtI2hQJLTTWasRIl';
    my $attr = {PrintError => 0, RaiseError => 0};
    my $data_source = "DBI:mysql:" . $DBNAME . ":localhost";

    $dbh = DBI->connect($data_source, $DBUSERNAME, $DBPASSWORD, $attr);
    if ( !$dbh ) { die $DBI::errstr; }
    $dbh->do( 'SET NAMES cp1251' );
    $dbh->{mysql_auto_reconnect} = 1;
  }
  return $this;
}

sub exec
{
  my ($this, $request, @params) = @_;
  my $sth = $dbh->prepare( $request ) or
     die ("Cannot connect to the database: ".$DBI::errstr."\n");
  my $rv = $sth->execute( @params );
  return $sth;
}

sub disconnect
{
  my $this = shift;
  $dbh->disconnect();
}

return 1;
