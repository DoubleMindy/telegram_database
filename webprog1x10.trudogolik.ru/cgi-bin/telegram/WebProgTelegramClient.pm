package WebProgTelegramClient;
use strict;
use Encode;

use IO::Socket::SSL;
use Cpanel::JSON::XS;
use JSON qw(encode_json);
require LWP::UserAgent;
# require S2U::Utils::Encode;
# use HTTP::Cookies;
use HTTP::Request;

# use autouse 'S2U::Utils::Debug' => qw(trace debug);
use autouse 'Data::Dumper' => qw(Dumper);

=pod

=encoding cp1251

=head1 NAME

WebProgTelegramClient - Работа по API с Telegram

=head1 DESCRIPTION

  API
  https://core.telegram.org/bots/api

  Создание бота
  https://habr.com/ru/post/262247/

  Чтобы бот мог читать чат, нужно настроить ему Privacy Mode
  для этого в @BotFather выдаем команду
    /setprivacy

    вводим название бота
    @WebProg1Bot

    выбираем статус
    Disable

=cut

=head2 new(token => XXX)

  my $token = 'XXXX';

  require WebProgTelegramClient;
  my $tg = WebProgTelegramClient->new(token => $token);


=cut
sub new
{
  my $this = shift;
  my %params = @_;
  my $self = {};
  bless($self, $this);

  $self->{_token} = $params{token};
  $self->{_request_url} = 'https://api.telegram.org/bot'.$self->{_token};

  return $self;
}



=head2 read_chat(chat_id => XXX, chat_title => XXX)

если задан ID чата, то title не рассматривается
возвращает массив вида

=cut
sub read_chat
{
  my $this = shift;
  my %params = @_;

  my $chat_id = $params{chat_id};
  my $chat_title = $params{chat_title};

  # если задан ID, то title не рассматривается
  if($chat_id)
  {
    $chat_title = '';
  }

  my $all_updates = $this->call('getUpdates', {});

  # debug($all_updates);
  my $chat_messages = [];
  foreach my $row (@{$all_updates->{result}})
  {
    my $chat = $row->{message}->{chat};
    # trace($chat_title);
    # trace($row->{chat}->{title});
    if( ($chat_id && $chat->{id} eq $chat_id) || ($chat_title && $chat->{title} eq $chat_title))
    {
      push(@$chat_messages, $row);
    }
  }

  return $chat_messages;
}

=head2 call( $method, $params)


  my $tg = WebProgTelegramClient->new(token => $token);
  my $result = $tg->call('getMe', {});

=cut
sub call
{
  my ( $this, $method, $params ) = @_;

  my $method_type = 'POST';

  my $result = $this->_json_request(method => $method, method_type => $method_type, data => $params);
  return $result;
}


=head2 _json_request(method => 'call', method_type => 'POST', data => {})

Отправляет запрос в JSON на переданный в параметре method url (дополняет его из request_url)

=cut
sub _json_request
{
  my $this = shift;
  my %params = @_;

  unless ($this->{_request_url})
  {
    die 'Задайте пример URL для вызова REST в настройках';
    return;
  }

  my $method = $params{method} || die 'No method pass';
  my $method_type = $params{method_type} || 'POST';
  my $data = $params{data} || undef;

  my $url = $this->{_request_url} . '/'.$method;


  my $uri = URI->new( $url );
  my $request = HTTP::Request->new( $method_type => $uri->as_string );
  $request->header( 'Content-Type' => 'application/json' );

  _set_encoding( $data, 'cp1251', 'utf-8' );
  $request->content( Cpanel::JSON::XS->new->utf8->encode($data) );



  my $user_agent = LWP::UserAgent->new(
    ssl_opts => {
      verify_hostname => 0,
      SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE
    },
  );

  my $response = $user_agent->request($request);

  my $result   = $this->_parse_response($response);

  _set_encoding( $result, 'utf-8', 'cp1251' );


  # trace($url);
  # debug($result);

  return $result;
}





sub _parse_response
{
  my ( $this, $response ) = @_;

  my $result;
  if ( $response->is_success )
  {
    eval { $result = Cpanel::JSON::XS->new->utf8->decode( $response->content ) };
    my $error = $@;
    if ($error)
    {
      # 204 код приходит, когда ничего не найдено. Возвращаем пустой хеш
      if($response->{_rc} == 204)
      {
        $result = {};
      }
      else
      {
        $result->{error} = $error;
      }
    }
  }
  else
  {
    $result = Cpanel::JSON::XS->new->utf8->decode( $response->content );
    unless($result->{error})
    {
      $result->{error} = $result->{error_description};
    }
  }

  return $result;
}


=head2 _set_encoding($any, $from, $to)

  FOR INTERNAL USE

=cut
sub _set_encoding
{
  return unless $_[0];

  if ( ref( $_[0] ) eq q/HASH/ )
  {
    _set_encoding( $_[0]->{$_}, $_[1], $_[2] ) for ( keys %{ $_[0] } );
  }
  elsif ( ref( $_[0] ) eq q/ARRAY/ )
  {
    _set_encoding($_, $_[1], $_[2]) for @{ $_[0] };
  }
  else
  {
    return if $_[0] =~ /^\d+$/;
    return $_[0] = S2U::Utils::Encode->w1251_to_utf8($_[0]) if $_[2] =~ /utf/i;
    #return $_[0] = S2U::Utils::Encode->utf8_to_w1251($_[0]);

    no warnings 'uninitialized';
    utf8::encode( $_[0] );
    Encode::from_to( $_[0], $_[1], $_[2] );
  }
}



1;

