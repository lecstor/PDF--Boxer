package PDF::Boxer::Doc;
use Moose;
use namespace::autoclean;

use PDF::API2;

has 'file' => ( isa => 'Str', is => 'ro', required => 1 );

has 'pdf' => ( isa => 'Object', is => 'ro', lazy_build => 1 );
sub _build_pdf{
  return PDF::API2->new( -file => shift->file );
}

has 'page' => ( isa => 'Object', is => 'rw', lazy_build => 1 );
sub _build_page{
  my ($self) = @_;
  my $page = $self->pdf->page;
  $page->mediabox(0,0,$self->page_width, $self->page_height);
#  $page->cropbox($self->page_width-10, $self->page_height);
  return $page;
}

# default to A4
has 'page_width'    => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'page_height'   => ( isa => 'Int', is => 'ro', lazy_build => 1 );
sub _build_page_width{ 595 }
sub _build_page_height{ 842 }

has 'gfx' => ( isa => 'Object', is => 'rw', lazy_build => 1 );
sub _build_gfx{ shift->page->gfx }

has 'text' => ( isa => 'Object', is => 'rw', lazy_build => 1 );
sub _build_text{
  my $txt = shift->page->text;
  $txt->compressFlate;
  return $txt;
}

has 'fonts' => ( isa => 'HashRef', is => 'ro', lazy_build => 1 );
sub _build_fonts{
  my ($self) = @_;
  return {
    'Helvetica'        => { type => 'corefont', id => 'Helvetica', -encoding => 'latin1' },
    'Helvetica-Bold'   => { type => 'corefont', id => 'Helvetica-Bold', -encoding => 'latin1' },
    'Helvetica-Italic' => { type => 'corefont', id => 'Helvetica-Oblique', -encoding => 'latin1' },
    'Times'            => { type => 'corefont', id => 'Times', -encoding => 'latin1' },
    'Times-Bold'       => { type => 'corefont', id => 'Times-Bold', -encoding => 'latin1' },
  }
}

sub font{
  my ($self, $name) = @_;
  my $font = $self->fonts->{$name};
  die "cannot find font '$name' in fonts list" unless $font;
  return $font unless ref($font) eq 'HASH';
  my $font_type = delete $font->{type};
  my $font_id = delete $font->{id};
  return $self->fonts->{$name} = $self->pdf->$font_type($font_id, 1); #%$font);
}

__PACKAGE__->meta->make_immutable;

1;

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Jason Galea <lecstor at cpan.org>. All rights reserved.

This library is free software and may be distributed under the same terms as perl itself.

=cut

