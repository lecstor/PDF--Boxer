package PDF::Boxer::Content::Text;
use Moose;
use namespace::autoclean;

extends 'PDF::Boxer::Content::Box';

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

sub calculate_minimum_size{
  my ($self) = @_;
  my $text = $self->prepare_text;
  my ($width,$height) = (0,0);
  foreach(@{$self->value}){
    my $twidth = $text->advancewidth($_);
    $width = $width ? (sort($twidth,$width))[1] : $twidth;
    $height += $self->lead;
  }

  my $int_width = int($width);
  $int_width++ if $width > $int_width;

  my $int_height = int($height);
  $int_height++ if $height > $int_height;

  $self->adjust({
     width => $int_width,
     height => $int_height,
  }, 'self-calculate_minimum_size');

  return ($int_width, $int_height);
}

sub prepare_text{
  my ($self) = @_;
  my $text = $self->boxer->doc->text;
  my $font = $self->get_font;
  $text->font($font, $self->size);
  $text->fillcolor($self->color);
  $text->lead($self->lead);
  return $text;
}

around 'render' => sub{
  my ($orig, $self) = @_;

  my $text = $self->prepare_text;
  my $font = $self->get_font;

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

sub dump_attr{
  my ($self) = @_;
  my @lines = (
    '== Text Attr ==',
    (sprintf 'Text: %s', "\n\t".join("\n\t", @{$self->value})),
    (sprintf 'Size: %s', $self->size || 'none'),
    (sprintf 'Color: %s', $self->color || 'none'),
  );
  $_ .= "\n" foreach @lines;
  return join('', @lines);
}

__PACKAGE__->meta->make_immutable;

1;

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Jason Galea <lecstor at cpan.org>. All rights reserved.

This library is free software and may be distributed under the same terms as perl itself.

=cut

