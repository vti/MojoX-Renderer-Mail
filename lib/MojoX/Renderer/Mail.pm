package MojoX::Renderer::Mail;

use strict;
use warnings;

use Encode ();
use MIME::Lite;
use MIME::EncWords 'encode_mimeword';

use constant TEST    => $ENV{'TEST' } || 0;
use constant DEBUG   => $ENV{'DEBUG'} || 0;
use constant CHARSET => 'UTF-8';

our $VERSION = '0.4';

sub build {
	my $self = shift;
	my $args = {@_};
	
	return sub {
		my($mojo, $ctx, $output) = @_;
		
		my $mail     = $ctx->stash('mail');
		my $charset  = $ctx->stash('charset' ) || $args->{'charset' } || CHARSET;
		
		my $encoding = $ctx->stash('encoding') || $args->{'encoding'};
		my $encode   = $encoding eq 'base64' ? 'B' : 'Q';
		
		my $mimeword = defined $ctx->stash('mimeword') ? $ctx->stash('mimeword') : !$encoding ? 0 : 1;
		
		# tuning
		
		$mail->{'From'} ||= $args->{'from'};
		
		if ($mail->{'Data'}) {
			$mail->{'Encoding'} ||= $encoding;
			_enc($mail->{'Data'});
		}
		
		if ($mimeword) {
			$_ = encode_mimeword($_, $encode, $charset) for grep { _enc($_); 1 } $mail->{'Subject'};
			
			for ( grep { $_ } @$mail{ qw(From To Cc Bcc) } ) {
				$_ = join ",\n",
					grep {
						_enc($_);
						{
							next unless /(.*) \s+ (\S+ @ .*)/x;
							
							my($name, $email) = ($1, $2);
							$email =~ s/(^<+|>+$)//sg;
							
							$_ = $name =~ /^[\w\s"'.,]+$/
								? "$name <$email>"
								: encode_mimeword($name, $encode, $charset) . " <$email>"
							;
						}
						1;
					}
					split /\s*,\s*/
				;
			}
		}
		
		# year, baby!
		
		my $msg = MIME::Lite->new( %$mail );
		
		$msg->add   ( %$_ ) for @{$ctx->stash('headers') || []}; # XXX: add From|To|Cc|Bcc => ... (mimeword)
		
		$msg->attr  ( %$_ ) for @{$ctx->stash('attr'   ) || []};
		$msg->attr  ('content-type.charset' => $charset) if $charset;
		
		$msg->attach( %$_ ) for
			grep {
				if (!$_->{'Type'} || $_->{'Type'} eq 'TEXT') {
					$_->{'Encoding'} ||= $encoding;
					_enc($_->{'Data'});
				}
				1;
			}
			grep { $_->{'Data'} || $_->{'Path'} }
			@{$ctx->stash('attach') || []}
		;
		
		$msg->replace('X-Mailer' => join ' ', 'Mojolicious',  $Mojolicious::VERSION, __PACKAGE__, $VERSION, '(Perl)');
		
		DEBUG && warn( $msg->as_string );
		
		TEST  || $msg->send( $args->{'how'}, @{$args->{'howargs'}||[]} );
		
		return 1;
	};
}

sub _enc($) {
	Encode::_utf8_off($_[0]) if $_[0] && Encode::is_utf8($_[0]);
	return $_[0];
}

1;

__END__

=encoding UTF-8

=head1 NAME

MojoX::Renderer::Mail - Mail renderer for Mojo and Mojolicious.

Uses MIME::Lite and MIME::EncWords.

All headers such as From, To, Cc, Bcc and Subject are encoded words.

=head1 SYNOPSIS

  #!/usr/bin/perl
  use utf8;

  use Mojolicious::Lite;
  use MojoX::Renderer::Mail;

  app->renderer->add_handler(
    mail => MojoX::Renderer::Mail->build(
      from     => 'sharifulin@gmail.com',
      encoding => 'base64',
      how      => 'sendmail',
      howargs  => [ '/usr/sbin/sendmail -t' ],
    ),
  );

Simple mail example:

  get '/simple' => sub {
    my $self = shift;
    
    $self->render(
      handler => 'mail',
      
      mail => {
        To      => '"Анатолий Шарифулин" sharifulin@gmail.com',
        Cc      => '"Анатолий Шарифулин" <sharifulin@gmail.com>, Anatoly Sharifulin sharifulin@gmail.com',
        Bcc     => 'sharifulin@gmail.com',
        Subject => 'Тест письмо',
        Type    => 'text/html',
        Data    => "<p>Привет!</p>",
      },
    );
    
    $self->render_text('OK');
  };

Attachment mail example:

  get '/attach' => sub {
    my $self = shift;
    
    $self->render(
      handler => 'mail',
        # charset  => '...',
        # mimeword => 0,
        
        mail => {
          To      => 'sharifulin@gmail.com',
          Subject => 'Тест аттач',
          Type    => 'multipart/mixed'
        },
        
        attach => [
          {
            Data => 'Текст письма',
          },
          {
            Type        => 'BINARY',
            Filename    => 'crash.data',
            Disposition => 'attachment',
            Data        => 'binary data binary data binary data binary data binary data',
          },
        ],

        headers => [ { 'X-My-Header' => 'Mojolicious' } ],
    );

    $self->render_text('OK');
  };

Multipart mixed mail example:

  get '/multi' => sub {
    my $self = shift;

    $self->render(
      handler => 'mail',
        mail => {
          To      => 'sharifulin@gmail.com',
          Subject => 'Мульти',
          Type    => 'multipart/mixed'
        },

        attach => [
          {
            Type     => 'TEXT',
            Encoding => '7bit',
            Data     => "Just a quick note to say hi!"
          },
          {
            Type     => 'image/gif',
            Path     => $0
          },
          {
            Type     => 'x-gzip',
            Path     => "gzip < $0 |",
            ReadNow  => 1,
            Filename => "somefile.zip"
          },
       ],
    );
    
    $self->render_text('OK');
  };

Render mail example:

  get '/render' => sub {
    my $self = shift;

    $self->render(
      handler => 'mail',

      mail => {
        To      => 'sharifulin@gmail.com',
        Subject => 'Тест render',
        Type    => 'text/html',
        Data    => $self->render_partial('render', format => 'mail'),
      },
    );

    $self->render(format => 'html');
  } => 'render';

  get '/render2' => sub {
    my $self = shift;

    my $data = $self->render_partial('render2', format => 'mail');
    
    $self->render(
      handler => 'mail',

      mail => {
        To      => 'sharifulin@gmail.com',
        Subject => $self->stash('subject'),
        Type    => 'text/html',
        Data    => $data,
      },
    );

    $self->render(template => 'render', format => 'html');
  } => 'render';
  
  app->start;
  
  __DATA__

  @@ render.html.ep
  <p>Привет render!</p>

  @@ render.mail.ep
  <p>Привет васса render!</p>

  @@ render2.mail.ep
  % stash 'subject' => 'Привет render2';

  <p>Привет васса render2!</p>


=head1 METHODS

=head2 build

This method returns a handler for the Mojo renderer.

Supported parameters:

=over 5

=item * from

Default from address

=item * encoding 

Default encoding of Subject and any Data, value is MIME::Lite content transfer encoding L<http://search.cpan.org/~rjbs/MIME-Lite-3.027/lib/MIME/Lite.pm#Content_transfer_encodings>

=item * charset

Default charset of Subject and any Data, default value is UTF-8

=item * how

HOW parameter of MIME::Lite::send, value are sendmail or smtp

=item * howargs 

HOWARGS parameter of MIME::Lite::send (arrayref)

=back


=head1 RENDER

  $self->render(
    handler => 'mail',
    
      mail   => { ... }, # as MIME::Lite->new( ... )
      attach => [
        { ... }, # as MIME::Lite->attach( .. )
        ...
      },
      headers => [
        { ... }, # as MIME::Lite->add( .. )
        ...
      },
      attr => [
        { ... }, # as MIME::Lite->attr( .. )
        ...
      },
  );


Supported parameters:

=over 4

=item * mail

Hashref, containts parameters as I<new(PARAMHASH)>. See MIME::Lite L<http://search.cpan.org/~rjbs/MIME-Lite-3.027/lib/MIME/Lite.pm#Construction>.

=item * attach 

Arrayref of hashref, hashref containts parameters as I<attach(PARAMHASH)>. See MIME::Lite L<http://search.cpan.org/~rjbs/MIME-Lite-3.027/lib/MIME/Lite.pm#Construction>.

=item * headers

Arrayref of hashref, hashref containts parameters as I<add(TAG, VALUE)>. See MIME::Lite L<http://search.cpan.org/~rjbs/MIME-Lite-3.027/lib/MIME/Lite.pm#Construction>.

=item * attr

Arrayref of hashref, hashref containts parameters as I<attr(ATTR, VALUE)>. See MIME::Lite L<http://search.cpan.org/~rjbs/MIME-Lite-3.027/lib/MIME/Lite.pm#Construction>.

=back


=head1 ENVIROMENT VARIABLES

Module has two env variables:

=over 2

=item * DEBUG

Print mail, default value is 0

=item * TEST

No send mail, default value is 0

=back


=head1 TEST AND RUN

  TEST=1 DEBUG=1 PATH_INFO='/multi' script/test cgi


=head1 SEE ALSO

=over 4

=item * L<MIME::Lite>

=item * L<MIME::EncWords>

=item * L<MojoX::Renderer>

=item * L<Mojolicious>

=back


=head1 AUTHOR

Anatoly Sharifulin <sharifulin@gmail.com>

=head1 THANKS

Alex Kapranoff <kapranoff@gmail.com>


=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-cpanauthors-russian at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.htMail?Queue=MojoX-Renderer-Mail>.  We will be notified, and then you'll
automatically be notified of progress on your bug as we make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc MojoX::Renderer::Mail

You can also look for information at:

=over 5

=item * Github

L<http://github.com/sharifulin/MojoX-Renderer-Mail/tree/master>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.htMail?Dist=MojoX-Renderer-Mail>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MojoX-Renderer-Mail>

=item * CPANTS: CPAN Testing Service

L<http://cpants.perl.org/dist/overview/MojoX-Renderer-Mail>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MojoX-Renderer-Mail>

=item * Search CPAN

L<http://search.cpan.org/dist/MojoX-Renderer-Mail>

=back

=head1 COPYRIGHT & LICENSE

Copyright (C) 2010 by Anatoly Sharifulin.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
