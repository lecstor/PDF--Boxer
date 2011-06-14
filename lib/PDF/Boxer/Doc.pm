package PDF::Boxer::Doc;
use Moose;
use namespace::autoclean;

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

has 'font' => ( isa => 'HashRef', is => 'ro', lazy_build => 1 );
sub _build_font{
  my ($self) = @_;
  return {
    Helvetica => {
      Bold   => $self->pdf->corefont( 'Helvetica-Bold',    -encoding => 'latin1' ),
      Roman  => $self->pdf->corefont( 'Helvetica',         -encoding => 'latin1' ),
      Italic => $self->pdf->corefont( 'Helvetica-Oblique', -encoding => 'latin1' ),
    },
  };
}

__PACKAGE__->meta->make_immutable;

1;
