Motorola MVME147 with System V/68 R3V7 (November 1991), in MAME
===============================================================

The machine is a Motorola VME board, the MVME147: 68030 processor, 68882
coprocessor, 16 MB of RAM, a WD33C93 SCSI controller and two Z8530 for the
serial lines. Its ROM monitor is 147Bug 2.44 (August 1997).

The system is System V/68 Release R3V7, Motorola's Unix System V Release 3
for the 68030. Version 911111: the kernel is from 11 November 1991, the
date on the installation tape. It was installed on this disk from that
tape, with its own installer, inside the emulator.

The emulator is MAME with a rewritten MVME147 driver, in a miniFORCE VME
chassis (machine "miniforce").


Starting it
-----------

Double click SYSV68.bat.

A window opens with a text terminal: the board's serial console. Everything
below shows up there.

  1. 147Bug runs its self tests and prints its prompt, "147RF-Bug>".
  2. The pack types "bo 0,0" by itself, which boots from SCSI disk 0.
  3. The disk IPL ("VME Disk IPL Version 52.2") loads the kernel.
  4. Sometimes it asks for the date. If it does, answer y (see below).
  5. It checks the disks, starts its services and asks for a user:
     "Console Login:".

It takes about TWO MINUTES from the double click to "Console Login:". That
is the speed of the real machine; it has not hung.


Messages that look like errors and ARE NOT
------------------------------------------

At power on, 147Bug prints:

  Failed Power-up Confidence test
  ...... Exception Processing test failed

  NOT AN ERROR THAT MATTERS. That test checks a bus detail (an access that
  must fail on purpose) the emulator does not reproduce. Nothing the system
  does depends on it.

  *** WARNING *** Unreliable R/W to NVRAM; now using defaults from ROM

  NOT AN ERROR. The board's configuration memory is blank and 147Bug uses
  its factory values, which are the right ones here.

  LANCE  not detected
  Parity not detected

  NOT ERRORS. The network interface and parity memory are not emulated; the
  system does not need them.

When System V/68 starts:

  Is the date Fri Sep 29 12:25:12 EDT 1995 correct? (y or n)

  Sometimes it comes up and sometimes it does not. If it does, answer y.
  The year may look odd (1995 in the tests); it does not matter. If you
  answer n it asks for the new date, in the format it shows.

  Default Timezone may be incorrect.
  You must login as 'setup' to change this.

  NOT AN ERROR. It is the notice of a freshly installed machine.

  This machine has not been used as a customer machine yet. ...
  ... call your service representative.

  NOT AN ERROR, and there is no one to call. It is Motorola's factory
  message for a freshly installed machine: it checks the disks on every
  boot until someone logs in as "setup" (see below). All that would matter
  is "BOOT SYSV68" or "FILE SYSTEM WAS MODIFIED" showing up on their own,
  and they do not.

  netspec "tcpip" not set up.

  NOT AN ERROR. There is no network, configured or emulated.


Logging in
----------

  Console Login: root
  Password:      sysv68

If you log in as "setup", the system walks you through setting up a new
machine. According to its own boot notice, after that it stops checking
the disks on every boot. It is optional.


The keyboard: # erases and @ kills the line
-------------------------------------------

When you log in the system says:

  erase = #  kill = @  intr = DEL  quit = ^|

That is normal for a 1991 Unix: # erases the previous character and @
erases the whole line. Backspace does NOT erase. To make backspace work as
on a system of today, type after logging in:

  stty erase '^H'

where ^H is typed as a caret and an H, inside the quotes.


Shutting down (IMPORTANT)
-------------------------

Shut the system down before closing the window, or the disk is left dirty
and the next boot has to repair it. As root:

  cd /
  /etc/shutdown -y -g0 -i0

It prints "THE SYSTEM IS BEING SHUT DOWN NOW", stops its services and ends
with:

  The system is down.
  NOTICE: System Halt Requested (0)
  NOTICE: System secured for powering down.

Once you see "System secured for powering down" you can close the window.

To restart instead of shutting down: /etc/shutdown -y -g0 -i6


Starting over
-------------

The pack's disk never changes: what you change is kept apart, in the folder
state\diff. RESET.bat deletes those changes (it asks first) and the next
boot starts from the freshly installed system.


What is in the folder
---------------------

  SYSV68.bat           starts the machine
  RESET.bat            throws away the changes made to the disk
  vme.exe              MAME with the MVME147 driver
  roms\mvme147.zip     the board's 147Bug 2.44
  disk\                316 MB SCSI disk with System V/68 installed
  autoboot.lua         types "bo 0,0" when 147Bug prints its prompt
  ini\ui.ini           skips MAME's "not working" warning
  state\nvram\         the board's configuration memory (do not delete it)
  state\               disk changes and MAME settings
  snapshots\           screenshots (F12)
