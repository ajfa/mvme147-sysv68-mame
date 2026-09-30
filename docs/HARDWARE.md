# What was worked out

Everything here was found by running 147Bug 2.44 and System V/68 R3V7 on the
emulated board and following them where they stopped. Addresses are the
MVME147's; kernel addresses are those of the R3V7 kernel (version 911111).

## The MVME147 driver

MAME had a skeleton for the board. It is rewritten (`patches/05-mvme147.patch`):

- **PCC.** Tick timers 1 and 2 count up at 160 kHz and reload from their
  preload register on overflow. Each interrupt source has its control
  register (level in bits 0-2, enable in bit 3, status in bit 7, cleared by
  writing 1). The vector is the vector base register (0x2d) ORed with the
  source number. Interrupts are acknowledged through the CPU space map.
- **DMA.** Direct and table walk transfers between memory and the WD33C93,
  byte by byte, in either direction. The firmware waits for DONE, which is
  set when the WD33C93 interrupts at the end of a transfer.
- **Bus errors.** Every address the board does not decode raises a bus
  error: 147Bug sizes memory that way, and saw 64 MB without it. The second
  ROM bank answers without a bus error, or 147Bug double faults.
- **VMEchip.** Its registers are on odd bytes; bit 0 of 0xfffe2001 says the
  board is the system controller.
- **Printer port status.** Bit 0 of 0xfffe2800 is the +12 V fuse; 147Bug
  wants it set.
- SCSI: the WD33C93 on MAME's nscsi bus, a hard disk on ID 0 and a tape on
  ID 4.
- The FPU is a 68882.

Not emulated: the LANCE Ethernet interface, parity memory, the printer, and
the bus error an FC3 access should raise. That last one is why 147Bug prints
"Exception Processing test failed"; nothing else depends on it.

## 68882

147Bug's self test found five problems in MAME's 6888x emulation
(`patches/01-m68k-fpu-68882.patch`):

- FREM and FMOD did a single partial step, like the x87 instruction MAME's
  helper is modelled on. The 6888x finishes the reduction in one
  instruction.
- FSAVE only wrote IDLE frames. The 6888x writes a BUSY frame when an
  arithmetic instruction is still running, 0xb4 bytes on a 68881 and 0xd4 on
  a 68882, and FRESTORE of that frame finishes the instruction.
- Enabled exceptions were never taken. On a 6888x they are taken before the
  next FPU instruction, and they are pending in an FSAVE frame.
- FMOVE to a register did not update the exception byte, and did not quiet
  a signalling NaN.
- The BIU word of the frame had its low 16 bits clear. They read as ones,
  and 147Bug keeps a flag there.

## WD33C93

(`patches/02-wd33c93.patch`)

- In manual mode (Transfer Info), each message byte ends with ACK still
  asserted and interrupt 0x20, so the host can look at it before Negate ACK.
- A byte read by Transfer Info waits in the data register with DBR set, and
  the interrupt comes when the host reads it. MAME gave both at once and
  147Bug returned an error.
- After Negate ACK the chip is idle, and when the target asserts REQ in a
  new phase it raises "service required" (0x88 plus the phase). MAME stopped
  with a fatal error.
- Transfer Info had no path for a target going from MESSAGE OUT to MESSAGE
  IN or STATUS, or from MESSAGE IN to any other phase.
- The transfer count register only changed when it reached zero. A target
  that ends a transfer early (a tape at a filemark, a short MODE SENSE)
  left the full count there, and the host read it as nothing transferred.

## SCSI devices

(`patches/03-nscsi-tape-disk.patch`)

- The target could not end the data in phase early. A tape read that hits a
  filemark sent a block's worth of zeros for every block requested: 16 MB of
  DMA past the end of memory.
- A message after IDENTIFY, such as the synchronous transfer request the
  Motorola driver sends, was ignored. A target that does not support it
  answers MESSAGE REJECT. Without it the driver's script and the bus phases
  disagree and the disk formatter gives up ("script mismatch").
- The tape answered MODE SENSE of any page other than 0 with CHECK
  CONDITION. 147Bug asks every device for page 3 and waits for the data; a
  SCSI-1 drive returns the header and block descriptor.
- SPACE kept a signed count in an unsigned variable, so spacing backwards
  never happened.
- The disk did not have page 0x38, the Seagate cache page the formatter
  asks for, and answered a request for changeable values with the current
  ones. The formatter tries to fit its parameters through that mask, and
  with interleave 0 as the mask it could not set interleave 1 ("Command
  Byte 10, Status 0B").

## Z8530

(`patches/04-z80scc-rr2.patch`) RR2 read from channel B must hold the
highest priority interrupt still pending in RR3, or 011 when none is. MAME
looked at the requests not yet acknowledged, so after the acknowledge it
reported "channel B external status" and the System V/68 console went
silent as soon as it used interrupts.

## MAME's startup warning

(`patches/06-ui-skip-warnings.patch`) `skip_warnings` in `ui.ini` is only
honoured when the same warnings were shown in the last week, which is never
true on a fresh setup. With this line it always is. The miniFORCE chassis is
marked as not working, because its default CPU board still does not work.

## System V/68

- The kernel finds its boot device in 147Bug's board ID packet, which it
  keeps a pointer to: the controller LUN is at offset 0x14, the device LUN
  at 0x16 and the controller type at 0x18. Type 13 is the MVME147's own SCSI
  tape. On the MVME147 the controller LUN is the SCSI ID, so the tape on ID 4
  boots with `bo 4,0` and the disk on ID 0 with `bo 0,0`.
- The Motorola SCSI drivers only attach drives they know by name. The
  kernel has a table of INQUIRY product strings (VIPER, EXB-8200, 96X2 TAPE
  and a few others for tapes; ST296N, 94171- and others for disks). An
  unknown tape is never attached and opening it fails with ENXIO before any
  SCSI command. The tape answers as an Archive Viper 150.
- A blank MAME NVRAM is all 0xff, and 147Bug's `bo 0,0` then loads a file
  whose name is that garbage. The harness and the pack start from a zeroed
  NVRAM.
- The installer needs the disk formatted by its own formatter; answering
  no to "Format the root file system's disk drive" ends in "could not be
  accessed".
- `login` times out after 60 emulated seconds and throws away what was
  typed before it turned echo off. Anything that types a password has to run
  at real speed and wait for the prompt.
