my ($PROJECT,$PROJECTPROPER,@AUTHORIDS) = @ARGV;
foreach my $AUTHORID (@AUTHORIDS) {
	$PROJECTPROPER ||= $PROJECT;
	$PPROJECT = $PROJECTPROPER;
	my $AUTHOR = ` cat author.table | fgrep \\"$AUTHORID\\" | awk -F\\" '{print \$4}' `;
	my ($NAME,$EMAIL) = ($AUTHOR =~ /^([^<]*)\s*<([^>]+)>/);
	$NAME =~ s/^\s+//;
	$NAME =~ s/\s+$//;
	my $HASH = `wwwpass2.pl ${PROJECT}`;
	chomp($HASH);
	warn "$NAME $EMAIL $HASH";
	for my $file (<survey-${AUTHORID}-*pdf>) {
		warn $file;
		my ($SURVEY) = ($file =~ /(survey-\d+-\d+,\d+,\d+)\./);
		print <<EOF;


To: ${NAME} <${EMAIL}>

Subject: About ${PPROJECT} , can we talk about your contributions to ${PPROJECT}?  [dev-topic-study]

Hello ${NAME}!

I'm interested in learning more about your contributions to
${PPROJECT}. I am studying topics of software development and I have
constructed a personalized survey about your contributions (commits)
relevant to topics extracted from the issues tracker of ${PPROJECT}.

The survey is about if automated topics could be useful to project
awareness. It should only take about ~10 minutes to complete.
Participation would be appreciated but feel free not to take part.

We extract topics from your github issue tracker and correlate them
with your github commits. Then we plot them over time!

For instance here's a view of the issue tracker topics of ${PPROJECT}:

http://softwareprocess.es/a/${HASH}/index.html

Your personalized survey is here (extracted from your own commits):

http://softwareprocess.es/a/${HASH}/${SURVEY}.pdf
http://softwareprocess.es/a/${HASH}/${SURVEY}.html
http://softwareprocess.es/a/${HASH}/${SURVEY}.odt

If you could write down your answers in an email or edit the odt or html
or pdf file in place and send it back to me that'd be excellent. Attach
the consent form as well too (sorry that it is so large).

Then please fill out this consent form if you participate in the survey:

http://softwareprocess.es/a/${HASH}/consent.odt
http://softwareprocess.es/a/${HASH}/consent.pdf
http://softwareprocess.es/a/${HASH}/consent.html

Once that is signed/agreed to (digital consent is OK) please send
it and the survey back to me. The consent form also asks about an
optional interview if you're interested.

If you'd rather setup a voice chat to make administration of this
survey easier then just email me back or find me on freenode as
avi_. Feel free to email me back with any questions, if you find
this intrusive I apologize, and thank you for your time.

Sincerely,

Abram Hindle
Assistant Professor
Department of Computing Science
University of Alberta, Edmonton, AB, Canada
http://softwareprocess.es/
googletalk: abram.hindle\@gmail.com
FreeNode: avi_
Github: http://github.com/abramhindle
EOF

	}
}
