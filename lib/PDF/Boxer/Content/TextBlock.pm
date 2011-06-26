package PDF::Boxer::Content::TextBlock;
use Moose;
use PDF::TextBlock;
use namespace::autoclean;

extends 'PDF::Boxer::Content::Box';
with 'PDF::Boxer::Role::Text';

has 'textblock' => ( isa => 'Object', is => 'ro', lazy_build => 1 );
sub _build_textblock{
  my ($self) = @_;
  my $tb  = PDF::TextBlock->new({
     pdf   => $self->boxer->doc->pdf,
     page  => $self->boxer->doc->page,
     fonts => {
        default => PDF::TextBlock::Font->new({
           pdf  => $self->boxer->doc->pdf,
           font => $self->get_font($self->font),
           size => $self->size,
           fillcolor => $self->color,
        }),
        b => PDF::TextBlock::Font->new({
           pdf  => $self->boxer->doc->pdf,
           font => $self->get_font($self->font_bold),
           font => $self->size,
           fillcolor => $self->color,
        }),
     },
  });

  return $tb;
}

around 'render' => sub{
  my ($orig, $self) = @_;

  my $text = $self->prepare_text();

warn "TEXT: ".join("\n",@{$self->value})."\n";

  my $textblock = $self->textblock;
  $textblock->x($self->content_left);
  $textblock->y($self->content_top);
  $textblock->w($self->content_width);
  $textblock->h($self->content_height);
  $textblock->align($self->align) if $self->align;
  $textblock->text(join("\n",@{$self->value}));
  $textblock->apply;

  $self->$orig();

};

__PACKAGE__->meta->make_immutable;

1;

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Jason Galea <lecstor at cpan.org>. All rights reserved.

This library is free software and may be distributed under the same terms as perl itself.

=cut

