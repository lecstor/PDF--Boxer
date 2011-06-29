package PDF::Boxer::Role::BoxDev;
use Moose::Role;

sub ruler_h{
  my ($self, $color) = @_;
  $color ||= 'blue';
  my $gfx = $self->boxer->doc->gfx;
  $gfx->strokecolor($color);
  $gfx->move(10,0);
  $gfx->vline($self->margin_height);
  my $y = 10;
  while ($y < $self->boxer->max_height){
    $gfx->move(10,$y);
    $gfx->hline($y % 50 ? 15 : 20);
    $y += 10;
  }
  $gfx->stroke;
}

sub add_marker{
  my ($self, $color) = @_;
  $color ||= 'blue';
  my $gfx = $self->boxer->doc->gfx;
  $gfx->linewidth(1);
  $gfx->strokecolor($color);
  $gfx->move($self->margin_left, $self->margin_top);
  $gfx->hline($self->margin_left + 3);
  $gfx->stroke;
  $gfx->move($self->margin_left, $self->margin_top);
  $gfx->vline($self->margin_top-3);
  $gfx->stroke;
}

sub cross_hairs{
  my ($self, $x, $y, $color) = @_;
  $color ||= 'blue';
  my $gfx = $self->boxer->doc->gfx;
  $gfx->strokecolor($color);
  $gfx->move($x,0);
  $gfx->vline($self->margin_height);
  $gfx->move(0,$y);
  $gfx->hline($self->margin_width);
  $gfx->stroke;
}

sub dump_all{
  my ($self) = @_;
  return unless $self->debug;
  warn "\n===========================\n";
  warn '=== '.$self->name. ' ==='."\n";
  warn $self->dump_spec;
  warn $self->dump_position;
  warn $self->dump_size;
  warn $self->dump_attr;
  warn "===========================\n";
  $self->add_marker;
}

sub dump_spec{
  my ($self) = @_;
  my @lines = (
    '== Spec ==',
    (sprintf 'Margin: %s %s %s %s', @{$self->margin}),
    (sprintf 'Border: %s %s %s %s', @{$self->border}),
    (sprintf 'Paddin: %s %s %s %s', @{$self->padding}),
  );
  $_ .= "\n" foreach @lines;
  return join('', @lines);
}

sub dump_attr{
  my ($self) = @_;
  my @lines = (
    '== Attr ==',
    (sprintf 'width: %s', $self->width),
    (sprintf 'height: %s', $self->height),
  );
  $_ .= "\n" foreach @lines;
  return join('', @lines);
}


1;

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Jason Galea <lecstor at cpan.org>. All rights reserved.

This library is free software and may be distributed under the same terms as perl itself.

=cut
