=pod
****************************************************************
Класс io_cgi
****************************************************************
Версия 1.0.2, 23.01.2004
****************************************************************
 -- обработка входных параметров программ CGI
 -- вывод заголовков документов HTML
 -- преобразование данных из полей форм

Парсинг CGI параметров, делаем один раз
my $io_cgi = io_cgi->new();
$io_cgi->get_params();


Получение значения конкретного параметра
print  $io_cgi->param('login');
print  $io_cgi->param('password');

Получение данных из полей типа Файл
print  $io_cgi->file_tag_name('key_file');
print  $io_cgi->file_path('key_file');
print  $io_cgi->file_name('key_file');
print  $io_cgi->file_content_type('key_file');
print  $io_cgi->file_contents('key_file');
print  $io_cgi->file_content_size('key_file');

Печать заголовков
print $io_cgi->print_html_headers_cashe;
print 'ОК';


****************************************************************
Copyright (c) Alexandre Frolov, 2001-2004
alexandre@frolov.pp.ru
http://www.shop2you.ru
****************************************************************
=cut

package io_cgi;
use strict;
use HTML::Entities;
use Digest::SHA1 qw(sha1_hex sha1_base64);


my @A2E = ();
my @E2A = ();

my $EBCDIC = "\t" ne "\011";
if ($EBCDIC) {
# (ord('^') == 95) for codepage 1047 as on os390, vmesa
@A2E = (
  0,  1,  2,  3, 55, 45, 46, 47, 22,  5, 21, 11, 12, 13, 14, 15,
 16, 17, 18, 19, 60, 61, 50, 38, 24, 25, 63, 39, 28, 29, 30, 31,
 64, 90,127,123, 91,108, 80,125, 77, 93, 92, 78,107, 96, 75, 97,
240,241,242,243,244,245,246,247,248,249,122, 94, 76,126,110,111,
124,193,194,195,196,197,198,199,200,201,209,210,211,212,213,214,
215,216,217,226,227,228,229,230,231,232,233,173,224,189, 95,109,
121,129,130,131,132,133,134,135,136,137,145,146,147,148,149,150,
151,152,153,162,163,164,165,166,167,168,169,192, 79,208,161,  7,
 32, 33, 34, 35, 36, 37,  6, 23, 40, 41, 42, 43, 44,  9, 10, 27,
 48, 49, 26, 51, 52, 53, 54,  8, 56, 57, 58, 59,  4, 20, 62,255,
 65,170, 74,177,159,178,106,181,187,180,154,138,176,202,175,188,
144,143,234,250,190,160,182,179,157,218,155,139,183,184,185,171,
100,101, 98,102, 99,103,158,104,116,113,114,115,120,117,118,119,
172,105,237,238,235,239,236,191,128,253,254,251,252,186,174, 89,
 68, 69, 66, 70, 67, 71,156, 72, 84, 81, 82, 83, 88, 85, 86, 87,
140, 73,205,206,203,207,204,225,112,221,222,219,220,141,142,223
      );
@E2A = (
  0,  1,  2,  3,156,  9,134,127,151,141,142, 11, 12, 13, 14, 15,
 16, 17, 18, 19,157, 10,  8,135, 24, 25,146,143, 28, 29, 30, 31,
128,129,130,131,132,133, 23, 27,136,137,138,139,140,  5,  6,  7,
144,145, 22,147,148,149,150,  4,152,153,154,155, 20, 21,158, 26,
 32,160,226,228,224,225,227,229,231,241,162, 46, 60, 40, 43,124,
 38,233,234,235,232,237,238,239,236,223, 33, 36, 42, 41, 59, 94,
 45, 47,194,196,192,193,195,197,199,209,166, 44, 37, 95, 62, 63,
248,201,202,203,200,205,206,207,204, 96, 58, 35, 64, 39, 61, 34,
216, 97, 98, 99,100,101,102,103,104,105,171,187,240,253,254,177,
176,106,107,108,109,110,111,112,113,114,170,186,230,184,198,164,
181,126,115,116,117,118,119,120,121,122,161,191,208, 91,222,174,
172,163,165,183,169,167,182,188,189,190,221,168,175, 93,180,215,
123, 65, 66, 67, 68, 69, 70, 71, 72, 73,173,244,246,242,243,245,
125, 74, 75, 76, 77, 78, 79, 80, 81, 82,185,251,252,249,250,255,
 92,247, 83, 84, 85, 86, 87, 88, 89, 90,178,212,214,210,211,213,
 48, 49, 50, 51, 52, 53, 54, 55, 56, 57,179,219,220,217,218,159
      );
if (ord('^') == 106) { # as in the BS2000 posix-bc coded character set
    $A2E[91] = 187;   $A2E[92] = 188;  $A2E[94] = 106;  $A2E[96] = 74;
    $A2E[123] = 251;  $A2E[125] = 253; $A2E[126] = 255; $A2E[159] = 95;
    $A2E[162] = 176;  $A2E[166] = 208; $A2E[168] = 121; $A2E[172] = 186;
    $A2E[175] = 161;  $A2E[217] = 224; $A2E[219] = 221; $A2E[221] = 173;
    $A2E[249] = 192;

    $E2A[74] = 96;   $E2A[95] = 159;  $E2A[106] = 94;  $E2A[121] = 168;
    $E2A[161] = 175; $E2A[173] = 221; $E2A[176] = 162; $E2A[186] = 172;
    $E2A[187] = 91;  $E2A[188] = 92;  $E2A[192] = 249; $E2A[208] = 166;
    $E2A[221] = 219; $E2A[224] = 217; $E2A[251] = 123; $E2A[253] = 125;
    $E2A[255] = 126;
}
elsif (ord('^') == 176) { # as in codepage 037 on os400
    $A2E[10] = 37;  $A2E[91] = 186;  $A2E[93] = 187; $A2E[94] = 176;
    $A2E[133] = 21; $A2E[168] = 189; $A2E[172] = 95; $A2E[221] = 173;

    $E2A[21] = 133; $E2A[37] = 10;  $E2A[95] = 172; $E2A[173] = 221;
    $E2A[176] = 94; $E2A[186] = 91; $E2A[187] = 93; $E2A[189] = 168;
}
}

# ==================================================================
# Конструктор класса io_cgi
# ==================================================================
our $singleton = undef;
sub new
{
  my $this = shift @_;
  return $singleton if defined $singleton;
  my $self = {};
  $singleton = bless($self, $this);
  return $singleton;
}

# ==================================================================
# get_params
#
# Чтение всех параметров программы CGI из стандартного потока ввода,
# а также чтение данных Cookie
# Прочитанные данные сохраняются в полях класса io_cgi
#
# Форма:
# <FORM action="/cgi-bin/io_login.pl" method="post" enctype="multipart/form-data">
# <FORM action="/cgi-bin/io_login.pl" method="post">
# <FORM action="/cgi-bin/io_login.pl" method="get">
# ==================================================================
sub get_params
{
  my $this = shift @_;
	my $raw_data;

	# Получили данные из формы методом POST
  if($ENV{'REQUEST_METHOD'} eq "POST")
	{
	  # Проверяем тип кодировки даннных:
		#   multipart/form-data или application/x-www-form-urlencoded

		$_=$ENV{CONTENT_TYPE};
		if(s/multipart\/form-data//)
		{
			# Нужно на платформе Windows переключить потоки в двоичный режим
			if($^O eq 'MSWin32')
			{
				binmode(STDIN);
				binmode(STDOUT);
				binmode(STDERR);
			}

			# Читаем данные из входного потока программы CGI
	    read(STDIN, $this->{ 'BUFFER' }, $ENV{'CONTENT_LENGTH'});

			# Прочитанные данные
			$raw_data = $this->{ 'BUFFER' };

			# Разбираем буфер с данными формата multipart/form-data
			$this->parse_multi($raw_data);
		}
		elsif(s/application\/x-www-form-urlencoded//)
		{
			# Читаем данные из входного потока программы CGI
	    read(STDIN, $this->{ 'BUFFER' }, $ENV{'CONTENT_LENGTH'});
			$raw_data = $this->{ 'BUFFER' };

			# Разбираем буфер в формате имя=значение
			$this->parse_data($raw_data);
		}
		else
		{
			die io_exception->new('Unknown www-form encoding method: '.$ENV{CONTENT_TYPE});
		}
	}

	# Получили данные через ссылку или из формы методом GET
  elsif ($ENV{'REQUEST_METHOD'} eq "GET")
	{
   	$this->{ 'BUFFER' } = $ENV{'QUERY_STRING'};
		$raw_data = $this->{ 'BUFFER' };

		# Разбираем буфер в формате имя=значение
		$this->parse_data($raw_data);
  }

	# Получаем cookie
	$this->{ 'http_cookie' } = $ENV{ HTTP_COOKIE}|| $ENV{COOKIE};
#	my ($key, $value) = split(/=/, $ENV{HTTP_COOKIE});
#	$this->{ 'cookie_key' } = $key;
#	$this->{ 'cookie_value' } = $value;
##  $this->print_html_headers_cashe();
##	print '$this->{ \'http_cookie\' } = '.$this->{ 'http_cookie' }.'<br>';

	my $raw_cookie=$this->{ 'http_cookie' };

  my %results;


#  $this->print_html_headers_cashe();

  my(@pairs) = split("; ?",$raw_cookie);
  foreach (@pairs) {
    s/\s*(.*?)\s*/$1/;
    my($key,$value) = split("=");

#		print 'key = '.$key.' value = '.$value.'<br>';

    # Some foreign cookies are not in name=value format, so ignore
    # them.
    next if !defined($value);
    my @values = ();
    if ($value ne '') {
      @values = map $this->unescape($_),split(/[&;]/,$value.'&dmy');
      pop @values;
    }
    $key = $this->unescape($key);
    # A bug in Netscape can cause several cookies with same name to
    # appear.  The FIRST one in HTTP_COOKIE is the most recent version.
#    $results{$key} ||= $this->new(-name=>$key,-value=>\@values);
    $results{$key} = \@values;
  }
	$this->{ 'cookies' }=\%results;

#	foreach my $fff (keys %results)
#	{
#	  my $val = $results{$fff};
#		print 'key = '.$fff.' value = '.$$val[0].'<br>';
#	}
#
#	my %cookies=();
#	my @cookies_pairs=split(/;/, $this->{ 'http_cookie' });
#	foreach my $cookie (@cookies_pairs)
#	{
#		my ($key, $value) = split(/=/, $cookie);
#		%cookies=(%cookies, $key => $value);
#	}
#	$this->{ 'cookies_ref' }=\%cookies;

	# Получаем ip пользователя с учетом не анонимного прокси
	my $user_ip = $ENV{'HTTP_X_FORWARDED_FOR'};
	if(!defined $user_ip)
	{
  	$user_ip = $ENV{'REMOTE_ADDR'};
	}
	$this->{ 'ip' } = $user_ip;
}

# ==================================================================
# unescape URL-encoded data
# ==================================================================
sub unescape {
  my $this = shift @_;
  my $todecode = shift @_;
  return undef unless defined($todecode);
  $todecode =~ tr/+/ /;       # pluses become spaces
    my $EBCDIC = "\t" ne "\011";
    if ($EBCDIC) {
      $todecode =~ s/%([0-9a-fA-F]{2})/chr $A2E[hex($1)]/ge;
    } else {
      $todecode =~ s/%([0-9a-fA-F]{2})/chr hex($1)/ge;
    }
  return $todecode;
}

# ==================================================================
# parse_multi
#
# Разбор данных, полученных методом POST в формате multipart/form-data
#
# Вход:  $raw_data - буфер с данными
# ==================================================================
sub parse_multi
{
  my $this = shift @_;
  my $raw_data = shift @_;

	my ($boundary, @pairs, $part, $dump, $firstline, $datas, $blankline, $arrvalue);
	my (@columns, $name, $currentHeader, $currentValue, $currentColumn);

	# Хеш для разбора входных данных
	my %CGI;


	# Разделитель
#  ($boundary = $ENV{CONTENT_TYPE}) =~ s/^.*boundary=(.*)$/\1/;
  ($boundary = $ENV{CONTENT_TYPE}) =~ /^.*boundary=(.*)$/;
	$boundary = $1;

	# Количество полей в форме
  @pairs = split(/--$boundary/, $raw_data);
	# Убираем остаток данных за последним разделителем
  @pairs = splice(@pairs,1,$#pairs-1);

  # Цикл по полям формы
  for $part (@pairs)
	{
    $part =~ s/[\r]\n$//g;
    ($dump, $firstline, $datas) = split(/[\r]\n/, $part, 3);

  next if $firstline =~ /filename=\"\"/;

    $firstline =~ s/^Content-Disposition: form-data; //;
    (@columns) = split(/;\s+/, $firstline);

#    ($name = $columns[0]) =~ s/^name="([^"]+)"$/\1/g;
    ($name = $columns[0]) =~ m/^name="([^"]+)"$/g;
		$name = $1;


    if ($#columns > 0)
		{
			if ($datas =~ /^Content-Type:/)
			{
	  		($CGI{"$name"}->{'Content-Type'}, $blankline, $datas) = split(/[\r]\n/, $datas, 3);

#        $CGI{"$name"}->{'Content-Type'} =~ s/^Content-Type: ([^\s]+)$/\1/g;

        $CGI{"$name"}->{'Content-Type'} =~ m/^Content-Type: ([^\s]+)$/g;
				$CGI{"$name"}->{'Content-Type'} = $1;

			}
			else
			{
			  ($blankline, $datas) = split(/[\r]\n/, $datas, 2);
			  $CGI{"$name"}->{'Content-Type'} = "application/octet-stream";
			}
    }
    else
		{
			($blankline, $datas) = split(/[\r]\n/, $datas, 2);
      if (grep(/^$name$/, keys(%CGI)))
			{
        if (ref($CGI{$name}) && @{$CGI{$name}} > 0) #if (@{$CGI{$name}} > 0)
				{
          push(@{$CGI{$name}}, $datas);
        }
        else
				{
          $arrvalue = $CGI{$name};
          undef $CGI{$name};
          $CGI{$name}[0] = $arrvalue;
          push(@{$CGI{$name}}, $datas);
        }
      }
      else
			{
	  		next if $datas =~ /^\s*$/;
        $CGI{"$name"} = $datas;
      }
    next;
    }

    for $currentColumn (@columns)
		{
      ($currentHeader, $currentValue) = $currentColumn =~ /^([^=]+)="([^"]+)"$/;
      $CGI{"$name"}->{"$currentHeader"} = $currentValue;
    }
    $CGI{"$name"}->{'Contents'} = $datas;
  }

  # Ссылка на хеш с результатом разбора входных параметров
	$this->{ 'param' } = \%CGI;
}

# ==================================================================
# parse_data
#
# Разбор данных, полученных методом GET
#
# Вход:  $raw_data - буфер с данными
# ==================================================================
sub parse_data
{
  my $this = shift @_;
  my $raw_data = shift @_;

  my (@items,$key,$value, $arrvalue);

	# Хеш для разбора входных данных
	my %CGI;
  # Выделяем пары имен полей и их значения
  @items = split('&', $raw_data);

  # Цикл по всем парам имя=значение
  for (@items)
	{
    $_ =~ tr/+/ /;
    ($key,$value) = split('=',$_,2);
    # Преобразование 16-ричных чисел  %xx hex в алфавитно-цифровые символы
    $key   =~ s/%(..)/pack("C", hex($1))/eg;
    $value =~ s/%(..)/pack("C", hex($1))/eg;
    if (grep(/^$key$/, keys(%CGI)))
		{
  		if (ref($CGI{$key}) && @{$CGI{$key}} > 0)
			{
        push(@{$CGI{$key}}, "$value");
      }
  		else
			{
    		$arrvalue = $CGI{$key};
    		undef $CGI{$key};
        $CGI{$key}[0] = $arrvalue;
    		push(@{$CGI{$key}}, "$value");
      }
    }
    else
		{
      $CGI{$key} = $value;
    }
  }

  # Ссылка на хеш с результатом разбора воходных параметров
	$this->{ 'param' } = \%CGI;
}

# ==================================================================
# cookie
#
# Получение cookie в виде массива (ключ, значение)
# ==================================================================
sub cookie
{
  my $this = shift @_;
  my $name = shift @_;

	# If no name is supplied, then retrieve the names of all our cookies.
	return () unless $this->{'cookies'};
	return keys %{$this->{'cookies'}} unless $name;
	return () unless $this->{'cookies'}->{$name};
#	return $this->{'cookies'}->{$name}->value if defined($name) && $name ne '';
	my $cookies=$this->{ 'cookies' };

	return $$cookies{$name}[0] if defined($name) && $name ne '';
}

# ==================================================================
# ip
# Трассировка адреса IP посетителя
#
# $user_ip = $io_cgi->ip();
#
# Выход: 	адрес ip посетителя с учетом не анонимных прокси
# ==================================================================
sub ip()
{
  my $this = shift @_;
	return $this->{ 'ip' };
}

# ==================================================================
# env
#
# Получение данных из элемента хеша %ENV
#
# $value = $io_cgi->env('HTTP_COOKIE');
# Вход:	 	имя переменной окружения
# Выход: 	значение переменной окружения
# ==================================================================
sub env
{
  my $this = shift @_;
  my $name = shift @_;
  return $ENV{ $name };
}

# ==================================================================
# param
#
# Получение значения из обычного поля формы или ссылки
#
# $param_value = $io_cgi->param(param_name);
#
# Вход:	 	имя тега поля формы
# Выход: 	значение поля
# ==================================================================
sub param
{
  my $this = shift @_;
  my $param_name = shift @_;
	if($param_name)
	{
		return ${$this->{ 'param' }} { $param_name };
	}
	else
	{
		return $this->{ 'param' };
	}
}

# ==================================================================
# add_param
#
# Добавление новой записи в хеш полей формы
#
# $param_value = $io_cgi->add_param(param_name, param_value);
#
# Вход:	 	имя поля, значение поля
# Выход: 	нет
# ==================================================================
sub add_param
{
  my $this = shift @_;
  my $param_name = shift @_;
  my $param_value = shift @_;

	if(!($param_name))
	{
		die io_exception->new('<br>Не задано имя параметра - ('.$param_name.') (значение - '.$param_value.') при записи в хеш io_cgi<br>');
	}
	${$this->{ 'param' }} { $param_name }=$param_value;
}


# ==================================================================
# file_tag_name
#
# Получение имени тега file из поля загрузки файлов формы
#
# $tag_name = $io_cgi->file_tag_name(param_tag_name);
#
# Вход:	 	имя тега поля формы
# Выход: 	имя тега file из поля загрузки файлов формы
# ==================================================================
sub file_tag_name
{
  my $this = shift @_;
  my $file_tag = shift @_;
	if(defined $this->param($file_tag))
	{
	  return $this->param($file_tag)->{'name'};
	}
	else
	{
  	return '';
	}
}

# ==================================================================
# file_path
#
# Получение полного пути к загруженному файлу
#
# $file_path = $io_cgi->file_path(param_tag_name);
#
# Вход:	 	имя тега поля формы
# Выход: 	полный путь к загруженному файлу на компьютере клиента
# ==================================================================
sub file_path
{
  my $this = shift @_;
  my $file_tag = shift @_;
	if(defined $this->param($file_tag))
	{
		return $this->param($file_tag)->{'filename'};
	}
	else
	{
  	return '';
	}
}

# ==================================================================
# file_name
#
# Получение имени загруженного файла
#
# $file_name = $io_cgi->file_name(param_tag_name);
#
# Вход:	 	имя тега поля формы
# Выход: 	имя загруженного файла
# ==================================================================
sub file_name
{
  my $this = shift @_;
  my $file_tag = shift @_;
	my $file_path = $this->file_path($file_tag);

	# Удаление пути из полного имени файла
	$file_path=~s(^.*[\\//])();
	return $file_path;
}

# ==================================================================
# file_content_type
#
# Получение типа MIME загруженного файла
#
# $file_content_type = $io_cgi->file_content_type(param_tag_name);
#
# Вход:	 	имя тега поля формы
# Выход: 	тип загруженного файла
# ==================================================================
sub file_content_type
{
  my $this = shift @_;
  my $file_tag = shift @_;
	if(defined $this->param($file_tag))
	{
		return $this->param($file_tag)->{'Content-Type'};
	}
	else
	{
  	return '';
	}
}

# ==================================================================
# file_contents
#
# Получение содержимого загруженного файла
#
# $file_contents = $io_cgi->file_contents(param_tag_name);
#
# Вход:	 	имя тега поля формы
# Выход: 	содержимое загруженного файла
# ==================================================================
sub file_contents
{
  my $this = shift @_;
  my $file_tag = shift @_;
	if(defined $this->param($file_tag))
	{
		return $this->param($file_tag)->{'Contents'};
	}
	else
	{
  	return '';
	}
}

# ==================================================================
# file_content_size
#
# Получение размера загруженного файла в байтах
#
# $file_size = $io_cgi->file_content_size(param_tag_name);
#
# Вход:	 	имя тега поля формы
# Выход: 	размер загруженного файла в байтах
# ==================================================================
sub file_content_size
{
  my $this = shift @_;
  my $file_tag = shift @_;
	if(defined $this->param($file_tag))
	{
		return length($this->param($file_tag)->{'Contents'});
	}
	else
	{
  	return 0;
	}

}

# ==================================================================
# print_html_headers_nocashe
#
# Вывод заголовков HTML без кеширования в стандратный поток
#
# $io_cgi->print_html_headers_nocashe;
# ==================================================================
sub print_html_headers_nocashe()
{
  my $this = shift @_;
  print "Content-Type: text/html\n";
  print "Pragma: no-cache\n";
  print "Cache-Control: no-cache\n";
  print "Expires: Thu Jan  1 01:01:01 1970\n";
  print "Charset: windows-1251\n\n";
}

# ==================================================================
# print_html_headers_cashe
#
# Печать заголовков HTML с кешированем в стандратный поток
#
# $io_cgi->print_html_headers_cashe;
# ==================================================================
sub print_html_headers_cashe()
{
  my $this = shift @_;
  print "Content-Type: text/html\n";
  print "Charset: windows-1251\n\n";
}


# ==================================================================
# print_html_headers_cookie_nocashe
#
# Печать заголовков HTML и Cookie без кеширования
#
# $io_cgi->print_html_headers_cookie_nocashe($cookie_name, $cookie_value);
#
# Вход:	 	имя cookie, значение cookie
# ==================================================================
sub print_html_headers_cookie_nocashe()
{
  my $this = shift @_;
  my ($cookie_name, $cookie_value) = @_;
  print "Content-Type: text/html\n";
  print "Pragma: no-cache\n";
  print "Cache-Control: no-cache\n";
  print "Expires: Thu Jan  1 01:01:01 1970\n";
  print "Charset: windows-1251\n";
#  print "Set-Cookie: ".$cookie_name."=".$cookie_value."\n\n";
  print "Set-Cookie: ".$cookie_name."=".$cookie_value."; path=/\n\n";
}





# ==================================================================
# print_html_headers_cookie_cashe
#
# Печать заголовков HTML и Cookie с кешированием
#
# $io_cgi->print_html_headers_cookie_cashe($cookie_name, $cookie_value);
#
# Вход:	 	имя cookie, значение cookie
# ==================================================================
sub print_html_headers_cookie_cashe()
{
  my $this = shift @_;
  my ($cookie_name, $cookie_value) = @_;
  print "Content-Type: text/html\n";
  print "Charset: windows-1251\n";
#  print "Set-Cookie: ".$cookie_name."=".$cookie_value."\n\n";
  print "Set-Cookie: ".$cookie_name."=".$cookie_value."; path=/\n\n";
}


# ==================================================================
# print_html_headers_cookie_cashe_hash
# Печать заголовков HTML и Cookie с кешированием с передачей хеша значений для записи cookie
# $io_cgi->print_html_headers_cookie_cashe_hash($cookie_hash);
# Вход:	 	хеш - { имя, значение cookie }
# ==================================================================
sub print_html_headers_cookie_cashe_hash($$)
{
  my $this = shift @_;
  my $params = shift @_;
  print "Content-Type: text/html\n";
  print "Charset: windows-1251\n";
	foreach my $key (keys %$params)
	{
		print "Set-Cookie: ".$key."=".$params->{$key}."; \n";
	}
	print "\n";
}

# ==================================================================
# print_html_headers_cookie_nocashe_permanent
#
# Печать заголовков HTML и Cookie с кешированием
#
# $io_cgi->print_html_headers_cookie_cashe($cookie_name, $cookie_value);
#
# Вход:	 	имя cookie, значение cookie
# ==================================================================
sub print_html_headers_cookie_nocashe_permanent()
{
  my $this = shift @_;
  my ($cookie_name, $cookie_value) = @_;
  print "Content-Type: text/html\n";
  print "Pragma: no-cache\n";
  print "Cache-Control: no-cache\n";
  print "Expires: Thu Jan  1 01:01:01 1970\n";
  print "Charset: windows-1251\n";
#  print "Set-Cookie: ".$cookie_name."=".$cookie_value."\n\n";
  print "Set-Cookie: ".$cookie_name."=".$cookie_value."; expires=Fri, 28-Aug-15 15:45:30 GMT; path=/\n\n";
#  print $this->set_cookie($cookie_name,$cookie_value)." path=/\n\n";
}


# ==================================================================
# set_cookie
#
# Установка Cookie с временем жизни 1 год
# print $this->set_cookie($cookie_name,$cookie_value),"\n\n";
#
# Вход:	 ключ, значение
# ==================================================================
sub set_cookie($$$)
{
my($year,$date,@day,$ret,$time);
$year=(localtime(time))[5]+1;
$date=localtime(time);
@day=split(/ /,$date);
$year =~ s/\d*(\d\d)/$1/;
$ret="Set-Cookie: $_[1]=$_[2]; expires=";
$ret.="$day[0], $day[3]-$day[1]-$year $day[4] GMT;";
return $ret
}

# ==================================================================
# ascii_to_html
#
# Замена символьных объектов для блокирования ввода пользователями кода HTML
#
# $param_value_encoded = $io_cgi->ascii_to_html($param_value);
#
#
# Вход:	 	исходная строка, введенная пользователем
# Выход: 	перекодированная строка, в которой смиволы ><"&
#  заменены символьными объектами
# ==================================================================
sub ascii_to_html($$)
{
  my $this = shift @_;
  my $ascii = shift @_;
  if($ascii)
	{
		$ascii=HTML::Entities::encode($ascii, '><"&');
		$ascii=~s/'/`/g;
		return $ascii;
#		return HTML::Entities::encode($ascii, '\'><"&');
	}
}
# ==================================================================
# html_to_ascii
#
# Замена символьных объектов HTML на символы ascii (для использования строки в
# не html документах, например excel)
#
# $param_value_decoded = $io_cgi->html_to_ascii($param_value);
#
#
# Вход:	 	исходная строка, введенная пользователем
# Выход: 	перекодированная строка, в которой смиволы HTML подобные &quot; (")
#  заменены символами ascii
# ==================================================================
sub html_to_ascii($$)
{
  my $this = shift @_;
  my $ascii = shift @_;
  if($ascii) { return HTML::Entities::decode($ascii); }
}

# ==================================================================
# win2koi($)
# ==================================================================
sub win2koi
{
  my($this,$from)=@_;
  $_=$from;
  tr/\0\1\2\3\4\5\6\7\10\11\12\13\14\15\16\17\20\21\22\23\24\25\26\27\30\31\32\33\34\35\36\37\40\41\42\43\44\45\46\47\50\51\52\53\54\55\56\57\60\61\62\63\64\65\66\67\70\71\72\73\74\75\76\77\100\101\102\103\104\105\106\107\110\111\112\113\114\115\116\117\120\121\122\123\124\125\126\127\130\131\132\133\134\135\136\137\140\141\142\143\144\145\146\147\150\151\152\153\154\155\156\157\160\161\162\163\164\165\166\167\170\171\172\173\174\175\176\177\200\201\202\203\204\205\206\207\210\211\212\213\214\215\216\217\220\221\222\223\224\225\226\227\230\231\232\233\234\235\236\237\240\241\242\243\244\245\246\247\250\251\252\253\254\255\256\257\260\261\262\263\264\265\266\267\270\271\272\273\274\275\276\277\300\301\302\303\304\305\306\307\310\311\312\313\314\315\316\317\320\321\322\323\324\325\326\327\330\331\332\333\334\335\336\337\340\341\342\343\344\345\346\347\350\351\352\353\354\355\356\357\360\361\362\363\364\365\366\367\370\371\372\373\374\375\376\377/\0\1\2\3\4\5\6\7\10\11\12\13\14\15\16\17\20\21\22\23\24\25\26\27\30\31\32\33\34\35\36\37\40\41\42\43\44\45\46\47\50\51\52\53\54\55\56\57\60\61\62\63\64\65\66\67\70\71\72\73\74\75\76\77\100\101\102\103\104\105\106\107\110\111\112\113\114\115\116\117\120\121\122\123\124\125\126\127\130\131\132\133\134\135\136\137\140\141\142\143\144\145\146\147\150\151\152\153\154\155\156\157\160\161\162\163\164\165\166\167\170\171\172\173\174\175\176\177\200\201\202\203\204\205\206\207\210\211\212\213\214\215\216\217\220\221\222\223\224\225\226\227\230\231\232\233\234\235\236\237\240\241\242\243\244\245\246\247\250\251\252\253\254\255\256\257\260\261\262\263\264\265\266\267\270\271\272\273\274\275\276\277\341\342\367\347\344\345\366\372\351\352\353\354\355\356\357\360\362\363\364\365\346\350\343\376\373\375\377\371\370\374\340\361\301\302\327\307\304\305\326\332\311\312\313\314\315\316\317\320\322\323\324\325\306\310\303\336\333\335\337\331\330\334\300\321/;
  return $_;
}
# ==================================================================
# str2dec($$)
# ==================================================================
sub str2dec
{
	my $this = shift @_;
	my $str = shift @_;
	my @array = split(//,$str);
	my $ustring = '';
	for my $char (@array)
	{
		if(ord($char)>127)
		{$ustring .= "&#" . (unpack("U", $char)+848) . ";";}
		else
		{$ustring .= $char;}
	}
	return $ustring;
}


return 1;