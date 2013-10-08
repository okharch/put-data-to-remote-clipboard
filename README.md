put-data-to-remote-clipboard
============================

Two counterparts that work together to send information from one host to clipboard of (other) host.

Usage:

Run clips receiver at remote host, for example your windows/linux desktop

 perl putclip.pl

If you need to put content of a file or a pipe to remote

 perl ~/bin/sendclip.pl --host=192.168.1.19 test.txt

 somejob | perl ~/bin/sendclip.pl --host=192.168.1.19

etc.

ENJOY!
