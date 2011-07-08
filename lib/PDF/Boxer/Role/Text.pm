package PDF::Boxer::Role::Text;
use Moose::Role;
# ABSTRACT: methods & attributes for text boxes

has 'size' => ( isa => 'Int', is => 'ro', default => 14 );
has 'font' => ( isa => 'Str', is => 'ro', default => 'Helvetica' );
has 'font_bold' => ( isa => 'Str', is => 'ro', default => 'Helvetica-Bold' );
has 'color' => ( isa => 'Str', is => 'ro', default => 'black' );
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
  my ($self, $font_name) = @_;
  return $self->boxer->doc->font( $font_name || $self->font );
}

sub baseline_top{
  my ($self, $font, $size) = @_;
  my $asc = $font->ascender();
  my $desc = $font->descender();
  my $adjust_perc = $asc / (($desc < 0 ? abs($desc) : $desc) + $asc);
  my $adjust = $self->size*$adjust_perc;
  return $self->content_top - $adjust;
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

1;

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Jason Galea <lecstor at cpan.org>. All rights reserved.

This library is free software and may be distributed under the same terms as perl itself.

=cut
