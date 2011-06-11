package PDF::Box::Content::Text;
use Moose;
use namespace::autoclean;

extends 'PDF::Box::Content';

has 'size' => ( isa => 'Int', is => 'ro' );
has 'color' => ( isa => 'Str', is => 'ro' );


sub render{
  my ($self, $x, $y) = @_;

warn "render text \@ $x, $y\n";
warn "  ".$self->value."\n";
warn "  ".$self->color."\n";

  my $text = $self->doc->text;
  $text->font($self->doc->font->{Helvetica}{Roman}, $self->size);
  $text->fillcolor($self->color);
  $text->translate($x,$y-$self->size);
  $text->text( $self->value );

}


__PACKAGE__->meta->make_immutable;

1;
