#!/usr/bin/perl -w

use lib '.';
require DataBaseConnecter;
use autouse 'Data::Dumper' => qw(Dumper);


package Model::Group;
{
  my $db_obj = DataBaseConnecter->new();

  sub new
  {
    my $class = shift;
    my $this = {}; 
    bless $this, $class;
    return $this;
  }

  sub get_table
  {
    my ($this) = @_;
    return "webprog1x10_$_[0]"; 
  }

  sub db_delete
  {
    my ($this, $group_id) = @_;
    $db_obj->exec( " DELETE FROM " . get_table('group_id') . 
                     " WHERE tg_id =?", $group_id
               );
  }

  sub db_insert
  {
    my ($this, $group_id, $group_title) = @_;
    $db_obj->exec( " INSERT INTO " . get_table('group_id') . 
                   " SET tg_id =?, title = ?", $group_id, $group_title
                  );
  }

  sub db_select_where
  {  
    my ($this, $group_id) = @_;

    my $sth = $db_obj->exec( " SELECT tg_id, title FROM " . get_table('group_id') .
                          " WHERE tg_id = ?
                            ORDER BY tg_id", $group_id
                          )->fetchrow_array;
    return $sth;
  }

  sub db_select_all
  {  
    my ($this) = @_;
    my $sth = $db_obj->exec( 
                          " SELECT tg_id, title FROM " . get_table('group_id')
                          )->fetchall_arrayref({});
    return $sth;

  }
}
return 1;

