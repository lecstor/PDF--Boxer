package PDF::Boxer::Role::SizePosition;
use Moose::Role;
use Moose::Util::TypeConstraints;

use Carp;

requires qw!margin border padding children!;

subtype 'HCoord',
    as 'Int',
    where { $_ >= 0 && $_ <= 595 },
    message { "HCoord '$_' out of bounds" };

subtype 'VCoord',
    as 'Int',
    where { $_ >= 0 && $_ <= 842 },
    message { "VCoord '$_' out of bounds" };

has 'max_width' => ( isa => 'HCoord', is => 'rw' );
has 'max_height' => ( isa => 'VCoord', is => 'rw' );

has 'width' => ( isa => 'HCoord', is => 'rw', lazy_build => 1, ); #trigger => \&_width_set );
has 'height' => ( isa => 'VCoord', is => 'rw', lazy_build => 1, ); #trigger => \&_height_set );

has 'margin_left' => ( isa => 'HCoord', is => 'rw', lazy_build => 1 ); # required => 1, ); #trigger => \&_margin_left_set );
has 'margin_top'  => ( isa => 'VCoord', is => 'rw', lazy_build => 1 ); # required => 1, ); #trigger => \&_margin_top_set );

has 'margin_right' => ( isa => 'HCoord', is => 'rw', lazy_build => 1 );
has 'margin_bottom'  => ( isa => 'VCoord', is => 'rw', lazy_build => 1 );

has 'border_left' => ( isa => 'HCoord', is => 'ro', lazy_build => 1 );
has 'border_top'  => ( isa => 'VCoord', is => 'ro', lazy_build => 1 );

has 'padding_left' => ( isa => 'HCoord', is => 'ro', lazy_build => 1 );
has 'padding_top'  => ( isa => 'VCoord', is => 'ro', lazy_build => 1 );

has 'content_left' => ( isa => 'HCoord', is => 'ro', lazy_build => 1 );
has 'content_top'  => ( isa => 'VCoord', is => 'ro', lazy_build => 1 );

has 'content_right' => ( isa => 'HCoord', is => 'rw', lazy_build => 1 );
has 'content_bottom'  => ( isa => 'VCoord', is => 'rw', lazy_build => 1 );

has 'margin_width'    => ( isa => 'HCoord', is => 'rw', lazy_build => 1 );
has 'margin_height'   => ( isa => 'VCoord', is => 'rw', lazy_build => 1 );

has 'border_width'    => ( isa => 'HCoord', is => 'rw', lazy_build => 1 );
has 'border_height'   => ( isa => 'VCoord', is => 'rw', lazy_build => 1 );

has 'padding_width'    => ( isa => 'HCoord', is => 'rw', lazy_build => 1 );
has 'padding_height'   => ( isa => 'VCoord', is => 'rw', lazy_build => 1 );


has 'pressure' => ( isa => 'Bool', is => 'ro', default => 0 );
has 'pressure_width' => ( isa => 'Bool', is => 'ro', lazy_build => 1 );
has 'pressure_height' => ( isa => 'Bool', is => 'ro', lazy_build => 1 );

has 'grow' => ( isa => 'Bool', is => 'ro', default => 0 );

has 'attribute_rels' => ( isa => 'HashRef', is => 'ro', lazy_build => 1 );

sub _build_attribute_rels{
  return {
    max_width     => [qw! margin_right content_right margin_width border_width padding_width !],
    max_height    => [qw! margin_bottom content_bottom margin_height border_height padding_height!],
    width         => [qw! margin_right content_right margin_width border_width padding_width !],
    height        => [qw! margin_bottom content_bottom margin_height border_height padding_height!],
    margin_left   => [qw! margin_right border_left padding_left content_left !],
    margin_top    => [qw! margin_bottom border_top padding_top content_top content_bottom !],
    margin_right  => [qw! margin_left border_left padding_left content_left content_right !],
    margin_bottom => [qw! margin_top border_top padding_top content_top content_bottom !],
    margin_width  => [qw! width margin_right content_right border_width padding_width !],
    margin_height => [qw! height margin_bottom content_bottom border_height padding_height !],
  }
}

# we need to be able to calculate width, height, x & y of lower left corner
# x: margin_left, content_left, margin_right & margin_width, content_right & content_width
# y: margin_top, content_top, margin_bottom & margin_height, content_bottom & content_height
# width: width, margin_width, content_width, margin_left & margin_right, content_left & content_right
# height: height, margin_height, content_height, margin_top & margin_bottom, content_top & content_bottom

my $req = {
  horiz => [
    [qw! margin_left !],
    [qw! content_left !],
    [qw! margin_right margin_width !],
    [qw! content_right content_width !],
  ],
  vert => [
    [qw! margin_top !],
    [qw! content_top !],
    [qw! margin_bottom margin_height !],
    [qw! content_bottom content_height !],
  ],
  width => [
    [qw! width !],
    [qw! margin_width !],
    [qw! margin_left margin_right !],
    [qw! content_left content_right!],
  ],
  height => [
    [qw! height !],
    [qw! margin_height !],
    [qw! content_height !],
    [qw! margin_top margin_bottom !],
    [qw! content_top content_bottom !],
  ]
};


sub change_size{
  my ($self, $width_change, $height_change) = @_;
  $self->clear_size;
  $self->width($self->width + $width_change);
  $self->height($self->height + $height_change);
}

sub move{
  my ($self, $horiz, $vert) = @_;
  $self->clear_position;
  $self->margin_left($self->margin_left + $horiz);
  $self->margin_top($self->margin_top + $vert);
}

sub modify{
  my ($self, $spec) = @_;

  my $ok = $self->check_modify_spec($spec);
  unless (scalar keys %$ok == 4){
    die "Invalid modify spec\n".Data::Dumper->Dumper($spec);
  }

  $self->clear_position;
  $self->clear_size;

  foreach my $attr (keys %$spec){
    $self->$attr($spec->{$attr});
  }

}

sub check_modify_spec{
  my ($self, $spec) = @_;
  my $ok = {};
  MEAS: foreach my $measure ( keys %$spec){
    REQ: foreach my $required (@{$spec->{$measure}}){
      foreach(@$required){
        next REQ unless $spec->{$_};
      }
      $ok->{$measure}++;
      next MEAS;
    }
  }
  return $ok;
}


# another approach.. when notified to refresh the node checks
# predefined boundaries and adjusts accordingly.
sub refresh{
  my ($self, $sender) = @_;

  if (my $parent = $self->parent){
    # I'm inside the parent, my margin should not exceed it's content area.
    if ($self->margin_left < $parent->content_left){
      $self->adjust({ margin_left => $parent->content_left }, 'self');
    }
    if ($self->margin_top > $parent->content_top){
      $self->adjust({ margin_top => $parent->content_top }, 'self');
    }
    if ($self->margin_right > $parent->content_right){
      $self->adjust({ margin_width => $self->margin_width - ($self->margin_right - $parent->content_right) }, 'self');
    }
    if ($self->margin_bottom > $parent->content_bottom){
#      $self->adjust({ margin_height => $self->margin_height - ($self->margin_bottom - $parent->content_bottom) }, 'self');
      $self->adjust({ margin_bottom => $parent->content_bottom }, 'self');
    }
  }

  if (my $older = $self->older){
    if ($older->pressure_width){
      # older is above
      if ($self->margin_top > $older->margin_bottom){
        $self->adjust({ margin_top => $older->margin_bottom }, 'self');
      }
    } else {
      # older is to left
      if ($self->margin_left < $older->margin_right){
        $self->adjust({ margin_left => $older->margin_right }, 'self');
      }
    }
  }

  if (my $younger = $self->younger){
    if ($self->pressure_width){
      # younger is below
      if ($self->margin_bottom < $younger->margin_top){
        $self->adjust({ margin_bottom => $younger->margin_top }, 'self');
      }
    } else {
      # younger is to right
      if ($self->margin_right > $younger->margin_left){
        $self->adjust({ margin_width => $self->margin_width - ($self->margin_right - $younger->margin_left) }, 'self');
      }
    }
  }

  if (my @childs = @{$self->children}){
    my $low_margin = shift(@childs)->margin_bottom;
    foreach(@childs){
      $low_margin = $_->margin_bottom if $_->margin_bottom < $low_margin;
    }
    if ($self->content_bottom > $low_margin){
      $self->adjust({ content_bottom => $low_margin }, 'self');
    }

  }

  if ($sender eq 'parent'){
    my $desc = 0;
    if (@{$self->children}){
      $self->children->[0]->refresh('parent');
      $desc = 1;
    }
    if ($self->younger){
      $self->younger->refresh('older');
      $desc = 1;
    }
    # send update signal back up (down?) the tree
    unless($desc){
      if ($self->older){
        $self->older->refresh('younger');
      } elsif ($self->parent){
        $self->parent->refresh('child');
      }
    }
  } elsif ($sender eq 'younger'){
    if ($self->older){
      $self->older->refresh('younger');
    } elsif ($self->parent){
      $self->parent->refresh('child');      
    }
    if (@{$self->children}){
      $self->children->[0]->refresh('parent');
    }
  } elsif ($sender eq 'older'){
    if ($self->younger){
      $self->younger->refresh('older');
    }
    if (@{$self->children}){
      $self->children->[0]->refresh('parent');
    }
  } elsif ($sender eq 'child' && $self->parent){
    $self->parent->refresh('child');      
  }

}

=item adjust

takes values for any of the predefined size and location attributes.
Decides what to do about it..

=cut


sub adjust{
  my ($self, $spec, $sender) = @_;

warn $self->name." adjust from $sender ".Data::Dumper->Dumper($spec);

  foreach my $attr (keys %$spec){
    $self->$attr($spec->{$attr});
    foreach ( @{$self->attribute_rels->{$attr}} ){
      next if $spec->{$_}; # don't clear anything which is in the spec
      my $clear = 'clear_'.$_;
      $self->$clear();
    }
  }

#  $self->refresh($sender);

=pod

  if ($self->older){
    if ($self->older->pressure_width){
      # older is above us
      if ($self->margin_top > $self->older->margin_bottom){
        $self->older->adjust({ margin_bottom => $self->limit_to_page_height($self->margin_top - 1) });
      }
    } else {
      # older is to our left
    }
  
  }

  if ($self->parent){
    if ($self->parent->content_bottom > $self->margin_bottom){
      $self->parent->adjust({ content_bottom => $self->margin_bottom + 1 });
    }
  }

#  if ( $self->pressure_height ){
#    if (my $younger = $self->younger){
#      if ($younger->margin_top > $self->margin_bottom){
#        $self->adjust({ margin_bottom => $younger->margin_top + 1 }, 'self');
#      }
#    }
#  }


  foreach my $attr (keys %$spec){
#    if ($attr eq 'max_width'){
#      $self->younger->adjust({ margin_left => $self->margin_right + 1 }) if ! $self->pressure_width;
#    }
#    if ($attr eq 'max_height'){
#      $self->younger->adjust({ margin_top => $self->margin_bottom - 1 }) if ! $self->pressure_width;
#    }
    if ($sender ne 'younger' && $self->younger){
      if ($attr eq 'width' || $attr eq 'margin_width'){
        if ( !$self->pressure_width ){  # we're next to younger sibling
          $self->younger->adjust({ 
            margin_left => $self->limit_to_page_width($self->margin_right + 1)
          }, 'older');
          if ($self->margin_right >= $self->younger->margin_left){
            $self->adjust({ margin_right => $self->younger->margin_left - 1 });
          }
        }
      }
      if ($attr eq 'height' || $attr eq 'margin_height'){
        if ( $self->pressure_width ){  # we're above younger sibling
          $self->younger->adjust({
            margin_top => $self->limit_to_page_height($self->margin_bottom - 1)
          }, 'older') if $self->pressure_width;
          if ($self->margin_bottom >= $self->younger->margin_top){
            $self->adjust({ margin_bottom => $self->younger->margin_top + 1 });
          }
        }
      }
      if ($attr eq 'margin_left'){
        if ( !$self->pressure_width ){  # we're next to younger sibling
          $self->younger->adjust({
            margin_left => $self->limit_to_page_width($self->margin_right + 1)
          }, 'older') if ! $self->pressure_width;
          if ($self->margin_right >= $self->younger->margin_left){
            $self->adjust({ margin_right => $self->younger->margin_left - 1 });
          }
        }
      }
      if ($attr eq 'margin_right'){
        if ( !$self->pressure_width ){  # we're next to younger sibling
          $self->younger->adjust({
            margin_left => $self->limit_to_page_width($self->margin_right + 1)
          }, 'older') if ! $self->pressure_width;
#          if ($self->margin_right >= $self->younger->margin_left){
#            $self->adjust({ margin_right => $self->younger->margin_left - 1 });
#          }
        }
      }
      if ($attr eq 'margin_bottom'){
        $self->younger->adjust({
          margin_top => $self->limit_to_page_height($self->margin_bottom - 1)
        }, 'older') if ! $self->pressure_width;
      }
    }

    if ($sender ne 'older' && $self->older){
      if ($attr eq 'margin_left'){
        $self->older->adjust({
          margin_right => $self->limit_to_page_width($self->margin_left - 1)
        }, 'younger' ) if ! $self->older->pressure_width;
      }
      if ($attr eq 'margin_right'){
        $self->older->adjust({ 
          margin_left => $self->limit_to_page_width($self->margin_right + 1)
        }, 'younger' ) if ! $self->older->pressure_width;
      }
    }

  }

  warn sprintf "Adjusted Node: %s\n", $self->name;
  $self->dump_all;

  if ($sender eq 'parent'){
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
  } elsif ($sender eq 'younger'){
    if ($self->older){
      $self->older->auto_adjust('younger');
    } elsif ($self->parent){
      $self->parent->auto_adjust('child');      
    }
    if (@{$self->children}){
      $self->children->[0]->auto_adjust('parent');
    }
  } elsif ($sender eq 'older'){
    if ($self->younger){
      $self->younger->auto_adjust('older');
    }
    if (@{$self->children}){
      $self->children->[0]->auto_adjust('parent');
    }
  } elsif ($sender eq 'child' && $self->parent){
    $self->parent->auto_adjust('child');      
  }


=cut

#  warn "== Adjust Done ==\n";
#  warn $self->dump_position;
#  warn $self->dump_size;

}

sub clear_position{
  my ($self) = @_;
  my $meth;
  foreach (qw!margin_right margin_bottom border_left border_top padding_left padding_top
             content_left content_top content_right content_bottom!){
    $meth = "clear_$_";
    $self->$meth();
  }
}

sub clear_size{
  my ($self) = @_;
  my $meth;
  foreach(qw!margin_width margin_height
             border_width border_height padding_width padding_height!){
    $meth = "clear_$_";
    $self->$meth();
  }
}

sub _build_margin_left{
  my ($self) = @_;
  if ($self->has_content_left){
    return $self->content_left - $self->padding->[3] - $self->border->[3] - $self->margin->[3];
  } elsif ($self->has_margin_right && $self->has_margin_width){
    return $self->margin_right - $self->margin_width;
  } elsif ($self->has_content_right && $self->has_content_width){
    return $self->content_right - $self->content_width;
  }

  warn $self->name; #."\n".$self->dump_all."\n";
  my %tmp = %$self;
  delete $tmp{boxer};
  delete $tmp{children};
  delete $tmp{older};
  delete $tmp{younger};
  delete $tmp{parent};
  warn Data::Dumper->Dumper(\%tmp);
  die "unable to build margin_left for ".$self->name."\t\t";
}

sub _build_margin_right{
  my ($self) = @_;
  return $self->margin_left + $self->margin_width;
}

sub _build_margin_top{
  my ($self) = @_;
  if ($self->has_content_top){
    return $self->content_top + $self->padding->[0] + $self->border->[0] + $self->margin->[0];
  } elsif ($self->has_margin_bottom && $self->has_margin_height){
    return $self->margin_bottom - $self->margin_height;
  } elsif ($self->has_content_bottom && $self->has_content_height){
    return $self->content_bottom - $self->content_height;
  }

  confess "unable to build margin_top for ".$self->name;
}

sub _build_margin_bottom{
  my ($self) = @_;
warn sprintf "margin bottom = mt %s - mh %s", $self->margin_top, $self->margin_height;
  my $pos = $self->margin_top - $self->margin_height;
  my $spacing = 0;
  return $self->limit_to_page_height($pos,$spacing);
}

sub _build_border_left{
  my ($self) = @_;
  return $self->margin_left + $self->margin->[3];
}

sub _build_border_top{
  my ($self) = @_;
  return $self->margin_top - $self->margin->[0];
}

sub _build_padding_left{
  my ($self) = @_;
  return $self->border_left + $self->border->[3];
}

sub _build_padding_top{
  my ($self) = @_;
  my $pos = $self->border_top - $self->border->[0];
  my $spacing = $self->border->[0] + $self->margin->[0];
  return $self->limit_to_page_height($pos,$spacing);
}

sub _build_content_left{
  my ($self) = @_;
  return $self->padding_left + $self->padding->[3];
}

sub _build_content_top{
  my ($self) = @_;
  my $pos = $self->padding_top - $self->padding->[0];
  my $spacing = $self->padding->[2] + $self->border->[2] + $self->margin->[2];
  return $self->limit_to_page_height($pos,$spacing);
}

sub _build_content_right{
  my ($self) = @_;

warn sprintf "Content right: %s + %s", $self->content_left, $self->width;

  return $self->content_left + $self->width;
}

sub _build_content_bottom{
  my ($self) = @_;
  my $pos = $self->content_top - $self->height;
  my $spacing = $self->padding->[2] + $self->border->[2] + $self->margin->[2];
  return $self->limit_to_page_height($pos,$spacing);
}

sub limit_to_page_height{
  my ($self, $val, $spacing) = @_;
  $spacing ||= 0;
  if ($val < 0 + $spacing){
    return $spacing;
  }
  if ($val > $self->boxer->max_height - $spacing){
    return $self->boxer->max_height - $spacing;
  }
  return $val;
}

sub limit_to_page_width{
  my ($self, $val, $spacing) = @_;
  $spacing ||= 0;
  if ($val < 0 + $spacing){
    return $spacing;
  }
  if ($val > $self->boxer->max_width - $spacing){
    return $self->boxer->max_width - $spacing;
  }
  return $val;
}

sub _build_width{
  my ($self) = @_;

  if ($self->has_margin_width){
    return $self->margin_width - (($self->padding->[3] + $self->border->[3] + $self->margin->[3])*2);
  } elsif ($self->has_margin_left && $self->has_margin_right){
    return $self->margin_right - $self->margin_left - (($self->padding->[3] + $self->border->[3] + $self->margin->[3])*2);
  } elsif ($self->has_content_left && $self->has_content_right){
    return $self->content_right - $self->content_left;
  }
  die "unable to build margin_left";


  my $val;
  if ($self->pressure_width){
    $val = $self->padding_width - ($self->padding->[1] + $self->padding->[3]);
  } else {
    $val = $self->_width_from_child;
warn ">>>>> Size build width min: $val\n"; 
  }
  my $spacing = $self->padding->[1] + $self->border->[1] + $self->margin->[1];
  return $self->limit_to_page_height($val,$spacing);
}

sub _build_height{
  my ($self) = @_;

  if ($self->has_margin_height){
    return $self->margin_height
      - ($self->padding->[0] + $self->padding->[2]
        + $self->border->[0] + $self->border->[2] 
        + $self->margin->[0] + $self->margin->[2]);
  } elsif ($self->has_margin_left && $self->has_margin_right){
    return $self->margin_right - $self->margin_left
      - ($self->padding->[0] + $self->padding->[2]
        + $self->border->[0] + $self->border->[2] 
        + $self->margin->[0] + $self->margin->[2]);
  } elsif ($self->has_content_left && $self->has_content_right){
    return $self->content_right - $self->content_left;
  }
  die "unable to build margin_left";


  my $val;
  if ($self->pressure_height){
    $val = $self->padding_height - ($self->padding->[0] + $self->padding->[2]);
  } else {
    $val = $self->_height_from_child - ($self->padding->[0] + $self->padding->[2]);
warn ">>>>> Size build height min: $val\n"; 
  }

  my $spacing = $self->padding->[2] + $self->border->[2] + $self->margin->[2];
  return $self->limit_to_page_height($val,$spacing);

  return $val;
}

sub _height_from_child{
  my ($self) = @_;
  my $low_child_margin_bottom = 0;
  if (my $child = $self->children->[-1]){
    warn "Child: ".$child->name."\n";
    $low_child_margin_bottom = $child->margin_bottom;
  }
warn "Height from child: ".$self->content_top." - $low_child_margin_bottom\n";
  return $self->content_top - $low_child_margin_bottom;
}

sub _width_from_child{
  my ($self) = @_;
  my $right_child_margin_right = 0;
  if (my $child = $self->children->[-1]){
    warn "Child: ".$child->name."\n";
    $right_child_margin_right = $child->margin_right;
  }
  my $content_right = $right_child_margin_right + 1;
warn "Width from child: ".$self->content_left." - $content_right\n";
  return $content_right - $self->content_left;
#  return $self->content_left - $content_right;
}

sub content_width{ shift->width }
sub content_height{ shift->height }

sub _build_padding_width{
  my ($self) = @_;
  my $val;
  if ($self->has_width){
    $val = $self->width + $self->padding->[1] + $self->padding->[3];
  } elsif ($self->pressure_width) {
    $val = $self->border_width - ($self->border->[1] + $self->border->[3]);
  } else {
    $val = $self->width + $self->padding->[1] + $self->padding->[3];
#    die "Minimise Box not implemented yet..";
  }
  return $val;
}

sub _build_padding_height{
  my ($self) = @_;
  my $val;
  if ($self->has_height){
    $val = $self->height + $self->padding->[0] + $self->padding->[2];
  } elsif ($self->pressure_height) {
    $val = $self->border_height - ($self->border->[0] + $self->border->[2]);
  } else {
    $val = $self->height + $self->padding->[0] + $self->padding->[2];
  }
  return $val;
}

sub _build_border_width{
  my ($self) = @_;
  my $val;
  if ($self->has_width){
    $val = $self->padding_width + $self->border->[1] + $self->border->[3];
  } elsif ($self->pressure_width) {
    $val = $self->margin_width - ($self->margin->[1] + $self->margin->[3]);
  } else {
    $val = $self->padding_width + $self->border->[1] + $self->border->[3];
  }
  return $val;
}

sub _build_border_height{
  my ($self) = @_;
  my $val;
  if ($self->has_height){
    $val = $self->padding_height + $self->border->[0] + $self->border->[2];
  } elsif ($self->pressure_height) {
    $val = $self->margin_height - ($self->margin->[0] + $self->margin->[2]);
  } else {
    $val = $self->padding_height + $self->border->[0] + $self->border->[2];
  }
  return $val;
}

sub _build_margin_width{
  my ($self) = @_;
  my $val;
  if ($self->has_width){
    $val = $self->border_width + $self->margin->[1] + $self->margin->[3];
  } elsif ($self->pressure_width) {
    $val = $self->max_width;
  } else {
    $val = $self->border_width + $self->margin->[1] + $self->margin->[3];
  }
  return $val;
}

sub _build_margin_height{
  my ($self) = @_;
  my $val;
  if ($self->has_height){
    $val = $self->border_height + $self->margin->[0] + $self->margin->[2];
  } elsif ($self->pressure_height) {
    $val = $self->max_height;
  } else {
    $val = $self->border_height + $self->margin->[0] + $self->margin->[2];
  }
  return $val;
}

sub _build_pressure_width{ shift->pressure }
sub _build_pressure_height{ shift->pressure }

sub dump_size{
  my ($self) = @_;
  my @lines = (
    '== Size: '.$self->name.' ==',
    (sprintf 'Max: %s x %s', $self->max_width, $self->max_height),
    (sprintf 'Margin: %s x %s', $self->margin_width, $self->margin_height),
    (sprintf 'Border: %s x %s', $self->border_width, $self->border_height),
    (sprintf 'Padding: %s x %s', $self->padding_width, $self->padding_height),
    (sprintf 'Content: %s x %s', $self->width, $self->height),
    (sprintf 'Pressure: %s x %s', $self->pressure_width, $self->pressure_height),
    (sprintf 'Content: %s x %s', $self->width, $self->height),
  );
  $_ .= "\n" foreach @lines;
  return join('', @lines);
}


sub dump_position{
  my ($self) = @_;
  my @lines = (
    '== Pos: '.$self->name.' ==',
    (sprintf 'Margin: %s %s %s %s', $self->margin_top, $self->margin_right, $self->margin_bottom, $self->margin_left),
    (sprintf 'Border: %s x %s', $self->border_left, $self->border_top),
    (sprintf 'Padding: %s x %s', $self->padding_left, $self->padding_top),
    (sprintf 'Content: %s x %s', $self->content_left, $self->content_top),
  );
  $_ .= "\n" foreach @lines;
  return join('', @lines);
}

1;

