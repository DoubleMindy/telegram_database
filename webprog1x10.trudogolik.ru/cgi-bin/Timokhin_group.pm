#!/usr/bin/perl -w

use lib '.';
require Model::Group;
use HTML::Template;
use autouse 'Data::Dumper' => qw(Dumper);
use strict;

package Timokhin_group;
{

  my $group = new Model::Group();
  my $template = HTML::Template->new(filename => 'html/Timokhin_group.html');

  sub new
  {
    my $class = shift;

    my $this = 
    { 
      group_id    => shift || '', 
      group_title => shift || ''
    };

    bless $this, $class;
    return $this;
  }


  sub get_table
  {
    my ($this) = @_;
    return "webprog1x10_$_[0]"; 
  }

  sub delete_row
  {
    my ($this) = @_;    
    print "DUMPER: $this->{group_id}\n";

    $group->db_delete( $this->{group_id} );
    show_all();
  }

  sub insert_row
  {
    my ($this) = shift;
    my $err = 0;

    # & defined because it converts undef to empty strings

    if( ( $this->{group_id} ) eq "" & ( defined $this->{group_id} ) )
    {
      $err = 1;
    }
    elsif ( $this->{group_id} )
    {
      my $sth = $group->db_select_where($this->{group_id});
      if ( defined $sth )
      {
        $err = 1;
      }

    $group->db_insert($this->{group_id}, $this->{group_title});
    }

    $template->param( ERROR => $err );
    show_all();
  }


  sub show_all
  {
    my ($this) = shift;

    my $all_rows = $group->db_select_all();    

    $template->param( GROUP_INFO => $all_rows );

    print "Content-Type: text/html\n";
    print "Charset: windows-1251\n\n";
    print $template->output;
  }

}
return 1;
