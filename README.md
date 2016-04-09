# dodgy-old-crap

I wrote the code in this repo many years ago. I really don't recommend looking at it unless
you want examples of how not to write good Perl. This code is full of bad practices and
idioms that now look horribly out of date. More importantly, some of the code is intended
to be run on a web server, but has huge security holes which would allow your server to
be hacked or (in at least one case) used as to send spam.

I probably shouldn't even put the code on Github, but I'm such a packrat that I can't
bear to see anythnig thrown away. I was reminded of the existance of this code earlier
this week and it's taken me a few days to track it down - so I thought that putting it
on Github would make it easier to find in the future.

But I really can't emphasise this enough - **Please don't run any of this code on a
system that is connected to the internet**.

So what do we have in the various directories here?

## mail

A really simple formmail program. Not sure that I ever used it.

## ms

My first suite of CGI program. My consulting company is called Magnum Solutions so
it amused me to name the programs "ms-foo" in the hope that people might assume they
were from Microsoft. That didn't happen. The programs in the suite are:

* **ms-env** - get information about the environment that your CGI programs are running in.
* **ms-guest** - a guest book (remember guest books?)
* **ms-mail** - my second attempt at a formmail program. Not much better than the first.
* **ms-webmail** - a webmail program. Presumably written to allow me to access my personal
email from behind the firewall of whatever bank I was working for at the time.

This programs are all dreadful. If you're looking for stuff like this, then you would be 
much better advised to look at the [nms](http://nms-cgi.sf.net) project.

## slavorg

A very simple bot that used to sit on the #london.pm IRC channel and give ops to the
people that it trusted. An artifact from a far most trusting internet age.

## spam

Not sure about this one. I think I was trying to analyse the spam I was getting.

## sqpl

This was ambitious. It's a full replacement for `isql` the command line program that
is used to talk to Sybase databases. I can't remember what it was about `isql` that I
didn't like or whether this replacement was successful in fixing the problems.

Interesting to see that there are two versions. `sqpl` uses DBI, the standard Perl
database interface. But there's also `sqpl.sybperl` which uses the older, proprietary,
Sybase::CTlib method.

## sybserv

Another program that was useful back when I was writing Sybase programs for banks. This
parses the file which Sybase uses to hold information about the various servers you
can connect to.

This maybe the only program I've ever written which uses Perl's formats.

## toc

This one might still work. It parses an HTML document, looking for heading tags and
then creates a table of contents which it inserts into the document.

## webged

This was the program that started my trying to find these programs a couple of days ago.
It displays genealogical data by generating a series of web pages from a
[GEDCOM](https://en.wikipedia.org/wiki/GEDCOM) file.
