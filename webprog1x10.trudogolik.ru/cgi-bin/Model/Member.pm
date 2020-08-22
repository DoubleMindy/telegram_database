#!/usr/bin/perl -w

use lib '.';

require DataBaseConnecter;
use autouse 'Data::Dumper' => qw(Dumper);


package Model::Member;
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

  sub db_select_id
  { 
    my ($this, $column) = @_;  
    my $sth = $db_obj->exec( "SELECT id FROM " . get_table('group_id') . 
                             " WHERE tg_id = ?", $column
                           )->fetchrow_array;
    return $sth;
  }


  sub db_select_where
  {  
    my ($this, $group_inner_id) = @_;

    my $sth = $db_obj->exec( " SELECT id, first_name, username FROM " . get_table('student') .
                             " WHERE group_id = ?
                               ORDER BY username", $group_inner_id
                        )->fetchall_arrayref({});
    return $sth;
  }

}

return 1;