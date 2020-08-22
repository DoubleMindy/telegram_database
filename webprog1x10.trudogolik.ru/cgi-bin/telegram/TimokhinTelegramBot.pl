use lib '.';

use BotAPI;
use strict;

use autouse 'Data::Dumper' => qw(Dumper);

# This is the bot TOKEN to access the conversations
my $TOKEN = '1386994773:AAF7oMm-xO4rMsKaNj3NCEUFM8DtODSMlTM';

my $api = BotAPI->new( token => $TOKEN );

print "Now you can use it!\n";

# Hash of new members in user_id:first_name format
my %new_members = {};

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
    my $message = $result->{message};

    my $left_chat_member = $message->{left_chat_member};
    
    # If response contains left member, send message
    if(defined $left_chat_member)
    {
      $api->SendMessage(
      {
        chat_id => $message->{chat}->{id},
        text    => "Good luck, $left_chat_member->{first_name}!"
      }
      );
    }

    my $new_chat_member = $message->{new_chat_member};

    # If response contains new member, remember it
    if(defined $new_chat_member)
    {
      $new_members{ $new_chat_member->{id} } = $new_chat_member->{first_name};
    }

    # And if current message was sent from new member, we answer him 
    if ($new_members{ $message->{from}->{id} })
    {
    $api->SendMessage(
      {
        chat_id => $message->{chat}->{id},
        reply_to_msg_id => $message->{from}->{id},
        text    => "Hello, $message->{from}->{first_name}!"
      }
      );

    # So this member is not new anymore
    delete $new_members{ $message->{from}->{id} };
    }
    
    # Keep moving and accumulate current position
    $updateid = ( $result->{update_id} );
    sleep 1;
  }

  # And go on to the next response
  $api->getUpdates( { offset => $updateid + 1 } );
  next;
}