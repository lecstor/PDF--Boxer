package PDF::Boxer::Content::Text;
use Moose;
use namespace::autoclean;
use DDP;

extends 'PDF::Boxer::Content::Box';
with 'PDF::Boxer::Role::Text';


sub get_default_size{
  my ($self) = @_;
  my $space = $self->boxer->max_width;
  my ($width, $height) = $self->find_smallest_block($space);
warn sprintf "Text %s default size: %s x %s\n", $self->name, $width, $height if $self->name; 
  return (int($width+1), int($height+1));
}

around 'update' => sub{
  my ($orig, $self) = @_;

  # update children
  #$self->$orig();
  my ($width, $height) = $self->find_smallest_block($self->width);
warn sprintf "Text %s smallest_block %s x %s\n", ($self->name, $width, $height) if $self->name;
  $self->set_height($height) if $self->height < $height;

warn sprintf "Text %s child_adjusted_height? %s < %s\n", $self->name, $self->margin_bottom, $self->parent->content_bottom if $self->name;
  if ($self->margin_bottom < $self->parent->content_bottom){
warn "Text child_adjusted_height\n";
    $self->parent->child_adjusted_height($self);
  }
  
};

around 'render' => sub{
  my ($orig, $self) = @_;

  my $text = $self->prepare_text;

  my $wrapped_lines = $self->wrapped_lines([@{$self->value}], $self->width);

  my $longest_line_length = $self->longest_line($wrapped_lines);

  my $font = $self->get_font;

  my $x = $self->content_left;
  my $y = $self->baseline_top($font, $self->size);
  my $align_method = 'text';

  foreach($self->align || ()){
    /^rig/ && do { $x = $self->content_right; $align_method = 'text_right' };
    /^cen/ && do { $x += ($self->width/2);    $align_method = 'text_center' };
  }

  $text->translate($x,$y);
  foreach(@$wrapped_lines){
    $text->$align_method( $_ );
    $text->cr;
  }

  $self->$orig();

};




sub find_smallest_block{
  my ($self, $space) = @_;
  return if $space > 1000;
  my $wrapped_lines = $self->wrapped_lines([@{$self->value}], $space);
  my $width = $self->longest_line($wrapped_lines);
  my $height = $self->lead * scalar @$wrapped_lines;
warn sprintf "Text %s find_smallest_block: %s x %s\n", $self->name, $width, $height if $self->name; 
  return ($width, $height); # if 1 - $width/($height || 1) < .2;
  #return $self->find_smallest_block($space + 10);
}

sub longest_line{
  my ($self, $lines) = @_;
  my $text = $self->prepare_text;
  my $longest_line_length = 0;
  foreach my $line (@$lines){
    my $len = $text->advancewidth($line);
    $longest_line_length = $len if $len > $longest_line_length;
  }
  return $longest_line_length;
}

sub wrapped_lines{
  my ($self, $lines, $space) = @_;
  my @wrapped_lines;
#  $space ||= $self->width;
  my $text = $self->prepare_text;
  foreach my $line (@$lines){
    my $len = $text->advancewidth($line);
    if ($len > $space){
      my $wrapped_lines = $self->split_line($line, $space);
      push(@wrapped_lines, @$wrapped_lines);
    } else {
      push(@wrapped_lines, $line);
    }
  }
  return (\@wrapped_lines);
}

sub split_line{
  my ($self, $line, $width) = @_;
  my @words = ref $line ? @$line : split(/\s+/, $line);
  my @wrapped_lines;  
  my $text = $self->prepare_text;
  while (@words){
    my $new_line = shift @words;
    while (@words && $text->advancewidth($new_line.' '.$words[0]) < $width){
      last unless @words;
      $new_line .= ' ' . shift @words;
    }
    push(@wrapped_lines, $new_line);  
  }
#  if (@words){
#    push(@wrapped_lines, @{$self->split_line(\@words)});
#  }
  return \@wrapped_lines;
}



__PACKAGE__->meta->make_immutable;

1;

__END__






sub set_minimum_size{
  my ($self) = @_;

  my $space = 10;
  my ($width, $height) = $self->find_smallest_block($space);

  my $int_width = int($width);
  $int_width++ if $width > $int_width;

  my $int_height = int($height);
  $int_height++ if $height > $int_height;

  $self->adjust({
     width => $int_width,
     height => $int_height,
  }, 'self-set_minimum_size');

  return ($int_width, $int_height);
}

sub size_and_position{
  my ($self) = @_;
  my $wrapped_lines = $self->wrapped_lines([@{$self->value}], $self->width);
  my $longest_line_length = int($self->longest_line($wrapped_lines))+1;
  $self->adjust({
     width => $longest_line_length,
     height => int($self->lead * scalar @$wrapped_lines)+1,
  }, 'self-set_minimum_size');

}

=pod

sub tighten{
  my ($self) = @_;
  my $wrapped_lines = $self->wrapped_lines([@{$self->value}], $self->width);
  my $height = int($self->lead * scalar @$wrapped_lines)+1;

  if ($self->height > $height){
    $self->adjust({ height => $height });
  }

}

around 'adjust' => sub{
  my ($orig, $self, $spec, $sender) = @_;
  $self->$orig($spec, $sender);

  my $wrapped_lines = $self->wrapped_lines([@{$self->value}], $self->width);
  my $height = int($self->lead * scalar @$wrapped_lines)+1;

  if ($self->height > $height){
    $self->adjust({ height => $height });
  }

};

=cut

around 'render' => sub{
  my ($orig, $self) = @_;

  my $text = $self->prepare_text;

  my $wrapped_lines = $self->wrapped_lines([@{$self->value}], $self->width);

warn p($self->value);
warn p($wrapped_lines);

  my $longest_line_length = $self->longest_line($wrapped_lines);

  my $font = $self->get_font;

  my $x = $self->content_left;
  my $y = $self->baseline_top($font, $self->size);
  my $align_method = 'text';

  foreach($self->align || ()){
    /^rig/ && do { $x = $self->content_right; $align_method = 'text_right' };
    /^cen/ && do { $x += ($self->width/2);    $align_method = 'text_center' };
  }

  $text->translate($x,$y);
  foreach(@$wrapped_lines){
    $text->$align_method( $_ );
    $text->cr;
  }

  $self->$orig();

};


__PACKAGE__->meta->make_immutable;

1;

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Jason Galea <lecstor at cpan.org>. All rights reserved.

This library is free software and may be distributed under the same terms as perl itself.

=cut

