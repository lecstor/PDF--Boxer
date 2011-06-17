package PDF::Boxer::Content::Text;
use Moose;
use namespace::autoclean;

extends 'PDF::Boxer::Box';

has 'size' => ( isa => 'Int', is => 'ro' );
has 'font' => ( isa => 'Str', is => 'ro', default => 'Helvetica' );
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
sub _build_pressure_height{ 0 }

sub get_font{
  my ($self) = @_;
  return $self->boxer->doc->font( $self->font );
}

sub baseline_top{
  my ($self, $font, $size) = @_;
  my $asc = $font->ascender();
  my $desc = $font->descender();
  my $adjust_perc = $asc / (($desc < 0 ? abs($desc) : $desc) + $asc);
  my $adjust = $self->size*$adjust_perc;
  return $self->content_top - $adjust;
}

around 'render' => sub{
  my ($orig, $self) = @_;

  $self->dump_all;

  my $text = $self->boxer->doc->text;

  my $font = $self->get_font;

  $text->font($font, $self->size);

  $text->fillcolor($self->color);
  
  $text->lead($self->lead);

  my $x = $self->content_left;
  my $y = $self->baseline_top($font, $self->size);
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

  $self->$orig();

};

#around 'adjust_size' => sub{
#  my ($orig, $self) = @_;
#  $self->height($self->lead * scalar @{$self->value});
#};

sub _height_from_child{
  my ($self) = @_;
  return $self->lead * scalar @{$self->value};
}

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
