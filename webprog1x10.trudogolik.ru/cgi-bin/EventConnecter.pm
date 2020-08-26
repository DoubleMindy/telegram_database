#!/usr/bin/perl -w

use lib '.';
use HTML::Template;
use autouse 'Data::Dumper' => qw(Dumper);
use strict;

package EventConnecter;
{

  sub new
  {
    my $class = shift;

    my $this = 
    { 
      classname   => shift,
      group_id    => shift, 
      group_title => shift || ''
    };
    my $filename = "html/Timokhin_" . lc($this->{classname}) . ".html";
    
    eval "require Model::$this->{classname}";
    
    $this->{essence}  = "Model::$this->{classname}"->new();
    $this->{template} = HTML::Template->new(filename => $filename);

    bless $this, $class;
    return $this;
  }
    
  sub _throw_page
  {
    my $data = shift;
    
    print "Content-Type: text/html\n";
    print "Charset: windows-1251\n\n";
    print "$data\n";
    exit; 
  }

  sub _fetch_inner_id
  {
    my ($this) = shift;

    _throw_page("There is no group in request") unless ( $this->{group_id} || $this->{group_title} );
    return $this->{essence}->db_select_id( $this->{group_id} );
  }

  sub delete_row
  {
    my ($this) = @_;    
    if ( ref($this->{group_id}) ne "ARRAY"  )
    {
      $this->{essence}->db_delete( $this->{group_id} );
    }
    else
    {
      my @group_ids = @{ $this->{group_id} };
      foreach my $gr ( @group_ids )
      {
        $this->{essence}->db_delete( $gr );
      }
    }
    $this->show_all();
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
      my $sth = $this->{essence}->db_select_where($this->{group_id});
      if ( defined $sth )
      {
        $err = 1;
      }

    $this->{essence}->db_insert($this->{group_id}, $this->{group_title});
    }

    $this->{template}->param( ERROR => $err );
    $this->show_all();
  }

  sub show_all
  {
    my ($this) = shift;    
    my $all_rows = $this->{essence}->db_select_all();    

    $this->{template}->param( uc( $this->{classname} ) . _INFO => $all_rows );

    _throw_page($this->{template}->output);
  }

  sub filter
  {
    my ($this) = @_;    
    my $group_inner_id = $this->_fetch_inner_id();

    my $all_rows = $this->{essence}->db_select_where( $group_inner_id );

    _throw_page("No " . lc( $this->{classname} ) . " in this groups!") if (scalar @$all_rows == 0);    

    $this->{template}->param( TITLE => $this->{group_title} ); 
    $this->{template}->param( uc( $this->{classname} ) . _INFO => $all_rows );

    _throw_page($this->{template}->output);
  }
}

return 1;