package PDF::Boxer::Doc;
use Moose;
use namespace::autoclean;

use PDF::API2;

has 'file' => ( isa => 'Str', is => 'ro', required => 1 );

has 'pdf' => ( isa => 'Object', is => 'ro', lazy_build => 1 );
sub _build_pdf{ PDF::API2->new( -file => shift->file ) }

has 'page' => ( isa => 'Object', is => 'rw', lazy_build => 1 );
sub _build_page{
  my ($self) = @_;
  my $page = $self->pdf->page;
  $page->mediabox($self->page_width, $self->page_height);
#  $page->cropbox(20,20,615,862);
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
sub _build_text{ shift->page->text }

has 'fonts' => ( isa => 'HashRef', is => 'ro', lazy_build => 1 );
sub _build_fonts{
  my ($self) = @_;
  return {
    'Helvetica'        => { type => 'corefont', id => 'Helvetica', -encoding => 'latin1' },
    'Helvetica-Bold'   => { type => 'corefont', id => 'Helvetica-Bold', -encoding => 'latin1' },
    'Helvetica-Italic' => { type => 'corefont', id => 'Helvetica-Oblique', -encoding => 'latin1' },
  }
}

sub font{
  my ($self, $name) = @_;
  my $font = $self->fonts->{$name};
  die "cannot find font '$name' in fonts list" unless $font;
  return $font unless ref($font) eq 'HASH';
  my $font_type = delete $font->{type};
  my $font_id = delete $font->{id};
  return $self->fonts->{$name} = $self->pdf->$font_type($font_id, %$font);
}

__PACKAGE__->meta->make_immutable;

1;
