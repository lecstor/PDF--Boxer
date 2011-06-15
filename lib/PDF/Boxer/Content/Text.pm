package PDF::Boxer::Content::Text;
use Moose;
use namespace::autoclean;

extends 'PDF::Boxer::Box';

has 'size' => ( isa => 'Int', is => 'ro' );
has 'color' => ( isa => 'Str', is => 'ro' );
has 'value' => ( isa => 'ArrayRef', is => 'ro' );
has 'align' => ( isa => 'Str', is => 'ro' );

has 'lead' => ( isa => 'Int', is => 'ro', lazy_build => 1 );
sub _build_lead{
  my ($self) = @_;
  return int($self->size + $self->size*$self->lead_spacing);
}

has 'lead_spacing' => ( isa => 'Num', is => 'ro', lazy_build => 1 );
sub _build_lead_spacing{
  return 20/100;
}

sub _build_pressure_width{ 1 }

around 'render' => sub{
  my ($orig, $self) = @_;

  $self->$orig();

#  warn "\n".'=== '.$self->name. ' ==='."\n";
#  warn $self->dump_position;
#  warn $self->dump_size;
  warn $self->dump_attr;
#  $self->add_marker('red');

  my $text = $self->boxer->doc->text;

  my $font = $self->boxer->doc->font->{Helvetica}{Roman};
  $text->font($font, $self->size);

  my $asc = $font->ascender();
  my $desc = $font->descender();
  my $adjust_perc = $asc / (($desc < 0 ? abs($desc) : $desc) + $asc);
  my $adjust = $self->size*$adjust_perc;

warn "asc: $asc desc: $desc";

warn "Adjust: $adjust ".$self->size*$adjust;

  $text->fillcolor($self->color);
  
  $text->lead($self->lead);

  if ($self->align eq 'right'){
    $text->translate($self->content_right,$self->content_top-$adjust);

warn sprintf "Text translate: %s %s", $self->content_right,$self->content_top-$adjust;

    foreach(@{$self->value}){
      $text->text_right( $_ );
      $text->nl;
    }
  } else {
    $text->translate($self->content_left,$self->content_top-$adjust);
    foreach(@{$self->value}){
      $text->text( $_ );
      $text->nl;
    }
  }

#  $self->margin_height();
#  return ( $x, $y - ($self->lead * scalar @{$self->value}) );
};

sub dump_attr{
  my ($self) = @_;
  my @lines = (
    '== Text Attr ==',
    (sprintf 'Text: %s', "\n\t".join("\n\t", @{$self->value})),
    (sprintf 'Size: %s', $self->size),
    (sprintf 'Color: %s', $self->color),
  );
  $_ .= "\n" foreach @lines;
  return join('', @lines);
}

__PACKAGE__->meta->make_immutable;

1;
