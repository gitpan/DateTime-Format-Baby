package DateTime::Format::Baby;

use strict;
use vars qw($VERSION);
use DateTime;
use Carp;

$VERSION = '0.15.3';

my %languages = (
    'en'      => {numbers => [qw /one two three four five six seven
                                      eight nine ten eleven twelve/],
                  format  => "The big hand is on the %s " .
                             "and the little hand is on the %s",
                  big     => [qw/big long large minute/],
                  little     => [qw/little small short hour/]},

    'br'      => {numbers => [qw /um dois tr�s quatro cinco seis
                                     sete oito nove dez onze doze/],
                  format  => "O ponteiro grande est� no %s " .
                             "e o ponteiro pequeno est� no %s"},

    'de'      => {numbers => [qw /Eins Zwei Drei Vier F�nf Sechs Sieben
                                       Acht Neun Zehn Elf Zw�lf/],
                  format  => "Der gro\xDFe Zeiger ist auf der %s " .
                             "und der kleine Zeiger ist auf der %s",
                  big     => [qw/gro� lang gro� Minute/],
                  little     => [qw/wenig klein Kurzschlu� Stunde/]},

    'du'      => {numbers => [qw /een twee drie vier vijf zes zeven
                                      acht negen tien elf twaalf/],
                  format  => "De grote wijzer is op de %s " .
                             "en de kleine wijzer is op de %s"},

    'es'      => {numbers => [qw /uno dos tres cuatro cinco seis siete
                                      ocho nueve diez once doce/],
                  format  => "La manecilla grande est� sobre el %s " .
                             "y la manecilla peque�a est� sobre el %s",
                  big     => [qw/grande grande minuto/, 'de largo'],
                  little     => [qw/poco peque�o cortocircuito hora/]},
                             

    'fr'      => {numbers => [qw /un deux trois quatre cinq six sept
                                     huit neuf dix onze douze/],
                  format  => "La grande aiguille est sur le %s " .
                             "et la petite aiguille est sur le %s",
                  big     => [qw/grand longtemps grand minute/],
                  little     => [qw/peu petit short heure/]},

    'it'      => {numbers => ['a una', 'e due', 'e tre', 'e quattro',
                                       'e cinque', 'e sei', 'e sette',
                                       'e otto', 'e nove', 'e dieci',
                                       'e undici', 'e dodici'],
                  format  => "La lancetta lunga e' sull%s " .
                             "e quella corta e' sull%s",
                  big     => [qw/grande lungamente grande minuto/],
                  little     => [qw/piccolo piccolo short ora/]},

    'no'      => {numbers => [qw /en to tre fire fem seks syv
                                     �tte ni ti elleve tolv/],
                  format  => "Den store viseren er p� %s " .
                             "og den lille viseren er p� %s"},

    'se'      => {numbers => [qw /ett tv� tre fyra fem sex sju
                                      �tta nio tio elva tolv/],
                  format  => "Den stora visaren �r p� %s " .
                             "och den lilla visaren �r p� %s"},

    'swedish chef'
              => {numbers => [qw /one tvu three ffuoor ffeefe six
                                      sefen eight nine ten elefen tvelfe/],
                  format  => "Zee beeg hund is un zee %s und zee little " .
                             "hund is un zee %s. Bork, bork, bork!"},

    'warez'   => {numbers => [qw {()nE TW0 7HR3e f0uR f|ve 5ix 
                                       ZE\/3n E|6hT n1nE TeN 3L3v3gn 7wELv3}],
                  format  => 'T|-|3 bIG h4|\||) Yz 0n thE %s ' .
                             'and 7|-|3 lIttlE |-|aND |S 0|\| Th3 %s'},
	'custom'  => 1,
);


sub new {
    my $class = shift;
	my %args;
	if (scalar @_ == 1) {
		$args{language} = shift;
	} elsif (scalar @_ %2) {
		croak ("DateTime::Format::Baby must be given either one parameter (a language) or a hash");
	} else {
		%args = @_;
	}
	$args{language}	||= 'en';
	
	$args{numbers}	||= $languages{$args{language}}{numbers};
	$args{format}	||= $languages{$args{language}}{format};
	$args{big}		||= $languages{$args{language}}{big};
	$args{little}	||= $languages{$args{language}}{little};
	
	unless (exists $languages{$args{language}}) {
		croak "I do not know the language '$args{language}'. The languages I do know are: " . join(', ', sort keys %languages);
	}
	unless ($args{numbers}) {
		croak "I have no numbers for that language.";
	}
	unless ($args{format}) {
		croak "I have no format for that language.";
	}
	
    return bless \%args, $class;
}

sub languages {
	return sort keys %languages;
}

sub language {
	my $self = shift;
	my $language = shift;
	
	if ($language) {
		$self->{language}   = $language;
		$self->{numbers}	= $languages{$language}{numbers};
		$self->{format}		= $languages{$language}{format};
		$self->{big}		= $languages{$language}{big};
		$self->{little}		= $languages{$language}{little};
		
		unless (exists $languages{$language}) {
			croak "I do not know the language '$language'. The languages I do know are: " . join(', ', sort keys %languages);
		}
	}
	return $self->{language};	
}

sub parse_datetime {
    my ( $self, $date ) = @_;

	my ($littlenum,$bignum);

	if ($self->{big} && $self->{little}) {
		my $numbers = '(' . join('|',@{$self->{numbers}}) . ')';
		my $format = $self->{format};
		my $big = '(' . join('|',@{$self->{big}}) . ')';
		my $little = '(' . join('|',@{$self->{little}}) . ')';

		(undef,$littlenum) = $date =~/$little.*?$numbers/i;
		(undef,$bignum) = $date =~/$big.*?$numbers/i;

	} else {
		my $regex = $self->{format};
		$regex =~s/\%s/(\\w+)/g;
		
		($bignum,$littlenum) = $date =~ /$regex/;
	}
		
	unless ($bignum && $littlenum) {
		croak "Sorry, I didn't understand '$date' in '".$self->language ."'";
	}

	my %reverse;
	@reverse{@{$self->{numbers}}} = (1..12);
	
	my $hours = $reverse{lc($littlenum)} * 1;
	my $minutes = $reverse{lc($bignum)} * 5;
	
	$hours-- if $minutes > 30;
	if ($minutes == 60) {
		$minutes = 0; $hours++;
	}
    return DateTime->new(year=>0, hour=>$hours, minute=>$minutes);
}

sub parse_duration {
    croak "DateTime::Format::Baby doesn't do durations.";
}

sub format_datetime {
    my ( $self, $dt ) = @_;

    my ($hours, $minutes) = ($dt->hour, $dt->minute);

    $hours ++ if $minutes > 30;

    # Turn $hours into 1 .. 12 format.
    $hours  %= 12;
    $hours ||= 12;

    # Round minutes to nearest 5 minute.
    $minutes   = sprintf "%.0f" => $minutes / 5;
    $minutes ||= 12;

    local $[ = 1;
    return sprintf $self->{format} => @{$self->{numbers}} [$minutes, $hours];
}

sub format_duration {
    croak "DateTime::Format::Baby doesn't do durations.";
}


1;
__END__

=head1 NAME

DateTime::Format::Baby - Parse and format baby-style time

=head1 SYNOPSIS

  use DateTime::Format::Baby;

  my $Baby = DateTime::Format::Baby->new('en');
  my $dt = $Baby->parse_datetime('The big hand is on the twelve and the little hand is on the six.');

  $Baby->language('fr');

  # La grande aiguille est sur le douze et la petite aiguille est sur le six>
  $Baby->format_datetime($dt);

=head1 DESCRIPTION

This module understands baby talk in a variety of languages.

=head1 METHODS

This class offers the following methods.

=over 4

=item * parse_datetime($string)

Given baby talk, this method will return a new
C<DateTime> object.

For some languages (en de, es, fr and it) parsing uses a regexp on various synonyms
for 'big' and 'little'. For all other languages, the module only understands the same
phrase that it would give using format_datetime().

If given baby talk that it can't parse, this method may either die or get confused.
Don't try things like "The big and little hands are on the six and five, respectively."

=item * format_datetime($datetime)

Given a C<DateTime> object, this methods returns baby talk. Remember though that babies
only understand time (even then, without am/pm)

=item * language($language)

When given a language, this method sets its language appropriately.

This method returns the current language. (After processing as above)

=item * languages()

This method return a list of known languages.

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list.  See http://lists.perl.org/ for more details.

=head1 NOTE

Baby talk does not implement years, months, days or even AM/PM. It's
more for amusement than anything else.

=head1 AUTHOR

Rick Measham <rickm@cpan.org> (BigLug on PerlMonks)

This code is a DateTime version of Acme::Time::Baby (copyright 2002 by Abigail)
with the ability to parse strings added by Rick Measham.

=head1 CONTRIBUTIONS

Abigail's original module contained a language list that is plagarised here. 
See the documentation for Acme::Time::Baby for language acknowledgements.

If you have additional language data for this module, please also pass it on to
Abigail. This module is not meant to replace the original. Rather it is a DateTime
port of that module.

=head1 COPYRIGHT

This program is copyright 2003 by Rick Measham

This program is based on code that is copyright 2002 by Abigail. 

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: 

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. 

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 

=head1 SEE ALSO

Acme::Time::Baby

datetime@perl.org mailing list

http://datetime.perl.org/

=cut
