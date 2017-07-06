#!/bin/sh
#
# Copyright (c) 2017 Anton Lindqvist <anton@openbsd.org>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

set -e

testseq() {
	stdin=$1
	exp=$(echo "$2")
	act=$(echo -n "$stdin" | ./edit csh)
	[ "$exp" = "$act" ] && return 0

	echo input:
	echo ">>>${stdin}<<<"
	echo -n "$stdin" | hexdump -Cv
	echo expected:
	echo ">>>${exp}<<<"
	echo -n "$exp" | hexdump -Cv
	echo actual:
	echo ">>>${act}<<<"
	echo -n "$act" | hexdump -Cv

	return 1
}

# Create a fake HOME with a minimal .cshrc and a few files used for completion.
tmp=$(mktemp -d)
trap 'rm -r $tmp' 0
touch $tmp/ambiguous.{1,2} $tmp/complete $tmp/ignore.{c,o} $tmp/only.o
cat >$tmp/.cshrc <<!
set filec
set fignore = (.o)
set prompt = " % "
cd ~
!

HOME=$tmp
MALLOC_OPTIONS=S
export HOME MALLOC_OPTIONS

# NL: Execute command.
testseq "echo a\nb" " % echo a\r\na\r\n % b"
testseq "echo \0001\nb" " % echo ^A\r\n\0001\r\n % b"

# VEOF: List all completions or exit.
testseq "\0004" " % exit\r"
testseq "a\0004" " % a^D\r\nambiguous.1  ambiguous.2  \r\r\n % a"
testseq "ignore\0004" " % ignore^D\r\nignore.c  ignore.o  \r\r\n % ignore"
testseq "set ignoreeof\n\0004" \
	" % set ignoreeof\r\n % ^D\r\nUse \"exit\" to leave csh.\r\n % "
testseq "set ignoreeof\na\0004" \
	" % set ignoreeof\r\n % a^D\r\nambiguous.1  ambiguous.2  \r\r\n % a"

# VEOL: File name completion.
testseq "\0033" " % \0007"
testseq "c\0033" " % complete"
testseq "a\0033" " % a\0007mbiguous."
testseq "~${USER}\0033" " % ~${USER}"
testseq "ignore\0033" " % ignore.c"
testseq "only\0033" " % only.o"

# VERASE: Delete character.
testseq "\0177" " % "
testseq "ab\0177\0177\0177" " % ab\b \b\b \b"
testseq "a\0002\0177" " % a^B\b\b  \b\b"
testseq "\0001\0002\0177" " % ^A^B\b\b  \b\b"
testseq "\t\0177" " %         \b\b\b\b\b\b\b\b        \b\b\b\b\b\b\b\b"

# VINTR: Abort line.
testseq "\0003" " % ^C\r\n % "
testseq "ab\0003" " % ab^C\r\n % "
testseq "foreach i ()\n\0003a" " % foreach i ()\r\n? ^C\r\r\n % a"

# VKILL: Kill line.
testseq "\0025" " % "
testseq "ab\0025" " % ab\b\b  \b\b"

# VLNEXT: Insert literal.
testseq "\0026\0007" " % ^G"
testseq "\0026\0033" " % ^["
testseq "echo \0026\na\nb" " % echo ^Ma\r\n\ra\r\n % b"

# VREPRINT: Reprint line.
testseq "ab\0022" " % ab^R\r\nab"

# XXX VSTATUS: Send TIOCSTAT.

# VWERASE: Delete word.
testseq "\0027" " % "
testseq "ab\0027" " % ab\b\b  \b\b"
testseq "ab cd\0027\0027" " % ab cd\b\b  \b\b\b\b\b   \b\b\b"

# VWERASE: Delete word using altwerase.
testseq "stty altwerase\n\0027" " % stty altwerase\r\n % "
testseq "stty altwerase\nab\0027" " % stty altwerase\r\n % ab\b\b  \b\b"
testseq "stty altwerase\nab/cd\0027\0027" \
	" % stty altwerase\r\n % ab/cd\b\b  \b\b\b\b\b   \b\b\b"
