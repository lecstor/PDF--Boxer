package PDF::Box::Content::Text;
use Moose;
use namespace::autoclean;

extends 'PDF::Box::Content';

has 'size' => ( isa => 'Int', is => 'ro' );
has 'color' => ( isa => 'Str', is => 'ro' );

has 'lead' => ( isa => 'Int', is => 'ro', lazy_build => 1 );
sub _build_lead{
  my ($self) = @_;
  return int($self->size + $self->size*$self->lead_spacing);
}

has 'lead_spacing' => ( isa => 'Num', is => 'ro', lazy_build => 1 );
sub _build_lead_spacing{
  return 20/100;
}

sub render{
  my ($self, $x, $y) = @_;

  my $gfx = $self->doc->gfx;
    $gfx->linewidth(1);
    $gfx->strokecolor('red');
    $gfx->move($x, $y);
    $gfx->line($x+3, $y);
    $gfx->stroke;
    $gfx->move($x, $y);
    $gfx->line($x, $y-3);
    $gfx->stroke;

warn sprintf "render text \@ $x, \%s\n", $y-$self->size;
warn "  ".$self->value."\n";
warn "  ".$self->color."  ".$self->size."\n";

  my $text = $self->doc->text;

  my $font = $self->doc->font->{Helvetica}{Roman};
  $text->font($font, $self->size);

  my $asc = $font->ascender();
  my $desc = $font->descender();
  my $adjust_perc = $asc / (($desc < 0 ? abs($desc) : $desc) + $asc);
  my $adjust = $self->size*$adjust_perc;

warn "asc: $asc desc: $desc";

warn "Adjust: $adjust ".$self->size*$adjust;

  $text->fillcolor($self->color);
  
  $text->translate($x,$y-$adjust);


#my ($tx, $ty) = $text->textpos();
#warn "  textpos: $tx, $ty\n";

#use Data::Dumper;
#warn Data::Dumper->Dumper($text->textstate);
#my %state = $text->textstate;

#use DDP;

#  $text->text( 'gT' );
#warn p(%state);

  $text->lead($self->lead);

  foreach(@{$self->value}){
    $text->text( $_ );
    $text->nl;
  }

  return ( $x, $y - ($self->lead * scalar @{$self->value}) );
#  return ( $x, $y - ($adjust * scalar @{$self->value}) );
}


__PACKAGE__->meta->make_immutable;

1;
