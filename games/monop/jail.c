/*	$OpenBSD: jail.c,v 1.2 1998/09/20 23:36:51 pjanzen Exp $	*/
/*	$NetBSD: jail.c,v 1.3 1995/03/23 08:34:44 cgd Exp $	*/

/*
 * Copyright (c) 1980, 1993
 *	The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by the University of
 *	California, Berkeley and its contributors.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#ifndef lint
#if 0
static char sccsid[] = "@(#)jail.c	8.1 (Berkeley) 5/31/93";
#else
static char rcsid[] = "$OpenBSD: jail.c,v 1.2 1998/09/20 23:36:51 pjanzen Exp $";
#endif
#endif /* not lint */

#include	"monop.ext"

/*
 *	This routine uses a get-out-of-jail-free card to get the
 * player out of jail.
 */
void
card()
{
	if (cur_p->loc != JAIL) {
		printf("But you're not IN Jail\n");
		return;
	}
	if (cur_p->num_gojf == 0) {
		printf("But you don't HAVE a get out of jail free card\n");
		return;
	}
	ret_card(cur_p);
	cur_p->loc = 10;			/* just visiting	*/
	cur_p->in_jail = 0;
}
/*
 *	This routine returns the players get-out-of-jail-free card
 * to a deck.
 */
void
ret_card(plr)
	PLAY	*plr;
{
	plr->num_gojf--;
	if (CC_D.gojf_used)
		CC_D.gojf_used = FALSE;
	else
		CH_D.gojf_used = FALSE;
}
/*
 *	This routine deals with paying your way out of jail.
 */
void
pay()
{
	if (cur_p->loc != JAIL) {
		printf("But you're not IN Jail\n");
		return;
	}
	cur_p->loc = 10;
	cur_p->money -= 50;
	cur_p->in_jail = 0;
	printf("That cost you $50\n");
}
/*
 *	This routine deals with a move in jail
 */
int
move_jail(r1, r2)
	int	r1, r2;
{
	if (r1 != r2) {
		printf("Sorry, that doesn't get you out\n");
		if (++(cur_p->in_jail) == 3) {
			printf("It's your third turn and you didn't roll doubles.  You have to pay $50\n");
			cur_p->money -= 50;
moveit:
			cur_p->loc = 10;
			cur_p->in_jail = 0;
			move(r1+r2);
			r1 = r2 - 1;	/* kludge: stop new roll w/doub	*/
			return TRUE;
		}
		return FALSE;
	}
	else {
		printf("Double roll gets you out.\n");
		goto moveit;
	}
}

void
printturn()
{
	if (cur_p->loc != JAIL)
		return;
	printf("(This is your ");
	switch (cur_p->in_jail) {
	  case 0:
		printf("1st");
		break;
	  case 1:
		printf("2nd");
		break;
	  case 2:
		printf("3rd (and final)");
		break;
	}
	printf(" turn in JAIL)\n");
}
