#!/usr/bin/perl -w

use lib '.';
require Model::Member;
use HTML::Template;
use autouse 'Data::Dumper' => qw(Dumper);
require 'io_cgi.pl';
use strict;

package Timokhin_member;
{

  my $member = new Model::Member();
  my $template = HTML::Template->new(filename => 'html/Timokhin_member.html');


  sub new
  {
    my $class = shift;

    my $this = 
    { 
      group_id    => shift, 
      group_title => shift
    };

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
    my $id = shift;
    my $title = shift;

    _throw_page("There is no group in request") unless ( $id || $title );
    return $member->db_select_id( $id );
  }

  sub show_all
  {
    my ($this) = @_;
    my $group_inner_id = _fetch_inner_id( $this->{group_id}, $this->{group_title} );

    my $all_rows = $member->db_select_where( $group_inner_id );
    _throw_page("No member in this groups!") if (scalar @$all_rows == 0);

    $template->param( MEMBER_INFO => $all_rows );
    $template->param( TITLE => $this->{group_title} );

    _throw_page($template->output);
  }
}
return 1;