#########################################################################
#
# Copyright 2017 by Sean Conner.  All Rights Reserved.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 3 of the License, or (at your
# option) any later version.
#
# This library is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
# License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this library; if not, see <http://www.gnu.org/licenses/>.
#
# Comments, questions and criticisms can be sent to: sean@conman.org
#
########################################################################

CC       = c99
CFLAGS   = -g
LDFLAGS  = -g
LDLIBS   =
ASM      = nasm -f elf32
ASMFLAGS = -g
AR       = ar rscu

%.a :
	$(AR) $@ $?

%.o : %.asm
	$(ASM) $(ASMFLAGS) -l $(*F).list -o $@ $<

.PHONY : all clean

all  : test iter
clean:
	$(RM) test iter *.o *~ *.a core.* *.list
	
test    : test.o libco.a
iter    : iter.o libco.a
libco.a : coroutine_create.o coroutine_free.o	\
		coroutine_yield-x86-32.o 	\
		coroutine_yield-x86-64.o

coroutine_yield-x86-64.o : ASM = nasm -f elf64
coroutine_create.o       : coroutine.h
coroutine_free.o         : coroutine.h
test.o                   : coroutine.h
iter.o                   : coroutine.h
