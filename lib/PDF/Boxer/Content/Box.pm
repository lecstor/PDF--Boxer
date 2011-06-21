package PDF::Boxer::Content::Box;
use Moose;
use DDP;
use Scalar::Util qw/weaken/;

has 'debug'   => ( isa => 'Bool', is => 'ro', default => 0 );

has 'margin'   => ( isa => 'ArrayRef', is => 'ro', default => sub{ [0,0,0,0] } );
has 'border'   => ( isa => 'ArrayRef', is => 'ro', default => sub{ [0,0,0,0] } );
has 'padding'  => ( isa => 'ArrayRef', is => 'ro', default => sub{ [0,0,0,0] } );
has 'children'  => ( isa => 'ArrayRef', is => 'rw', default => sub{ [] } );

with 'PDF::Boxer::Role::SizePosition';

has 'boxer' => ( isa => 'PDF::Boxer', is => 'ro' );

has 'name' => ( isa => 'Str', is => 'ro' );
has 'type' => ( isa => 'Str', is => 'ro', default => 'Box' );
has 'background' => ( isa => 'Str', is => 'ro' );
has 'border_color' => ( isa => 'Str', is => 'ro' );
#has 'display' => ( isa => 'Str', is => 'ro', default => 'inline' );

#has 'sibling'  => ( isa => 'Object', is => 'ro' );
has 'older'  => ( isa => 'Object', is => 'ro' );
has 'younger'  => ( isa => 'Object', is => 'rw' );
has 'parent'  => ( isa => 'Object', is => 'ro' );

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

  return $args;
}

sub BUILD{
  my ($self) = @_;
  unless($self->parent){
    $self->adjust({
      margin_top => $self->boxer->max_height,
      margin_left => 0,
      margin_width => $self->boxer->max_width,
      margin_height => $self->boxer->max_height,
    },'self');
  }
warn "BUILD: ".$self->name."\n";
warn Data::Dumper->Dumper($self);

  foreach my $child (@{$self->children}){
    $child->{boxer} = $self->boxer;
    $child->{debug} = $self->debug;
    my $weak_me = $self;
    weaken($weak_me);
    $child->{parent} = $weak_me;
    my $class = 'PDF::Boxer::Content::'.$child->{type};
    $child = $class->new($child);
  }
#  die sprintf "not enough room for \"%s\" width: mw: %s > %s", $self->name, $self->margin_width, $self->max_width if $self->has_width && $self->margin_width > $self->max_width;
#  die sprintf "not enough room for \"%s\" height: mh: %s > %s", $self->name, $self->margin_height, $self->max_height if $self->has_height && $self->margin_height > $self->max_height;
}

sub propagate{
  my ($self, $method) = @_;
  return unless $method;
  my @kids = @{$self->children};
  if (@kids){
    foreach my $kid (@kids){
      $kid->$method();
    }
  }
  return @kids;
}

sub calculate_minimum_size{
  my ($self) = @_;

  my @kids = $self->propagate('calculate_minimum_size');

  # the main box should stay wide open.
  return unless $self->parent;

  my ($width, $height) = (0,0);
  if (@kids){
    foreach(@kids){
      $height+= $_->margin_height;
      $width = $width ? (sort($_->margin_width,$width))[1] : $_->margin_width;
    }
  } else {
    $width = $self->has_width ? $self->width : 0;
    $height = $self->has_height ? $self->height : 0;
  }

  $self->adjust({
     width => $width,
     height => $height,
  }, 'self');

  warn $self->dump_size;

}

sub size_and_position{
  my ($self) = @_;

  my ($width, $height) = $self->kids_min_size;

  my $kid = $self->children->[0];

  if ($kid){
    $kid->adjust({
      margin_left => $self->content_left,
      margin_top => $self->content_top,
      margin_width => $self->content_width,
      margin_height => $self->content_height,
    },'parent');

    $self->propagate('size_and_position');
  }

  warn $self->dump_all;

  

}

sub kids_min_size{
  my ($self) = @_;
  my $kid = $self->children->[0];
  return ($kid->margin_width, $kid->margin_height) if $kid;
  return (0,0);
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

# send a signal to the non-parents who send the signal back up chain.
sub auto_adjust{
  my ($self, $type) = @_;

    # adjust takes sender rel, not recipient rel as arg.
    my $spec = $self->get_spec;
    $self->adjust($spec, $type );

=pod

warn "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n";
warn $self->dump_all;

    my $cleared = 0;
    foreach(qw!width height margin_left margin_top!){
      my $val = delete $spec->{$_};
      next unless $val;
      $self->$_($val);
      $cleared++;
    }
    $self->clear unless $cleared;

warn p($self);
    foreach my $attr (keys %$spec){
      $self->$attr($spec->{$attr});
    }
warn $self->dump_all;
warn "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n";

=cut

  # check for bottom of page
#  if ($self->margin_bottom < 0 && $self->margin_top > 0){
#warn sprintf "!!!!!!!!!! margin_bottom: %s margin_top: %s margin_height: %s\n",
#  $self->margin_bottom, $self->margin_top, $self->margin_height;
#    $self->adjust({ margin_top => $self->margin_height }, 'self');
#  }


#  if ( $self->pressure_height ){
#    if (my $younger = $self->younger){
#      if ($younger->margin_top > $self->margin_bottom){
#        $self->adjust({ margin_bottom => $younger->margin_top + 1 }, 'self');
#      }
#    }
#  }

=pod

  # propogate auto_adjust
  if ($type eq 'parent'){
    my $desc = 0;
    if (@{$self->children}){
      $self->children->[0]->auto_adjust('parent');
      $desc = 1;
    }
    if ($self->younger){
      $self->younger->auto_adjust('older');
      $desc = 1;
    }
    # send update signal back up (down?) the tree
    unless($desc){
      if ($self->older){
        $self->older->auto_adjust('younger');
      } elsif ($self->parent){
        $self->parent->auto_adjust('child');
      }
    }
  } elsif ($type eq 'younger'){
    if ($self->older){
      $self->older->auto_adjust('younger');
    } elsif ($self->parent){
      $self->parent->auto_adjust('child');      
    }
    if (@{$self->children}){
      $self->children->[0]->auto_adjust('parent');
    }
  } elsif ($type eq 'older'){
    if ($self->younger){
      $self->younger->auto_adjust('older');
    }
    if (@{$self->children}){
      $self->children->[0]->auto_adjust('parent');
    }
  } elsif ($type eq 'child' && $self->parent){
    $self->parent->auto_adjust('child');      
  }



=pod

  if ($type eq 'parent'){
    warn "updating ".$self->name."\n";
    if ($self->older){
      $self->older->auto_adjust('parent');
    } elsif ($self->parent){
      $self->parent->auto_adjust('parent');
    }
  } elsif ($type eq 'children'){
    warn "signalling ".$self->name."\n";
    if (@{$self->children}){
      foreach(@{$self->children}){
        $_->auto_adjust('children');
      }
    } else {
      $self->auto_adjust('parent');
    }
  }

=cut

}

sub get_spec{
  my ($self) = @_;
  my $spec;
  if (my $parent = $self->parent){
    $spec->{max_width}   = $parent->width;
    $spec->{max_height}  = $parent->height;
    $spec->{margin_left} = $parent->content_left;
    $spec->{margin_top}  = $parent->content_top;

    if (my $older = $self->older){
      if ($older->pressure_width){
        $spec->{margin_top}  = $self->limit_to_page_height($older->margin_bottom - 1);
      } else {
        $spec->{max_width}   = $self->limit_to_page_width($parent->width - $older->margin_right - 1);
        $spec->{margin_left} = $self->limit_to_page_width($older->margin_right + 1);
      }
    }

  } else {
    $spec->{max_width}   = $self->max_width;
    $spec->{max_height}  = $self->max_height;
    $spec->{margin_left} = 0;
    $spec->{margin_top}  = $self->max_height;
  }

#=pod

  # set height to put margin_bottom just below last child's margin_bottom.
  if (@{$self->children} && !$self->pressure_height){
    my $margin_bottom = $self->children->[-1]->margin_bottom
                              + $self->padding->[2]
                              + $self->border->[2]
                              + $self->margin->[2];
    $spec->{height} = $spec->{margin_top} - $margin_bottom;
warn "Child: ".$self->children->[-1]->name." margin_bottom = ".$self->children->[-1]->margin_bottom."\n";
warn sprintf "   height (%s) = %s - %s\n", $spec->{height}, $spec->{margin_top}, $margin_bottom;
  }

#=cut

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

