# XML::Stream v1.24 2014-12-22

This module provides you with access to XML Streams.  An XML Stream
is just that.  A stream of XML over a connection between two computers.
For more information about XML Streams, and the group that created them,
please visit:

<http://xmpp.org/protocols/streams/>

Darian Anthony Patrick
dapatrick@cpan.org


## Installation

  perl Makefile.PL

  make

  make install

## Requirements

  Perl 5.8.0            - For unicode support

  Authen::SASL          - For SASL Authentication

  MIME::Base64          - For SASL Authentication

## Recommendations

  IO::Socket::SSL v0.81 - Module to enable TLS for XML::Stream.

  Net::DNS              - Enables access to SRV records.

## Development

### Run tests

  make test

## Reporting Bugs

Please submit bug reports at
<https://github.com/dap/XML-Stream/issues>

## License

LGPL Version 2.1 (See more information in LICENSE)

