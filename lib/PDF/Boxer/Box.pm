package PDF::Boxer::Box;
use Moose;

has 'debug'   => ( isa => 'Bool', is => 'ro', default => 0 );

has 'margin'   => ( isa => 'ArrayRef', is => 'ro', default => sub{ [0,0,0,0] } );
has 'border'   => ( isa => 'ArrayRef', is => 'ro', default => sub{ [0,0,0,0] } );
has 'padding'  => ( isa => 'ArrayRef', is => 'ro', default => sub{ [0,0,0,0] } );

with 'PDF::Boxer::Role::Size', 'PDF::Boxer::Role::Position';

has 'boxer' => ( isa => 'PDF::Boxer', is => 'ro' );

has 'name' => ( isa => 'Str', is => 'ro' );
has 'type' => ( isa => 'Str', is => 'ro', default => 'Box' );
has 'background' => ( isa => 'Str', is => 'ro' );
has 'border_color' => ( isa => 'Str', is => 'ro' );
#has 'display' => ( isa => 'Str', is => 'ro', default => 'inline' );

has 'children'  => ( isa => 'ArrayRef', is => 'rw', default => sub{ [] } );
has 'sibling'  => ( isa => 'Object', is => 'ro' );
has 'parent'  => ( isa => 'Object', is => 'ro' );

sub add_to_children{
  my ($self, $child) = @_;
  push(@{$self->children}, $child);
  return $child;
}

sub BUILDARGS{
  my ($class, $args) = @_;

  foreach my $attr (qw! margin border padding !){
    next unless exists $args->{$attr};
    my $arg = $args->{$attr};
    if (ref($arg)){
      unless (ref($arg) eq 'ARRAY'){
        die "Arg to $attr must be string or array reference";
      }
    } else {
      $arg = [split(/\s+/, $arg)];
    }
    my $val = [$arg->[0]];
    $val->[1] = defined $arg->[1] ? $arg->[1] : $val->[0];
    $val->[2] = defined $arg->[2] ? $arg->[2] : $val->[0];
    $val->[3] = defined $arg->[3] ? $arg->[3] : $val->[1];

    $args->{$attr} = $val;
  }

  $args->{pressure_width} = 0 if $args->{width};
  $args->{pressure_height} = 0 if $args->{height};

  return $args;
}

sub BUILD{
  my ($self) = @_;
  die sprintf "not enough room for \"%s\" width: mw: %s > %s", $self->name, $self->margin_width, $self->max_width if $self->has_width && $self->margin_width > $self->max_width;
  die sprintf "not enough room for \"%s\" height: mh: %s > %s", $self->name, $self->margin_height, $self->max_height if $self->has_height && $self->margin_height > $self->max_height;
}

sub clear{
  my ($self) = @_;
  $self->clear_size();
  $self->clear_position();
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

sub auto_adjust{
  my ($self) = @_;

  my $spec = $self->get_spec;

  $self->clear;
  foreach my $attr (keys %$spec){
    $self->$attr($spec->{$attr});
  }

  if (my $parent = $self->parent){
    $self->max_width($parent->width);
    $self->max_height($parent->height);
    $self->margin_left($parent->content_left);
    $self->margin_top($parent->content_top);

    if (my $sibling = $self->sibling){
      if ($sibling->pressure_width){
        $self->margin_top($sibling->margin_bottom - 1);
      } else {
        $self->max_width($parent->width - $sibling->margin_right - 1);
        $self->margin_left($sibling->margin_right + 1);
      }
    }

  }



  if ($self->pressure_height){
    if ($self->parent){
      $self->height($self->content_top - $self->parent->content_bottom);
    }
  } else {
    $self->height($self->_height_from_child);
    $self->parent->auto_adjust if $self->parent;
  }

  if ($self->pressure_width){
  
  } else {

  }

  if (my $sibling = $self->sibling){
    if ($sibling->pressure_width){
      $self->margin_top($sibling->margin_bottom - 1);
    } else {
#      $self->max_width($parent->width - $sibling->margin_right - 1) if $self->parent;
      $self->margin_left($sibling->margin_right + 1);
    }
    $self->parent->auto_adjust if $self->parent;
    foreach(@{$self->children}){
      $_->auto_adjust;
    }
  }

#    foreach(@{$self->children}){
#      $_->auto_adjust;
#    }
 



}

sub get_spec{
  my ($self) = @_;
  my $spec;
  if (my $parent = $self->parent){
    $spec->{max_width}   = $parent->width;
    $spec->{max_height}  = $parent->height;
    $spec->{margin_left} = $parent->content_left;
    $spec->{margin_top}  = $parent->content_top;

    if (my $sibling = $self->sibling){
      if ($sibling->pressure_width){
        $spec->{margin_top}  = $sibling->margin_bottom - 1;
      } else {
        $spec->{max_width}   = $parent->width - $sibling->margin_right - 1;
        $spec->{margin_left} = $sibling->margin_right + 1;
      }
    }

  } else {
    $spec->{max_width}   = $self->max_width;
    $spec->{max_height}  = $self->max_height;
    $spec->{margin_left} = 0;
    $spec->{margin_top}  = $self->max_height;
  }
  return $spec;
}

sub render{
  my ($self) = @_;

#  $self->height($self->_height_from_child);

#warn p($self);
#  $self->dump_all;

  my $gfx = $self->boxer->doc->gfx;

  if ($self->background){
    $gfx->fillcolor($self->background);
#    $gfx->rect($self->margin_left, $self->margin_top, $self->border_width, -$self->border_height);
    $gfx->rect($self->border_left, $self->border_top, $self->border_width, -$self->border_height);
    $gfx->fill;
  }

  # increasing linewidth thickens the border "around" the lines of the rectangle.
  # we want to thinken "inside" the rectangle..
  if (my $width = $self->border->[0]){
    $gfx->linewidth(1);
    $gfx->strokecolor($self->border_color || 'black');
    my ($bl,$bt,$bw,$bh) = ($self->border_left, $self->border_top, $self->border_width, $self->border_height);
    foreach(1..$width){
      $gfx->rect($bl,$bt,$bw,-$bh);
      $gfx->stroke;
      $bl++; $bt--;
      $bw -= 2;
      $bh -= 2;
    }
  }

  foreach(@{$self->children}){
    $_->render;
  }

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


__PACKAGE__->meta->make_immutable;

1;

