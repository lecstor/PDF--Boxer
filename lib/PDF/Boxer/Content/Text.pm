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

  $self->dump_all;

  my $text = $self->boxer->doc->text;

  my $font = $self->boxer->doc->font('Helvetica');

  $text->font($font, $self->size);

  my $asc = $font->ascender();
  my $desc = $font->descender();
  my $adjust_perc = $asc / (($desc < 0 ? abs($desc) : $desc) + $asc);
  my $adjust = $self->size*$adjust_perc;

warn "asc: $asc desc: $desc";

warn "Adjust: $adjust ".$self->size*$adjust;

  $text->fillcolor($self->color);
  
  $text->lead($self->lead);

  my $x = $self->content_left;
  my $y = $self->content_top-$adjust;
  my $align_method = 'text';

  foreach($self->align || ()){
    /^rig/ && do { $x = $self->content_right; $align_method = 'text_right' };
    /^cen/ && do { $x += ($self->width/2);    $align_method = 'text_center' };
  }

  $text->translate($x,$y);
  foreach(@{$self->value}){
    $text->$align_method( $_ );
    $text->nl;
  }

  $self->height($self->lead * scalar @{$self->value});

  $self->$orig();

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
