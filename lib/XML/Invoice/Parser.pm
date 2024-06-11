package XML::Invoice::Parser;

use strict;
use warnings;

use List::Util qw(first);
use XML::LibXML;

use XML::Invoice::Parser::UBL;
use XML::Invoice::Parser::CrossIndustryInvoice;
use XML::Invoice::Parser::CrossIndustryDocument;

use constant RES_OK => 0;
use constant RES_XML_PARSING_FAILED => 1;
use constant RES_UNKNOWN_ROOT_NODE_TYPE => 2;

our @document_modules = qw(
  XML::Invoice::Parser::CrossIndustryDocument
  XML::Invoice::Parser::CrossIndustryInvoice
  XML::Invoice::Parser::UBL
);

=head1 NAME

XML::Invoice::Parser - Parse various XML invoice formats with format auto detection

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 DESCRIPTION

C<XML::Invoice::Parser> is a universal parser for various XML invoice formats specified
in EN16931 (XRechnung/Factur-X/ZUGFeRD 2.x and higher) and adjacent ones
(ZUGFeRD 1.0).  

C<XML::Invoice::Parser> will automatically detect the format of an XML invoice passed as
a flat string and will handle all details from there: depending on its document
type declaration, it will pick and instatiate the appropriate C<XML::Invoice::Parser>
child class for parsing the document and return an object exposing its data
with the standardized structure outlined in the synopsis below.

Please note that the parser classes work on pure XML only. For hybrid formats
where the XML data is attached to a PDF document (such as ZUGFeRD), you need to
extract the XML payload and pass that XML payload to C<XML::Invoice::Parser>. Handling
PDF attachments is outside C<XML::Invoice::Parser>'s scope. That being said, the
xmlbill2txt and xmlbill2csv shipped with this module can deal with extracting
XML attachments from PDF files.

See L<XML::Invoice::Parser::Base> for details on the shared interface of the returned
classes. Please implement this interface if you want to create your own Parser
classes under the C<XML::Invoice::Parser> name space.

=head1 SUPPORTED FORMATS

Currently, C<XML::Invoice::Parser> supports the following formats. Please note
that PDF handling is out of scope, so for any hybrid format where the XML
data is transmitted as an attachment to a PDF file, the extracted XML payload
will have to be provided to the C<XML::Invoice::Parser>> constructor.

=head2 XRechnung

This a pure XML format based on Oasis Universal Business language 2.1. It is
most commonly used when issuing invoices to public sector entities in Germany
which have started mandating invoices in this format in 2020. It fullfils the
requirements of EN16931.

=head2 ZUGFeRD 1.0

This is a hybrid format consisting of a human readable PDF invoice with an
embedded XML payload in UN/CEFACT CrossIndustryDocument format. While being
machine readable, this XML payload does not fully fulfill the requirements of
EN16931.

=head2 ZugFeRD 2.x

This is a hybrid format consisting of a human readable PDF invoice with an
embedded XML payload in UN/CEFACT CrossIndustryInvoice format. Depending on
the profile used, this XML payload fulfills the requirements of EN16931.

=head1 SYNOPSIS

  # $xml_data contains an XML document as flat scalar
  my $invoice_parser = XML::Invoice::Parser->new($xml_data);

  # %metadata is a hash of document level metadata items
  my %metadata = %{$invoice_parser->metadata};

  # @items is an array of hashes, each representing a line
  # item on the bill
  my @items = @{$invoice_parser->items};

=cut

=head1 METHODS

=head2 new($xml_data)

Parameters:

=over 5

=item C<$xml_data>: XML document to parse as one flat scalar.

=back

=cut

sub new {
  my ($class, $xml_data) = @_;
  my $self = {};

  $self->{message} = '';
  $self->{dom} = eval { XML::LibXML->load_xml(string => $xml_data) };

  if ( ! $self->{dom} ) {
    $self->{message} = t8("Parsing the XML data failed: #1", $xml_data);
    $self->{result} = RES_XML_PARSING_FAILED;
    return $self;
  }

  # Determine parser class to use
  my $type = first {
    $_->check_signature($self->{dom})
  } @document_modules;

  unless ( $type ) {
    $self->{result} = RES_UNKNOWN_ROOT_NODE_TYPE;

    my @supported = map { $_->supported } @document_modules;

    $self->{message} =  t8("Could not parse XML Invoice: unknown XML invoice type\nsupported: #1",
                           join ",\n", @supported
                        );
    return $self;
  }

  bless $self, $type;

  # Implementation sanity check for child classes: make sure they are aware of
  # the keys the hash returned by their metadata() method must contain.
  my @missing_data_keys = grep { !${$self->_data_keys}{$_} } @{ $self->data_keys };
  if ( scalar(@missing_data_keys) > 0 ) {
    die "Incomplete implementation: the following metadata keys appear to be missing from $type: " . join(", ", @missing_data_keys);
  }

  # Implementation sanity check for child classes: make sure they are aware of
  # the keys the hashes returned by their items() method must contain.
  my @missing_item_keys = ();
  foreach my $item_key ( @{$self->item_keys} ) {
    unless ( ${$self->_item_keys}{$item_key}) { push @missing_item_keys, $item_key; }
  }
  if ( scalar(@missing_item_keys) > 0 ) {
    die "Incomplete implementation: the following item keys appear to be missing from $type: " . join(", ", @missing_item_keys);
  }

  $self->parse_xml;

  # Ensure these methods are implemented in the child class
  $self->metadata;
  $self->items;

  $self->{result} = RES_OK;
  return $self;
}

=head1 AUTHOR

Johannes Grassler, C<< <info@computer-grassler.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xmlinvoice at rt.cpan.org>,
or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML::Invoice::Parser>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::Invoice::Parser

You can also look for information at:
    
=over 4
    
=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=XML::Invoice::Parser>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML::Invoice::Parser>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/XML::Invoice::Parser>

=item * Search CPAN

L<https://metacpan.org/release/XML::Invoice::Parser>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Sven Schoeling C<< <s.schoeling@googlemail.com> >> who made various
improvements to this module's invocation.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Johannes Grassler.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1; # End of XML::Invoice::Parser
