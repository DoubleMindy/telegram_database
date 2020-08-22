use lib '.';

use BotAPI;
use strict;

use autouse 'Data::Dumper' => qw(Dumper);
use DBI;

use Time::Piece;
use Date::Parse;

my $DBNAME     = "webprog1x10_tgbot";
my $DBUSERNAME = "webprog1x10_tgbot";
my $DBPASSWORD = 'VtI2hQJLTTWasRIl';
  # This is the bot TOKEN to access the conversations
my $TG_TOKEN   = '1386994773:AAF7oMm-xO4rMsKaNj3NCEUFM8DtODSMlTM',
  # We use admin's username to separate users and admin
my $TG_ADMIN   = "Dina";


sub get_table{ return "webprog1x10_@_[0]"; };

sub find_id_in{ return "(SELECT id FROM " . get_table(@_[0]) . " WHERE @_[1] = ?)" }


my $attr = {PrintError => 1, RaiseError => 1};
my $data_source = "DBI:mysql:" . $DBNAME;

my $dbh = DBI->connect($data_source, $DBUSERNAME, $DBPASSWORD, $attr);
if (!$dbh) { die $DBI::errstr; }
$dbh->do( 'SET NAMES cp1251' );
$dbh->{mysql_auto_reconnect} = 1;

my $api = BotAPI->new( token => $TG_TOKEN );

print "Now you can use it!\n";

# Hash of new members in user_id:first_name format
my %new_members = {};
my %new_groups = {};
my %new_homeworks = {};
my %admins = {};

# Fetch all rows from student-table
my $sth = $dbh->prepare( "SELECT username, first_name FROM " . get_table('student') );
my $rv = $sth->execute;

while( my @row = $sth->fetchrow_array )
{
  # Write all members of group which exists in DB
  $new_members{ @row[0] } = @row[1];
}

$sth = $dbh->prepare( "SELECT tg_id, title FROM " . get_table('group_id') );
$rv = $sth->execute;

while( my @row = $sth->fetchrow_array )
{
  # Write all members of group which exists in DB
  $new_groups{ @row[0] } = @row[1];
}

$sth = $dbh->prepare( "SELECT tag, group_id FROM " . get_table('homework') );
$rv = $sth->execute;

while( my @row = $sth->fetchrow_array )
{
  # Write all members of group which exists in DB
  $new_homeworks{ @row[0] } = @row[1];
}

$sth = $dbh->prepare( "SELECT username, first_name FROM " . get_table('admin') );
$rv = $sth->execute;

while( my @row = $sth->fetchrow_array )
{
  # Write all members of group which exists in DB
  $admins{ @row[0] } = @row[1];
}

# Autolisten mode
while ( 1 ) 
{
  # Listen new response every second
  if ( scalar @{ ( $api->getUpdates->{result} ) } == 0 ) { sleep 1; next; }
  
  # This is tracker of current position in whole getUpdates()-method
  my $updateid;

  # Parse response
  for my $result ( @{ $api->getUpdates->{result} } ) 
  {
    # Homework's done tag
    my $done = 0;

    my $message    = $result->{message};
    my $name       = $message->{from}->{first_name};
    my $uname      = $message->{from}->{username};
    my $user_id    = $message->{from}->{id};
    my $chat_id    = $message->{chat}->{id};
    
    # Check if message contains hashtag (i.e. homework added)
    my $hashed  = $message->{entities}->[0]->{type} eq "hashtag";

    # FOR = USER, ADMIN 
    # Add new group to DB
    unless ( $new_groups{ $chat_id } )
    {
      my $chat_title = $message->{chat}->{title};    
      my $user_count = $api->getChatMembersCount( 
                                                { chat_id => $chat_id } 
                                                )->{result};

      $sth = $dbh->prepare("INSERT INTO " . get_table("group_id") . 
                           " SET title = ?, tg_id = ?, user_count = ?"
                          );
      $rv = $sth->execute($chat_title, $chat_id, $user_count);

      $new_groups{ $chat_id } = $chat_title;
    }

    # FOR = USER 
    # Add student which posts homework at first time
    unless ( $new_members{ $uname } )
    {
      $sth = $dbh->prepare("INSERT INTO " . get_table("student") . 
                           " SET group_id = " . find_id_in("group_id", "tg_id") . 
                             ", first_name = ?, username = ?"
                          );
      $rv = $sth->execute($chat_id, $name, $uname);

      $new_members{ $uname } = $name;
    }

    # If this message is about homework...
    if ( $hashed )
    {
      # We assumed that string begins with #homework<number>
      my ($homework_id) = $message->{text} =~ /(\d+)/;

      # Finding autoincrement group_id 
      $sth = $dbh->prepare( find_id_in("group_id", "tg_id") );
      $rv = $sth->execute($chat_id);
      my $group_inner_id = $sth->fetchrow_array;    

      my $user_status = $api->getChatMember(
                                      { chat_id => $chat_id,
                                        user_id => $user_id
                                      })->{result}->{status};
      # FOR = ADMIN 
      # Add new admin to DB
      if 
      ( 
         ( $user_status eq "creator" || $user_status eq "administrator" )
         & ( not $admins{ $uname } ) 
      )
      {
        $sth = $dbh->prepare("INSERT INTO " . get_table("admin") . 
                             " SET group_id = ?, username = ?, first_name = ?"
                            );
        $rv = $sth->execute($group_inner_id, $uname, $name);
        $admins{ $uname } = $name;       
      }

      # FOR = ADMIN 
      # Add new homework to DB if user is admin
      if ( ( $new_homeworks{ $homework_id } ne $group_inner_id ) & ( $admins{ $uname } eq $name ) )
      { 
        # Find deadline date-time in message (format 31.12.2020 15:00)
        my ($dd, $mm, $yyyy, $hours, $mins) = 
          $message->{text} =~/(\d{2})\.(\d{2})\.(\d{4}) (\d{2})[\-\:](\d{2})/;
        my $date_time = "${yyyy}-${mm}-${dd} ${hours}:${mins}:00";

        # Max score of current homework
        my $current_score = 5;     

        $sth = $dbh->prepare("INSERT INTO " . get_table("homework") . 
                             " SET tag = ?, deadline = ?, max_rate = ?, group_id = ?"
                            );
        $rv = $sth->execute($homework_id, $date_time, $current_score, $group_inner_id);
        $new_homeworks{ $homework_id } = $group_inner_id;
      }
      # FOR = USER 
      else
      {
        # Current homework score
        my $current_rate = 0;
        # Fetching deadline from homeworks table
        $sth = $dbh->prepare("SELECT deadline FROM " . get_table("homework") .
                             " WHERE tag = ? AND group_id IN ?"
                            );
        $rv = $sth->execute($homework_id, $group_inner_id);
        my $deadline = $sth->fetchrow_array;

        # Covert deadline string to timestamp
        $deadline = str2time( $deadline );
        
        # If current homework was added before deadline rate it by maximum score
        if ( $message->{date} < $deadline )
        {
          # Homework was done
          $done++;
          $sth = $dbh->prepare("SELECT max_rate FROM " . get_table("homework") . 
                               " WHERE tag = ? AND group_id IN ?"
                              );
          $rv = $sth->execute($homework_id, $group_inner_id);
          $current_rate = $sth->fetchrow_array;
        }

        # Student's inner id 
        $sth = $dbh->prepare( find_id_in("student", "username") );
        $rv = $sth->execute($chat_id);
        my $student_inner_id = $sth->fetchrow_array;  

        # Add new row to stack table
        $sth = $dbh->prepare("INSERT INTO " . get_table("stack") . 
                             " SET homework_id =  (SELECT id FROM " . get_table("homework") .
                             " WHERE tag = ? AND group_id = ?), 
                                student_id = ?, current_rate = ?, is_done = ?"
                             );
        $rv = $sth->execute($homework_id, $group_inner_id, $student_inner_id, $current_rate, $done);

        # Fetch sum of all rates of current user's homeworks
        $sth = $dbh->prepare("SELECT SUM(current_rate) FROM " . get_table("stack") .  
                             " WHERE student_id = ?" 
                            );
        $rv = $sth->execute($uname, $student_inner_id);
        my $max_score = $sth->fetchrow_array;
        
        # Fetch count of current user's homeworks
        $sth = $dbh->prepare("SELECT SUM(is_done) FROM " . get_table("stack") .  
                             " WHERE student_id = ?"
                            );
        $rv = $sth->execute($uname, $student_inner_id);
        my $hw_done = $sth->fetchrow_array;

        # Set it to student's profile table
        $sth = $dbh->prepare("UPDATE " . get_table("student") .  
                             " SET homeworks_done = ?, score = ?
                               WHERE username = ?");
        $rv = $sth->execute($hw_done, $max_score, $uname);
      }
    }

    # Keep moving and accumulate current position
    $updateid = ( $result->{update_id} );
    sleep 1;
  }

  # And go on to the next response
  $api->getUpdates( { offset => $updateid + 1 } );
  next;
}