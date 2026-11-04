# Tinker Board R2.0 (RK3288) – Yocto + Xen: Project Documentation

All project documentation in one place.

- **[Part 1 – Project guide (beginner's version)](#part-1--project-guide-beginners-version)**:
  the whole story in plain words (what we wanted, what went wrong, why, and how we fixed it).
  Start here.
- **[Part 2 – Technical reference](#part-2--technical-reference)**: exact details (addresses,
  patches, code, configuration, checksums, every error and its fix).

Quick start (build and flash): [Part 1, Chapter 12](#chapter-12--how-to-build-flash-and-use-it) or
[Part 2, section 10](#10-build-and-flash-procedure).

---

# Part 1 – Project guide (beginner's version)

*My Tinker Board Project: Three Operating Systems on One Small Computer*

*A beginner's guide to how this project was built, step by step, from the first boot to the end.*

---

## Before you start

This guide tells the whole story of the project, from the very first boot problem to the finished
system. You don't need to be an expert to read it. Every new word is explained the first time it
appears, and there's a word list at the end ([Chapter 15](#chapter-15--word-list)).

If you want the exact technical details (register addresses, full patch listings, every hash), they
are in [Part 2 – Technical reference](#part-2--technical-reference) further down this document. This part is the friendly version.

**How to read it:**
- Chapters 1–3 explain the ideas and the equipment. Read these first.
- Chapters 4–10 tell the story in order. Each step answers four questions:
  *What did we want? What went wrong? Why? How did we fix it?*
- Chapters 11–14 are for using the finished system and getting out of trouble.

---

## Contents

- [Our journey at a glance](#our-journey-at-a-glance) (the whole project as one tree)

1. [The big idea](#chapter-1--the-big-idea)
2. [The equipment](#chapter-2--the-equipment)
3. [The building blocks, explained simply](#chapter-3--the-building-blocks-explained-simply)
4. [Setting up the build PC](#chapter-4--setting-up-the-build-pc)
5. [Part 1 – Getting Xen to start](#chapter-5--part-1--getting-xen-to-start)
6. [Part 2 – Making it a real system](#chapter-6--part-2--making-it-a-real-system)
7. [Part 3 – Adding Android](#chapter-7--part-3--adding-android)
8. [Part 4 – Polishing it](#chapter-8--part-4--polishing-it)
9. [Part 5 – The car project](#chapter-9--part-5--the-car-project)
10. [Part 6 – Four domains, a screen for each, Android 10](#chapter-10--part-6--four-domains-a-screen-for-each-android-10)
    - 10a. [Part 7 – Three guests: the HDMI fix and FreeRTOS's own screen](#chapter-10a--part-7--three-guests-the-hdmi-fix-and-freertoss-own-screen)
11. [How the finished system works](#chapter-11--how-the-finished-system-works)
12. [How to build, flash and use it](#chapter-12--how-to-build-flash-and-use-it)
13. [Every problem we hit, in plain words](#chapter-13--every-problem-we-hit-in-plain-words)
14. [What doesn't work yet, and how to recover](#chapter-14--what-doesnt-work-yet-and-how-to-recover)
15. [Word list](#chapter-15--word-list)

---

## Our journey at a glance

The whole project as one tree, in the order we did it. Each branch is one step from Chapters 5–10:
first what went wrong (✗), then what fixed it (→). Steps without a problem just say what we built.

```
Tinker Board RK3288 project
│
├── Start: build a Yocto image on the PC (Chapter 4)
│
├── Part 1 – Getting Xen to start (Chapter 5)
│   ├── Step 1   ✗ Board "froze" after mmcblk0: p1 … p9
│   │            → The card held an old project; flash our own image
│   ├── Step 2   ✗ Typing did nothing
│   │            → Serial wires to pins 32 / 33 / 34 (not 8 / 10)
│   ├── Step 3   ✗ "Xen must be entered in NS Hyp mode"
│   │            → U-Boot patch 0001: switch to non-secure HYP mode
│   ├── Step 4   ✗ Silence after "Starting kernel"
│   │            → Same U-Boot patch: clean HYP settings register
│   ├── Step 5   ✗ "Missing processor info: 410fc0d1"
│   │            → Xen patch 0001: add the Cortex-A12/A17
│   ├── Step 6   ✗ dom0 Linux crashed twice (L2CTLR, DMA controller)
│   │            → Xen patch 0002 + non-secure DMA address in the start script
│   ├── Step 7   ✗ The 2-second hang (Xen's clock went backwards)
│   │            → Linux patch 0001: don't reset timer7
│   └── Result   ✓ Xen + dom0 boot, login works
│
├── Part 2 – Making it a real system (Chapter 6)
│   ├── Step 8   First test guest with xl create
│   ├── Step 9   Network bridge xenbr0 (192.168.100.x)
│   ├── Step 10  FreeRTOS as a guest (rtos1), 1 ms tick
│   ├── Step 11  ✗ FreeRTOS up to 19 ms late
│   │            → RTDS real-time scheduler: 200 µs in every 1 ms
│   ├── Step 12  ✗ reboot hung
│   │            → Xen patch 0003: RK3288 reset
│   ├── Step 13  Xen starts by itself at power-on (/boot.scr)
│   └── Step 14  ✗ Only 1 CPU core
│                → U-Boot patch 0002: PSCI → 4 cores
│
├── Part 3 – Adding Android (Chapter 7)
│   ├── Step 15  Android 7 + its own 4.14 kernel (32-bit binder)
│   ├── Step 16  Android adapted to Xen (disks, init.xen.rc, network)
│   ├── Step 17  ✗ system_server kept crashing
│   │            → 3 fixes: /dev/input folder, alarm (timerfd) patch, USB hub kept awake
│   └── Step 18  ✗ Xen crash with RTDS on all 4 cores
│                → FreeRTOS alone on core 3 (cpupool rt); real fix in Step 28
│
├── Part 4 – Polishing it (Chapter 8)
│   ├── Step 19  Quieter FreeRTOS, release Xen, auto-start, watchdog, NAT …
│   ├── Step 20  ✓ Repeated power-cycle test passed
│   └── Step 21  Screen + touch for Android tried → froze → switched off (headless)
│
├── Part 5 – The car project (Chapter 9)
│   ├── Step 22  Pretend car vehicle-sim on vcan0
│   ├── Step 23  can2rtos: CAN → FreeRTOS (receive only)
│   ├── Step 24  FreeRTOS checks speed, rpm and signal loss
│   ├── Step 25  Dashboard on HDMI (cluster-hdmi)
│   ├── Step 26  ✗ Messages arrived in bursts (105 ms gaps)
│   │            → FreeRTOS signals xenconsoled less often → 20–35 ms
│   ├── Step 27  ignition-watch (switched off until ACC is wired)
│   └── Step 28  ✗ Xen crash in the RTDS scheduler
│                → Xen patches 0004 + 0005 (official fixes), 3000-round test ✓
│
└── Part 6 – Four domains, a screen for each, Android 10 (Chapter 10) – tested on the board, except screens + Android 10
    ├── Step 29  ✗ "Android 17" can't run on a 32-bit 2 GB chip
    │            → newest possible: 7.1.1 ready-made, 9/10 from source → chose 10 (LineageOS 17.1)
    ├── Step 30  Smaller dom0: 384 MB, ffmpeg moved out (320 MB in Step 37)
    ├── Step 31  FreeRTOS gets all of core 3 (1000 µs in every 1000 µs)
    ├── Step 32  New 4th domain media1: Yocto video + picture player
    ├── Step 33  display-map: one screen per OS (HDMI + USB displays, udl)
    ├── Step 34  SSH (dropbear) + tmux consoles for every OS
    ├── Step 35  Android 10 (LineageOS 17.1): PC set up, source downloaded, build next
    │            ✗ 3 WebView packages failed → git-lfs;  ✗ swap lost by a "!" → re-run
    ├── Step 36  Safety check: heat, power, SD card, memory
    ├── Step 37  Every OS smaller: card 3.54 → 1.57 GB, memory 1168 → 1028 MB
    │            (QEMU firmware 220 MB out, Android system 1.8 GB → 613 MB, rtos1 4 MB)
    └── Step 38  ✓ Tested on the board: all 4 domains, rtos1 1000/1000 µs, Android + media1 work
│
└── Part 7 – Three guests: the HDMI fix and FreeRTOS's own screen (Chapter 10a) – 2026-11-04, tested on the board
    ├── Step 41  Back to three OSes: Android removed; dom0 + rtos1 + media1
    ├── Step 42  ✗ HDMI showed "This VM has no graphic display device" during playback
    │            → guest-vnc -1: the viewer waits for media1's real screen
    ├── Step 43  ✗ FreeRTOS's SPI screen (ILI9341) stayed blank
    │            → SPI clock 24.75 → 8.25 MHz, chip-select toggled per command
    ├── Step 44  ✓ Wiring corrected, rtos1 restarted: the dashboard shows on the TFT
    ├── Step 45  ✓ Full restart: both guests start and log in by themselves; image rebuilt
    └── Step 46  ✗ No video after a power cut (media1 init misreads at cold start)
                 → xen-guests checks media1 and restarts it automatically

Finished (Part 5): Xen → dom0 (Yocto) + FreeRTOS (real-time) + Android, on 4 cores
Part 6:            + media1 (Yocto media), a screen per OS, Android 10
Now (Part 7):      Xen → dom0 + FreeRTOS (own TFT screen) + media1 (HDMI); Android removed
```

---

## Chapter 1 – The big idea

### What we built

We took one small, cheap computer board, the **ASUS Tinker Board R2.0**, and made it run
**three operating systems at the same time**:

1. **Linux** (made with Yocto). This is the "boss". It controls everything else.
2. **Android 7**. The same system phones use. Here it runs without a screen.
3. **FreeRTOS**. A tiny "real-time" system that must react on time, every time.

They all run together, on the same board, and they can't disturb each other.

### Why would anyone do that?

Think about a modern car. It has a computer for the music and maps, a computer for the
dashboard, and computers for safety (like the brakes). Car makers now want to put all of those on
**one chip** to save money and space. But the safety part must never be slowed down or crashed by
the music app.

The trick is a program called a **hypervisor**. It sits underneath all the operating systems and
gives each one its own share of the computer, like walls between flats in a building. We used the
hypervisor called **Xen**.

```
     Linux (boss)        Android (apps)      FreeRTOS (safety, on time)
   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
   │              │    │              │    │              │
   └──────────────┘    └──────────────┘    └──────────────┘
   ┌────────────────────────────────────────────────────────┐
   │           Xen hypervisor (the walls between them)      │
   └────────────────────────────────────────────────────────┘
   ┌────────────────────────────────────────────────────────┐
   │      Tinker Board: 4 CPU cores, 2 GB memory            │
   └────────────────────────────────────────────────────────┘
```

### What you get at the end

You put the SD card in the board and switch it on. Without pressing anything:

- Xen starts, then Linux, then Android and FreeRTOS start by themselves.
- FreeRTOS runs a task exactly every 10 milliseconds. We measured it: it's never more than
  0.04 ms early or late, even while Android is busy.
- A pretend car sends its speed and engine speed (rpm) 100 times a second. FreeRTOS checks every
  message and warns about speeding, about the engine revving too high, and about the signal going
  missing.
- If you plug in an HDMI monitor, a car dashboard shows the speed, rpm and warning lights.

The project took four days, 2026-10-22 to 2026-10-25.

---

## Chapter 2 – The equipment

### What you need

- **ASUS Tinker Board R2.0.** It has a Rockchip **RK3288** chip with 4 CPU cores and 2 GB of memory.
- **A micro-SD card**, 32 GB. The whole system lives on this card.
- **A USB-to-serial adapter** (3.3 V). This lets the PC read the board's text messages and type
  into it, even before anything has started. We call this the **console** or **UART**.
- **A good power supply**: 5 V, 3 A. A weak one causes strange freezes (we saw two).
- **A Linux PC.** We used Ubuntu. It builds the software and writes the SD card.
- Optional: an HDMI monitor, an Ethernet cable, a USB CAN adapter (for reading a real car).

### Connecting the serial adapter (important!)

This was the first thing that went wrong, so take care here. The board has a row of 40 pins. The
console is on pins **32, 33 and 34**, not on pins 8 and 10 as many websites suggest for other boards.

```
   Board pin 32 (sends)    ───────►  adapter RX (receives)
   Board pin 33 (receives) ◄───────  adapter TX (sends)
   Board pin 34 (ground)   ────────  adapter GND
```

Notice that "send" goes to "receive" and the other way round.

On the PC, open the console with:

```
picocom -b 115200 /dev/ttyUSB0
```

`115200` is the speed. Press `Ctrl-a` then `Ctrl-x` to quit picocom.

> **Remember:** when the board starts, it shows "Hit any key to stop autoboot" for a moment. If you
> press a key then, it stops and waits. So after switching on, **don't touch the keyboard** until
> you see `login:`.

---

## Chapter 3 – The building blocks, explained simply

Here are all the pieces, from the bottom up, the order in which they start.

### The boot ROM and U-Boot (the "starter")

When you switch on, a tiny program built into the chip (the **boot ROM**) looks at the SD card and
loads **U-Boot**. U-Boot is a **bootloader**: its only job is to prepare the hardware and start the
next program. Think of it as the starter motor of a car.

### Xen (the hypervisor)

Xen is started by U-Boot. It takes over the CPU cores and memory and shares them out.

One thing is important to know. An ARM processor has different "levels of power", called **modes**.
Normal programs run at the lowest level. Operating systems run one level higher. A hypervisor needs
an even higher level, called **HYP mode**. U-Boot has to hand the CPU over *in HYP mode*, or Xen
refuses to start. This turned out to be our biggest problem (Chapter 5).

### Domains (the virtual machines)

Xen calls each operating system it runs a **domain**.

- **Domain-0 ("dom0")** is the boss domain. It's Linux, and it can create, stop and watch the
  others. It is the only one that touches the real hardware (SD card, network, USB).
- The other domains are **guests**. Ours are `android1` (Android) and `rtos1` (FreeRTOS).

### Yocto (the "factory" that builds Linux)

You don't download Linux for this board as a ready file. You **build** it with a tool called
**Yocto**. Yocto reads "recipes" (small text files) that say where to download each program, how to
compile it and where to put it. At the end it produces one file you can write to the SD card: the
**image** (`.wic` file).

Recipes are grouped into **layers**. We didn't change anyone else's layers. All our own work is in
one layer of our own called **`meta-tinker-xen`**. That keeps everything tidy: if you delete our
layer, you're back to the original.

Words you'll see:
- **recipe** (`.bb` file): how to build one program.
- **bbappend** (`.bbappend` file): "take that other recipe, and also do this". We use it to add our
  fixes to U-Boot, Xen and Linux without editing their files.
- **patch** (`.patch` file): a small list of changes to source code ("in this file, replace these
  lines with those lines").
- **bitbake**: the command that runs the factory, e.g. `bitbake tinker-xen-test-image`.

### Real-time and FreeRTOS

"Real-time" doesn't mean "fast". It means **on time, every time**. An airbag must fire within a few
milliseconds; being fast "on average" isn't good enough. **FreeRTOS** is a very small operating
system designed for this. Ours runs a task every 10 ms and measures how accurate it is.

### Schedulers (who gets the CPU when)

When several programs want the same CPU, a **scheduler** decides who goes next. Xen has several:

- **credit2**: fair sharing. Good for Linux and Android.
- **RTDS**: real-time. You say "this guest gets 200 microseconds of CPU in every 1 millisecond,
  guaranteed", and Xen keeps that promise.

We gave FreeRTOS its **own CPU core** (core number 3) with RTDS, and the other three cores to Linux
and Android with credit2. A group of cores with its own scheduler is called a **cpupool**.

### CAN bus

Cars send messages between their computers on a two-wire network called **CAN**. Each message has
a number (its ID) and up to 8 bytes of data. Linux can use CAN like a network card. It even has a
*pretend* one, called **vcan**, that we used for testing.

---

## Chapter 4 – Setting up the build PC

These steps happen on the PC, not on the board.

> **The quick way:** clone this project and run `./sync.sh`. It does Steps 1–3 below for you: it
> downloads every layer at the exact version we tested (the versions are written inside `sync.sh`)
> and creates `build/conf` with the right settings. The steps below explain what it does.

**Step 1 – Download Yocto and the layers it needs.** All on the "kirkstone" version:

```
mkdir ~/xen-hypervisor && cd ~/xen-hypervisor
git clone -b kirkstone git://git.yoctoproject.org/poky
git clone -b kirkstone https://github.com/openembedded/meta-openembedded
git clone -b kirkstone git://git.yoctoproject.org/meta-virtualization
git clone -b kirkstone git://git.yoctoproject.org/meta-arm
git clone -b kirkstone git://git.yoctoproject.org/meta-rockchip
```

What each one is:
- `poky`: Yocto itself.
- `meta-openembedded`: lots of extra programs.
- `meta-virtualization`: Xen.
- `meta-arm`: the ARM compiler.
- `meta-rockchip`: support for the Tinker Board's chip.

**Step 2 – Make a build folder and tell Yocto about the layers:**

```
source poky/oe-init-build-env build
bitbake-layers add-layer ../meta-openembedded/meta-oe
bitbake-layers add-layer ../meta-arm/meta-arm-toolchain ../meta-arm/meta-arm
bitbake-layers add-layer ../meta-rockchip
bitbake-layers add-layer ../meta-openembedded/meta-filesystems
bitbake-layers add-layer ../meta-openembedded/meta-python
bitbake-layers add-layer ../meta-openembedded/meta-networking
bitbake-layers add-layer ../meta-virtualization
bitbake-layers add-layer ../meta-tinker-xen
```

**Step 3 – Tell Yocto which board and which features.** Open `build/conf/local.conf` and make sure
it has these two lines:

```
MACHINE = "tinker-board"
DISTRO_FEATURES:append = " virtualization xen"
```

**Step 4 – Build:**

```
bitbake tinker-xen-test-image
```

The first build takes several hours, because it compiles everything from scratch. Later builds only
redo what changed and take minutes. When it works, the last line says something like
`all succeeded`. The SD card file ends up in
`build/tmp/deploy/images/tinker-board/tinker-xen-test-image-tinker-board.wic`.

> **Tip:** before changing anything, we saved a copy of the original, working image in
> `diagnostics/baseline/`. If everything goes wrong, you can always go back to it.

---

## Chapter 5 – Part 1 – Getting Xen to start

This was the hardest part. Xen had never run on this chip, and seven different things stood in the
way. We removed them one by one.

### Step 1 – The "freeze" that wasn't our image

**What we saw:** the board stopped after a line listing the SD card's partitions
(`mmcblk0: p1 … p9`).

**Why:** we counted. Our image has 7 partitions, but the message showed 9, and the bootloader
version was different too. The card held a completely different, older project, not our Yocto
image. That old project had a hang ~2 seconds into Linux, which we met again (and fixed) in Step 5.

**Fix:** write our own image to the card.

### Step 2 – Typing did nothing

**What we saw:** the board's messages appeared on the PC, but nothing we typed reached the board.

**Why:** the adapter's wires were on pins 8 and 10, which is a different serial port.

**Fix:** move the wires to pins 32, 33 and 34 (Chapter 2). Then we could log in.

### Step 3 – "Xen must be entered in NS Hyp mode"

**What we saw:** Linux on its own showed this line:

```
CPU: All CPU(s) started in SVC mode.
```

and Xen, started by hand from U-Boot, stopped immediately:

```
- Xen must be entered in NS Hyp mode -
- Please update the bootloader -
- Boot failed -
```

**Why:** remember the "levels of power" from Chapter 3. U-Boot handed over the CPU in "SVC mode"
(the operating-system level) and in "secure" state. Xen needs "HYP mode" in "non-secure" (NS)
state. U-Boot can do this switch for some chips, but nobody had ever written that code for the
RK3288.

**Fix:** we wrote it ourselves, in a U-Boot patch
(`0001-rockchip-rk3288-allow-booting-in-non-secure-HYP-mode.patch`). It does four things:

1. It tells U-Boot that this chip *can* do the switch.
2. It tells U-Boot where the interrupt controller (the GIC) is.
3. It opens up the chip's devices to "non-secure" programs. Normally many devices only listen to
   "secure" programs, so Xen and Linux would be locked out.
4. It **keeps the old behaviour as the default**. The switch only happens when our Xen start script
   asks for it, so plain Linux still boots exactly as before.

> **Safety note:** a broken bootloader can stop a board from starting. So we tested every new U-Boot
> by sending it over the serial cable straight into memory (`loady`) and starting it from there.
> Nothing was written to the card until it worked. Since the board starts from the SD card, the worst
> case is always "write the card again".

### Step 4 – Silence after "Starting kernel"

**What we saw:** after the patch, the board printed `Starting kernel ...` and then nothing at all.

**Why:** after a lot of detective work (we made the code print a letter at each step and saw it stop
at "E"), we found the cause. When the CPU enters HYP mode, it uses a settings register that nobody
had set, so it contained random leftovers. Those leftovers switched on features that made the very
first instruction crash.

**Fix:** set that register to a clean, known value just before switching (`0x30c50830`). Added to
the same U-Boot patch.

### Step 5 – Xen didn't know the processor

**What we saw:** `Missing processor info: 410fc0d1`.

**Why:** Xen keeps a list of processors it knows. The RK3288's CPU type (Cortex-A12/A17) wasn't on
the list, not even in the newest Xen.

**Fix:** a Xen patch (`0001`) that adds it, set up the same way as its close cousin, the Cortex-A15.

### Step 6 – Linux (dom0) crashed in two places

**Crash 1:** Linux crashed while reading a cache-control register called L2CTLR. Under Xen, reading
that register is "caught" by Xen, and Xen didn't know what to answer, so it reported an error.
**Fix:** Xen patch `0002`. Xen now answers with the real value, the same way the KVM hypervisor
does.

**Crash 2:** Linux crashed when touching a DMA controller (a helper that copies memory). It was
using the controller's "secure-only" address. **Fix:** our start script tells Linux to use the
controller's normal address instead.

### Step 7 – The famous 2-second hang

**What we saw:** Linux always stopped about 2 seconds after starting. This was the same hang the old
project on the card had.

**Why:** this one took the longest. Xen printed its internal clock, and the number was **negative**.
Time was going backwards! We found that Linux, while starting, **resets a hardware timer** (timer7),
and on this chip that timer drives the main system clock. Linux didn't mind, but Xen's clock jumped
back to zero, so every "wake me up in 1 second" alarm in Xen would never ring. Everything waited
forever.

**Fix:** a small Linux patch: "if timer7 is already running, leave it alone". U-Boot always starts
it, so Linux now never resets it.

### Result of Part 1

```
/sys/hypervisor/type  →  xen
```

Linux was running **on top of Xen** for the first time on this board.

---

## Chapter 6 – Part 2 – Making it a real system

### Step 8 – The first guest

We installed Xen's control tools (`xl`) and created a small test Linux as a guest. Commands:

```
xl create /etc/xen/guest1.cfg     # start a guest
xl list                           # see all domains
xl console guest1                 # talk to it (Ctrl-] to come back)
xl destroy guest1                 # switch it off
```

It worked. (We removed this test guest later, when Android arrived.)

Once, the board restarted by itself the moment we started a guest. It never happened again. The
reset reason said "power-on", so it was most likely a weak moment of the power supply.

### Step 9 – A network between the domains

We built a **bridge**, a virtual network switch inside dom0, called `xenbr0`, with the address
`192.168.100.1`. Each guest gets a virtual network cable plugged into it. A ping between Linux and
the guest worked in both directions, in under 1 millisecond.

### Step 10 – FreeRTOS as a guest

**Why FreeRTOS and not Zephyr?** Zephyr's Xen support only works on 64-bit ARM, and our chip is
32-bit.

We wrote the small "glue" FreeRTOS needs to live inside Xen. Xen gives every guest a virtual
interrupt controller and a virtual timer, and our code uses them to make the 1 ms "tick" that drives
FreeRTOS. The guest prints its results as text.

The first runs showed three bugs:

| What we saw | Why | Fix |
|---|---|---|
| The same text line printed again and again | memory caches were off, so Xen read old data | switch the caches on |
| Each 10 ms period was really 10.15 ms | each tick was timed from "now", so small delays added up | time each tick from a fixed schedule instead |
| FreeRTOS used 100 % of its CPU | when idle, it spun in a loop | when idle, it now sleeps (`WFI` instruction) |

After that: **10 ms, accurate to about 0.008 ms**.

### Step 11 – The real-time scheduler

With everything sharing one core, FreeRTOS was sometimes 19 ms late while the other guest started.
That's terrible for real-time. So we switched FreeRTOS to the **RTDS** scheduler and gave it a
guarantee: *200 µs in every 1 ms*.

```
xl sched-rtds -d rtos1 -v all -p 1000 -b 200 -e 1
#   -p period 1000 µs, -b budget 200 µs, -e may use spare time too
```

Results:

| Situation | Before (credit2) | After (RTDS) |
|---|---|---|
| Nothing else happening | ±0.008 ms | ±0.01–0.02 ms |
| Another guest starting | up to 19.9 ms late | mostly under ±0.115 ms |
| Linux 100 % busy | – | ±0.007 ms |

### Step 12 – `reboot` didn't work

**What we saw:** typing `reboot` printed `Xen: Platform reset did not work properly!` forever.

**Why:** Xen didn't know how to reset this particular chip.

**Fix:** Xen patch `0003` teaches Xen about the RK3288. To reset, it writes the magic value `0xfdb9`
into the chip's reset register, the same thing Linux and U-Boot do. The first version couldn't find
that register. Our board is the "RK3288**W**" variant, and U-Boot renames the device on it, so the
patch now accepts both names.

### Step 13 – Starting Xen automatically

Until now we started Xen by typing commands into U-Boot. To make it automatic, we used something
U-Boot already does: at power-on it looks on the card's boot partition for a file called
`/boot.scr` and runs it. So we:

- put our Xen start script there as `/boot.scr`;
- made sure the image doesn't contain the file U-Boot would otherwise prefer
  (`/extlinux/extlinux.conf`);
- kept a "plain Linux without Xen" option in `/native/extlinux.conf`, used if Xen is missing.

We never used `saveenv`, so U-Boot's own settings were never changed.

### Step 14 – Using all 4 CPU cores

**What we saw:** `Failed to bring up CPU 1 (error -19)`. Xen used only one core.

**Why:** Xen starts the other cores by asking the firmware through a standard interface called
**PSCI** ("please switch on core 2, and start it at this address"). This board had no PSCI.

**Fix:** we added PSCI to U-Boot (patch `0002`). U-Boot leaves a tiny piece of itself in memory, and
when Xen asks to switch on a core, that piece:

1. powers the core up,
2. writes the start address and a magic number (`0xdeadbeaf`) into a "mailbox" the chip's boot ROM
   watches,
3. wakes the core.

**Problem on the first try:** only 2 cores came up. All the sleeping cores watch the *same*
mailbox, so the first request woke all of them at once. **Fix:** switch the extra cores fully off
first, so each request wakes exactly one.

Result:

```
(XEN) Using PSCI v1.0
(XEN) Brought up 4 CPUs
```

---

## Chapter 7 – Part 3 – Adding Android

### Step 15 – Why Android 7, and why a special kernel

Google publishes ready-made Android images for 32-bit ARM only up to Android 7. Building Android
yourself needs about 250 GB of disk, more than our PC had free.

Android 7 talks to its kernel through a part called **binder**, using an old 32-bit format. That old
format was removed from Linux after version 4.18, and our dom0 Linux is 5.15. So Android gets **its
own kernel, Linux 4.14**, built by the recipe `linux-android-guest`.

### Step 16 – Adapting Android to Xen

The downloaded image was made for the Android phone emulator. We changed a few things:

- **Disks:** Android's `/system` and `/data` live on two extra SD card partitions (p8 and p9). Xen
  passes them to Android as virtual disks.
- **Startup file:** a new `init.xen.rc` tells Android how to start inside Xen (mount the disks,
  start the network, enable adb).
- **Graphics:** the emulator's graphics files were removed, and Android uses its built-in software
  drawing.
- **Network:** Android gets the address `192.168.100.3`, and dom0 is its gateway to the outside.

You talk to Android from dom0 with **adb** (Android Debug Bridge):

```
adb connect 192.168.100.3:5555
adb shell
```

### Step 17 – Android kept crashing at start

Android's main program (`system_server`) crashed and restarted again and again. We fixed it in
three rounds:

1. **Error:** `Could not register INotify for /dev/input`.
   **Why:** there's no keyboard or touchscreen, so the input folder was never created.
   **Fix:** create the folder at startup (`mkdir /dev/input` in `init.xen.rc`).

2. **Error:** a `NullPointerException` in the alarm service.
   **Why:** Android 7 sets its alarms in a way that needs a special permission. Android only got
   that permission in version 8, and the old way (a `/dev/alarm` device) doesn't exist in Linux
   4.14.
   **Fix:** a small patch to the Android kernel that allows alarms for Android's "system" user group
   (number 1000).

3. **Error:** the USB hub kept resetting while adb was running.
   **Why:** the board's USB hub falls asleep to save power and fails to wake up properly.
   **Fix:** a rule that keeps the hub awake.

### Step 18 – A Xen crash, and a clever workaround

**What we saw:** with the RTDS scheduler on all 4 cores, Xen crashed while Android started:

```
Assertion '!unit_on_replq(svc)' failed at rt.c:587
```

**Workaround:** use RTDS only where we really need it. Cores 0–2 got the normal credit2 scheduler
(for Linux and Android), and core 3 got its own pool, called `rt`, with RTDS just for FreeRTOS. This
is actually a nicer design anyway. (The real cause of this crash came back later and was properly
fixed in Step 28.)

**Result:** Android started fully (`sys.boot_completed = 1`) with zero crashes, and FreeRTOS stayed
accurate to ±0.06 ms while Android was busy.

---

## Chapter 8 – Part 4 – Polishing it

### Step 19 – Small but important improvements

- **Quieter FreeRTOS.** It printed 3 lines per second on the shared console, so you couldn't type.
  Now it prints one summary line every 10 seconds.
- **Faster, final Xen.** We switched from the "debug" Xen (extra checks, lots of messages) to the
  normal "release" Xen. The release build left out the real-time scheduler by default, so we turned
  it back on (`CONFIG_SCHED_RTDS=y`).
- **Temperature sensor.** Under Xen, the temperature driver waited forever and gave no readings.
  That also meant no automatic shutdown if the chip overheated. The cause was a link to "CPU cooling"
  that can't exist under Xen. **Fix:** the start script removes that link. Now the readings work
  (about 35–42 °C).
- **FreeRTOS gets a proper console.** Instead of a debug-only trick, it now uses a shared memory
  "ring" like the other guests, so `xl console rtos1` works with the release Xen.
- **Hardware watchdog.** A **watchdog** is a timer that restarts the board unless somebody "pats" it
  regularly. Dom0 now pats it every 5 seconds. If the system freezes, nobody pats it, and the board
  restarts itself after about 45 seconds. We tested it: it restarted after 43 seconds.
- **Guests start by themselves.** A startup script (`xen-guests`) starts FreeRTOS and Android at
  boot, and stops them cleanly at shutdown.
- **No more console spam.** Linux tried to put a login prompt on the serial port, which belongs to
  Xen, and complained `respawning too fast`. Now it doesn't try.
- **Android network service refused to start.** Android's security system (SELinux) said
  `Service xen-net does not have a SELinux domain defined`. **Fix:** tell it which security label
  to use (`seclabel u:r:su:s0`).

### Step 20 – Final check of Part 4

We restarted, powered off and powered on several times. Every time:

1. Xen started with 4 cores.
2. Both guests started on their own.
3. Android was ready about 76 seconds later.
4. FreeRTOS stayed between 9961 and 10038 µs (the target is 10000).

### Step 21 – Trying a screen and touch for Android (switched off again)

We tried to give Android a screen and touch:

- dom0 showed Android's screen on the HDMI monitor;
- a USB touchscreen was passed through to Android;
- sound worked in dom0.

Some of it worked: Android drew its screen and received taps.

**But:** Android's apps need a 3D graphics feature (OpenGL ES 2.0) that this setup doesn't have. We
could force apps to draw without it, but then Android **froze after 1–2 minutes**. We traced it to
Android's timer interrupt getting stuck, but couldn't solve it.

**Decision (yours, option A):** go back to the stable, screen-less Android. The screen and touch
code stays in the project, switched off.

---

## Chapter 9 – Part 5 – The car project

We moved toward a real-time **car system**. To keep it safe, we followed one simple rule:

> **The board never sends anything to a car.** We use a *pretend* car. If it's ever connected to a
> real car, it only *listens*.

### Step 22 – A pretend car

The program **`vehicle-sim`** acts like a car and sends two CAN messages every 10 ms on the pretend
CAN bus `vcan0`:

- message `0x0C0`: speed (in steps of 0.01 km/h);
- message `0x0C1`: engine speed in rpm.

It "drives" a 60-second loop:

```
0–20 s   speed up from 0 to 135 km/h (changing gears)
20–35 s  cruise at 135 km/h  (too fast on purpose: the limit is 120)
35–50 s  brake to a stop
50–60 s  stand still (engine idling at 800 rpm)
```

It shifts late in 2nd gear on purpose, so the engine goes over 6000 rpm.

### Step 23 – Getting the messages into FreeRTOS

FreeRTOS has no CAN driver of its own, so a small dom0 program, **`can2rtos`**, passes the messages
over:

1. It **only receives** CAN messages, and only the two IDs we care about.
2. For each speed message, it writes one simple text line into FreeRTOS's console, like
   `V 1234 13500 4590` (message number, speed, rpm).

### Step 24 – FreeRTOS checks every message

A new FreeRTOS task, **`vVehicleTask`**, runs every 5 ms. It reads the lines and checks:

| Check | Warning when | All-clear when |
|---|---|---|
| Overspeed | above 120 km/h | below 115 km/h |
| Engine redline | above 6000 rpm | below 5700 rpm |
| Signal lost | no message for 100 ms | messages return |

The all-clear is a bit lower than the warning on purpose. This "hysteresis" stops a warning from
flickering on and off when the value sits right at the limit.

If the signal is lost, FreeRTOS marks the speed as invalid instead of showing an old value. That's
the "fail-safe" idea: when in doubt, say "I don't know" rather than show something wrong.

Example of what it prints:

```
[vehicle] ALERT overspeed: 135 km/h (limit 120)
[vehicle] ALERT engine over redline: 6293 rpm (limit 6000)
[vehicle] redline cleared: 5694 rpm
[vehicle] SIGNAL LOST: no frame for 100 ms, speed/rpm invalid
[vehicle] SIGNAL OK again (seq 52011)
[vehicle] 10s: frames 1000, lost 0, bad 0, max gap 25000 us, speed 135 km/h, rpm 4590; ...
```

**Test result:** 1000 messages every 10 s, **0 lost**. All warnings came on and went off at the
right moments, and pausing the pretend car triggered "SIGNAL LOST".

### Step 25 – The dashboard

The program **`cluster-hdmi`** draws a car dashboard on the HDMI monitor:

- big speed numbers and rpm with a bar;
- four warning lamps: OVERSPEED, REDLINE, SIGNAL, RTOS;
- a status line at the bottom.

It reads the CAN messages itself (listen only), and it reads FreeRTOS's warnings from FreeRTOS's log
file.

**Problem:** the RTOS lamp had no data. **Why:** the folder for that log file
(`/var/log/xen/console`) didn't exist after a restart. **Fix:** create it automatically at every
boot.

No monitor was available, so we tested it by drawing into memory and saving a picture. This is the
real picture from the board:

![Dashboard picture taken on the board](images/cluster-dashboard-board.png)

### Step 26 – Messages arriving in bursts

**What we saw:** sometimes FreeRTOS waited **105 ms** between messages. That's dangerously close to
its 100 ms "signal lost" limit, even though the pretend car never paused. On the dom0 side, the
gaps were at most 29 ms.

**Why:** we read the source code of Xen's console program (`xenconsoled`). To protect itself from
noisy guests, it only listens to a guest's "I'm ready for more" signal 30 times per 0.2 seconds. Our
FreeRTOS sent that signal after *every* read, up to 200 times a second. So xenconsoled kept
ignoring it, and the messages piled up and then arrived in a burst.

**Fix:** FreeRTOS now only sends the signal when its input buffer is nearly full. xenconsoled keeps
filling a buffer that has room anyway, without being asked.

**Result:** the biggest gap dropped from 105 ms to **20–35 ms**, still with 0 lost messages.

### Step 27 – Ignition (switched off until wired)

In a real car, the computer should switch itself off cleanly when you turn the key off. The car's
"ACC" wire has 12 V while the key is on.

**`ignition-watch`** reads that signal on board pin 7:

- ACC off for 10 seconds → it shuts the board down cleanly (guests first).
- ACC back on within 10 seconds → it cancels the shutdown. Starting the engine can make the voltage
  dip for a moment.
- It does nothing until it has seen ACC "on" at least once. Without this, a board on your desk with
  nothing connected could switch itself off.

> **Danger:** 12 V would destroy the board's 3.3 V pin. It must go through an **optocoupler** or a
> voltage divider. That's why the service is **switched off** until it's wired correctly. Details
> are in the layer's README.

### Step 28 – A Xen crash after flashing

**What we saw:** right after writing the new card, about one minute after start, Xen crashed:

```
(XEN) CPU3: Unexpected Trap: Data Abort
(XEN) PC:     0023ae60 rt.c#repl_timer_handler+0x1cc/0x2ac
(XEN)      R0: 00100100 ...
(XEN) Panic on CPU 3:
(XEN) Reboot in five seconds...
```

**Detective work:**

1. We looked up the address `0023ae60` in Xen's symbol file. It's inside the RTDS scheduler, in a
   list of "who gets their time budget refilled next".
2. The number `00100100` is a special marker Xen writes into list entries that have been *removed*.
   So Xen was walking through a list that contained an entry it had already thrown away: the list
   was broken.
3. This is the **same bug** as the assertion in Step 18 (`rt.c:587`), so the workaround there had
   only hidden it.
4. We searched Xen's history and found that the Xen developers had fixed exactly this in 2022. When
   a guest is *paused* for a moment (Xen's own tools do that), the scheduler forgot to remove it
   from this list. When the guest resumed, it was added a second time, and the list broke. Our Xen
   (4.16.1) was older than the fix.
5. To prove it, we paused and resumed FreeRTOS in a loop on the old Xen. It crashed in under 250
   rounds, with exactly the same message.

**Fix:** we added the two official fixes (Xen patches `0004` and `0005`).

**Proof:** on the new card we ran the same loop **3000 times without a crash**. Afterwards
everything was still normal (1000 messages per 10 s, 0 lost, FreeRTOS 9958–10040 µs).

> **A mistake we made (no harm done):** while checking the board, we pressed Enter during U-Boot's
> "Hit any key" moment. U-Boot stopped and tried to run our Linux commands, which it didn't
> understand (`Unknown command`). None of them changes anything, and typing `boot` continued
> normally. Lesson: after switching on, only watch until `login:` appears.

---

## Chapter 10 – Part 6 – Four domains, a screen for each, Android 10

> **Status (2026-10-27):** the Yocto part of this chapter is **tested on the board** (Step 38).
> Not tested yet: real screens (no monitors connected) and Android 10, which is still being built. The Yocto build passed
> (4540 tasks, no warnings): card image 3.54 GB, dom0 root 578 MB, media-root 298 MB, no ffmpeg
> left in dom0. After Step 37 the card image is **1.57 GB**.

### Step 29 – The new wish list, and what the board can really do

**What we wanted:**

1. A smaller dom0, still a standard base Yocto image.
2. A smaller Android guest.
3. A newer Android, "Android 17".
4. FreeRTOS (rtos1) must always come first.
5. A fourth domain…
6. …running Yocto Linux that plays videos and shows pictures.
7. Every OS on a screen of its own.

**What we found:**

- **Android 17 can't run on this board.** The RK3288 is a 32-bit ARM chip (ARMv7) with 2 GB of
  memory, shared by all four domains. Current Android is built for 64-bit ARM, needs far more
  memory and a 3D graphics chip, and a much newer kernel than ours. Building it would also need
  about 400 GB of disk and 32–64 GB of memory on the PC, which has 15 GB.
- **The newest Android that fits** is decided by what exists for 32-bit ARM:

  | Android | Where it comes from | Effort | Risk |
  |---|---|---|---|
  | 7.0 (what we had) | Google's ready-made emulator image | done | works |
  | 7.1.1 | Google's last ready-made 32-bit ARM image (`armeabi-v7a-25_r18`, Google APIs) | small | low |
  | 9 | build from source | large | medium: others have run it on 32-bit ARM without 3D graphics |
  | 10 (LineageOS 17.1) | build from source | largest | high: nobody we found has run it on 32-bit ARM without 3D graphics, let alone under Xen |

  We checked Google's list of system images: after 7.1.1 there are only x86 and 64-bit ARM ones.
  **We chose Android 10 (LineageOS 17.1)** (Step 35).
- **The board has two display outputs:** HDMI and the MIPI DSI connector for the 7" panel. For one
  screen per OS we use **USB display adapters** as extra screens. FreeRTOS has no screen driver,
  so dom0 draws its status (the instrument cluster) for it.

### Step 30 – A smaller dom0

dom0 was already built on the standard base image (`core-image-minimal`). We made it smaller:

- **Memory:** `dom0_mem=512M` became **`dom0_mem=384M`** (`xen-boot.cmd`). dom0 still runs the Xen
  tools, QEMU for the guests' screens, the screen viewers, the car bench, SSH and adb.
- **Programs:** the video player (`ffmpeg`) and the river video moved out of dom0 into the new media
  guest (Step 32). They were the biggest programs in dom0.
- **Kept, by choice:** the car bench and dashboard, SSH and the tmux consoles, adb and sound.

### Step 31 – FreeRTOS always first

FreeRTOS already had core 3 to itself, with the real-time scheduler (RTDS) in its own CPU pool `rt`
(Step 11, Step 18). Until now it was promised **200 µs in every 1 ms**. Now it gets **the whole
core: 1000 µs in every 1000 µs** (`rtos1-start`, `BUDGET=1000`). Nothing else can ever be scheduled
on core 3, and no other domain can take time from FreeRTOS.

The other guests are pinned to cores 0–2 (`cpus = "0-2"` in `android1.cfg` and `media1.cfg`).

> **A mistake we caught:** we first also pinned FreeRTOS with `cpus = "3"`. We took it out again: the
> `rt` pool already keeps it on core 3, and a pin on top of the pool could stop it from starting.

FreeRTOS still shares the memory bus and cache with the other cores, so under heavy load (video,
Android drawing in software) expect slightly more jitter. Check the `10 ms task` lines in its log.

### Step 32 – The fourth domain: media1

A new guest, **media1**, is a small Yocto Linux that plays videos and shows pictures:

- **Image:** `media-guest-image` (base image + `ffmpeg` + `media-player`), written to its own SD
  card partition **`media-root`**, with 256 MB spare for your files (64 MB since Step 37).
- **Kernel:** dom0's own kernel (`/boot/zImage`). It already has the Xen parts a guest needs
  (disk, network, screen, keyboard).
- **Size:** 256 MB memory (192 MB since Step 37), 2 cores (on cores 0–2), for software video decoding.
- **Network:** `192.168.100.4` on the bridge, gateway dom0 (`192.168.100.1`). SSH with the same key
  as dom0.
- **Screen:** a Xen virtual screen, 800×480. QEMU in dom0 serves it on `127.0.0.1:5901`.
- **Player:** `media-player` loops everything in `/home/root/media` (videos *and* pictures, 5 s
  per picture). While that folder is empty it plays the river clip. `media-play` plays single files.

To add your own files, from the PC through dom0:

```
scp -r photos root@<board>:/tmp/            (to dom0)
scp -r /tmp/photos root@192.168.100.4:/home/root/media/   (in dom0, to media1)
```

The old `nature-video` recipe, which played the river on dom0's HDMI, is gone. The clip now lives in
`media-player`.

### Step 33 – A screen for each OS

A new service in dom0, **`display-map`**, decides which OS appears on which screen
(`/etc/default/display-map`):

```
SCREENS="hdmi=vnc:5900 usb1=vnc:5901 usb2=cluster usb3=console"
```

| Screen | Shows | How |
|---|---|---|
| `hdmi` (board's HDMI) | android1 | Android's virtual screen (VNC port 5900) |
| `usb1` (1st USB display) | media1 | media1's virtual screen (VNC port 5901) |
| `usb2` (2nd USB display) | rtos1 + car | the instrument cluster with FreeRTOS's real-time status |
| `usb3` (3rd USB display) | dom0 | dom0's text console (moved there with `con2fb`) |

- **USB displays** use the Linux `udl` driver (`CONFIG_DRM_UDL=m`). It drives the older
  **DisplayLink DL-1x0 / DL-1x5 (USB 2.0)** adapters. Newer DisplayLink adapters (DL-3xxx and later)
  need a closed driver and **won't work**. Numbering is by USB port, so keep each adapter in the
  same port. A screen that isn't plugged in yet is waited for.
- **Input:** a screen only gets the keyboard, mouse or touchscreen listed for it
  (`INPUT_hdmi=...`). By default only HDMI (Android) gets them. The viewer `android-hdmi` got a new
  option `-I` for this.
- **Text console:** `android-hdmi` and `cluster-hdmi` used to switch tty1 to graphics mode
  whatever screen they drew on. Now they do that only if the console is on *their* screen, so dom0's
  console stays readable on its own screen.
- The old single-screen services `android-hdmi` and `cluster-hdmi` are switched off
  (`ENABLED=0`): `display-map` starts the viewers itself.

> **Not yet working end to end:** Android 7's screen is still switched off (it froze, Step 21), so
> the HDMI screen stays black until Android has a working screen (Step 35).

### Step 34 – SSH and a console for each OS

Earlier in this part (in the same change set) we added:

- **SSH into dom0** (dropbear), key logins only: put your PC's public key in `TINKER_SSH_KEY` in
  `local.conf`. This is now a shared class (`tinker-ssh.bbclass`) used by dom0 and media1.
- **`consoles`**: one tmux session on the serial line with a pane per OS. It now has four panes:
  dom0, rtos1, android1 and media1.

### Step 35 – Android 10 (LineageOS 17.1), in progress

**Why it's hard:** no ready-made Android 10 exists for a Xen guest on 32-bit ARM. We have to build
it from source. Even a ready-made "generic" system image wouldn't be enough, because Android 10
also needs a `vendor` part for our virtual hardware (software graphics, screen, input, power), and
that has to be built from the same source.

**Setting up the PC:**

| What | Why |
|---|---|
| `sudo apt-get install … python2 …` (the list in the LineageOS build guide) | Android 10's build still uses Python 2 in places; Ubuntu 22.04 still has it |
| `git-lfs` | the WebView packages are stored with Git LFS; without it 3 of them failed to check out |
| **16 GB swap** (was 2 GB) | 15 GB memory isn't enough for the last step of the build |

> **A mistake we made (no harm done):** the swap commands were typed in a normal terminal with a `!`
> in front (`! sudo swapoff … && …`). The `!` is a Claude Code shortcut, but in bash it means
> "NOT": `swapoff` worked, was counted as a failure, and everything after `&&` was skipped. The PC
> had **no swap at all** until we ran the commands again without the `!`.

**Download:** into `~/lineage-17.1`, a "shallow" copy (only the newest version of each project):

```
repo init -u https://github.com/LineageOS/android.git -b lineage-17.1 --depth=1 -g default,-darwin,-mips,-notdefault
repo sync -c -j8 --no-tags --no-clone-bundle --optimized-fetch --prune
```

Most of it is needed. Only about 5–8 GB could be left out (WebView for arm64/x86, emulator files),
so we kept it complete except for those WebView packages.

**Result:** **58 GB** on the PC. Three WebView packages had failed to check out (they were fetched
before `git-lfs` was installed). The fix:

- a local manifest, `~/lineage-17.1/.repo/local_manifests/tinker-xen.xml`, drops the arm64, x86
  and x86_64 WebView packages (a 32-bit ARM build doesn't use them);
- the ARM one was synced again and its 98 MB `webview.apk` fetched with `git lfs pull`.

**Target:** LineageOS has a generic 32-bit ARM product, **`lineage_arm-userdebug`**
(`vendor/lineage/build/target/product/lineage_arm.mk`). It is built on AOSP's `aosp_arm` (the ARM
emulator) and already uses the 64-bit binder ABI (`TARGET_USES_64_BIT_BINDER := true`).

**How much space** (estimates until the first build):

| | On the PC | On the SD card |
|---|---|---|
| source | **58 GB (measured)** | – |
| build output | ~60–90 GB | – |
| Android 10 total | **~100–140 GB** (more with ccache, which stays off) | system 1.5–2 GB, vendor 0.1–0.3 GB, data ~2 GB |
| whole card | – | **~4–4.5 GB: 8 GB card minimum, 16 GB recommended** (today **1.57 GB**, measured after Step 37) |

**The plan:**

1. Find the generic 32-bit ARM target in the tree (`gsi_arm` or `lineage_arm`) and build it once,
   unchanged (several hours).
2. A new guest kernel setup: Android 8 and later need the newer binder (`hwbinder`, `vndbinder`)
   instead of Android 7's 32-bit binder.
3. Graphics without a 3D chip: SwiftShader for drawing, and a screen setup that works with Xen's
   virtual screen. **This is where it's most likely to fail.**
4. Package it as the new `android-guest` recipe. android1 will then need about **768 MB** again
   (we lowered it to 512 MB for Android 7 in Step 30).

If Android 10 can't be made to work, the fallback is Android 9 (built from source) or 7.1.1
(ready-made).

### Step 36 – Is it safe for the board?

- **Heat is the main risk.** Under Xen the CPU can't slow itself down when hot (the cooling link was
  removed, Step 19 / problem 23). The chip's hardware cut-off still works, so it switches off
  before damage, but abruptly. With video and Android drawing in software, cores 0–2 run flat out
  for long stretches. The CPU stays at 500 MHz under Xen (Chapter 14), which keeps it cooler than
  full speed would, but **use a heatsink and a fan** anyway. Watch
  `cat /sys/class/thermal/thermal_zone1/temp`.
- **Speed:** the same 500 MHz also means software drawing (Android 10) and video decoding are slow.
  The 800×480 river clip is made to decode in real time; bigger videos may stutter.
- **Power:** use a good 5 V / 3 A supply and a **powered USB hub** for the USB displays.
- **SD card:** three Linux-based systems write to it. Use a good A1/A2 card and shut down with
  `poweroff`.
- **Memory:** dom0 320 + android1 512–768 + media1 192 + rtos1 4 MB ≈ 1.0–1.3 GB of 2 GB (Step 37).
- **Bring-up order:** flash the new Yocto build with Android 7 first → check `xl list` and
  FreeRTOS's timing → media1 and the screens (watching the temperature) → Android 10 last.

### Step 37 – Making every OS smaller

**What we wanted:** every OS as small as possible, on the card and in memory.

**What we found:** most of dom0 wasn't dom0 at all. Of its 291 MB, **220 MB were QEMU's firmware
files**: BIOS images for emulated PCs, RISC-V, SPARC and PowerPC machines. Xen only uses QEMU for
the guests' screens and disks and never loads them. Android's system disk was 1.8 GB with only
575 MB used, and the boot partition was 146 MB for about 25 MB of files.

**What we changed:**

| OS | On the card, before → after | Memory, before → after | How |
|---|---|---|---|
| dom0 | root 578 → **166 MB**, boot 146 → **48 MB** | 384 → **320 MB** | QEMU firmware removed (keymaps kept), 32 MB spare instead of 64, boot partition fixed at 48 MB |
| android1 | system 1.8 GB → **613 MB**; data 550 MB (kept) | 512 MB (kept) | system disk shrunk to its contents + 10 % (it's read-only); data kept because Android compiles its framework into it on first boot |
| media1 | 298 → **106 MB** | 256 → **192 MB** | room for your files 256 → 64 MB (raise `IMAGE_ROOTFS_EXTRA_SPACE` for more) |
| rtos1 | 21 KB (in dom0's root) | 16 → **4 MB** | it uses 172 KB; `rtos1.cfg`, `guest.ld` and `main.c` (`GUEST_RAM_MB`) changed together |
| **whole card** | **3.54 → 1.57 GB** | **1168 → 1028 MB** of 2048 | fits a 2 GB card (Android 10 will need more) |

> **Two build failures on the way (no harm done):** first `truncate` was missing (Yocto only lets
> recipes use a fixed list of PC tools, so we cut the file with `dd`); then the disk check found the
> shrunk disk's reserved "resize" inode still had its old size, so the build now repairs it with
> `e2fsck -fy` before the final check.

**If something fails on the board:** undo rtos1's 4 MB first (it's the critical domain), then raise
dom0 to 384 MB and media1 to 256 MB.

### Step 38 – Testing it on the board

You wrote the card; Claude ran the checks over the serial cable (logs in `diagnostics/part6/`,
summary in `diagnostics/part6/RESULTS.md`). No Ethernet cable, monitor or USB display was connected.

| Check | Result |
|---|---|
| Starts to `tinker-board login:` (switch-on and `reboot`) | ✓ |
| `xl list` | ✓ Domain-0 320, rtos1 4, android1 511, media1 191 MB |
| FreeRTOS gets all of core 3 from boot | ✓ period 1000, budget 1000 µs |
| FreeRTOS 10 ms task while Android starts | ✓ 9952–10049 µs |
| Car messages into FreeRTOS | ✓ 1000 per 10 s, 0 lost |
| Android | ✓ finished starting in under 4 minutes; 282 MB of 496 free; shrunk system disk works |
| media1 | ✓ starts with dom0's kernel, network works, the video plays (screen changes every frame) |
| dom0 memory | ✓ 228 MB of 282 MB available |
| Temperature | ✓ 45–46 °C |
| Shutdown order | ✓ media1 → android1 → rtos1 |

> **Something we learned:** `xl sched-rtds -d rtos1` shows Xen's default (10000/4000). Add `-v all`
> to see the real values for each vCPU (1000/1000).

**Still to test:** the screens (needs an HDMI monitor and DisplayLink DL-1x0/1x5 adapters), media1's
screen from the PC over VNC (needs the Ethernet cable), Android 10.

**Found while testing (small improvements for later):** media1's kernel keeps 64 MB for a feature
it doesn't use (CMA); `cma=0` would give that back. Android's data disk used only 40 MB, so it could
be smaller too.

### Step 39 – A rear camera and one sound system for all

You asked for a back camera and for sound. You picked a **USB webcam** (the ribbon-cable camera has
no driver for this chip in our Linux version), the **cluster screen** for the camera picture, and
**all three kinds of sound**: car chimes, media1's videos and Android.

**The rear camera.** The pretend car now sends a third message, the **gear** (`0x0C2`: P, R, N or D).
Each drive cycle ends with backing up for 6 seconds and parking. A new program, `rear-camera`, sits
on the cluster screen. It watches the gear and, as soon as the car is in **R**:

1. it **pauses** the dashboard (so the two programs don't draw over each other),
2. shows the webcam picture, **mirrored** like a mirror, with **guide lines** (red near, amber,
   green far) and "CHECK SURROUNDINGS" at the top,
3. plays the **reverse beep**.

One second after the car leaves R, the dashboard gets its screen back and draws everything again.
If the car messages stop, the camera also gives the screen back, so the "signal lost" warning is
visible. Without a webcam the screen shows colour bars and "NO CAMERA"; a webcam plugged in later
is picked up. The dashboard now shows **GEAR R** and **GEAR P** too. It all runs in dom0, so it
doesn't depend on any guest.

**The sound.** The board has one speaker output (the 3.5 mm jack). Only dom0 can use it, so
dom0 gets a **mixer**, `audio-mixer`, that every sound goes through:

| Sound | Where it comes from | How it gets to the mixer |
|---|---|---|
| Car chimes (warning, reverse, info) | made by the mixer itself | requested by `vehicle-chimes` and `rear-camera` |
| media1's videos | ffmpeg in media1 | over the network (xenbr0), UDP port 5601 |
| Android 7 | Android's sound driver | over the network, TCP port 5602 |

Chimes are most important: while one plays, the guests' sound is turned down to a quarter.
`vehicle-chimes` listens to FreeRTOS's warnings (overspeed, redline, signal lost: warning chime;
cleared: a soft "info" chime). The mixer only listens on dom0's xenbr0 address and only accepts each
guest's own address.

> **A trick for Android:** Android 7 came from the phone emulator, whose sound driver writes to a
> special emulator file, `/dev/eac`. We give Android a file with that name that is really a **pipe**,
> and a tiny script sends whatever comes out of it to dom0 with `netcat`. Android also looks for its
> sound driver under the name `xen`, so the build adds that name pointing to the emulator's driver.

**Tested on the PC** (not on the board yet): the mixer mixes two guest streams at the right pitch
(Android's 44.1 kHz is converted to 48 kHz), turns them down during a chime and plays the chimes;
media1's ffmpeg command delivers its sound cleanly; `vehicle-chimes` reacts to the warnings, even
after the log is trimmed; the camera picture, guide lines and "NO CAMERA" screen look right; the
dashboard is paused in reverse and comes back 1 s later.

**Still to test on the board:** a real webcam (it must offer the YUYV format; most do), the USB
sound codec's name, and Android's sound.

**Limits:** Android's sound arrives about 0.5–1 s late (the pipe and the network hold some), so a
video in Android would be out of sync. Android 10 needs its own way (later). The guide lines are
fixed; they don't follow the steering wheel.

### Step 40 – Trying it on the board, and Android gets its screen

You flashed the card and connected an 800x480 HDMI display. What we found:

- **The first "display" was a capture stick.** A MacroSilicon MS2109 "USB Video" stick *records*
  HDMI into a computer; it can't show a picture. The display has to be on the board's HDMI port.
- **The webcam crashed dom0's kernel** the moment it started streaming. Under Xen, the kernel asks
  for camera memory in a special way, and on this board that memory sits in "high memory", which
  the kernel can't reach directly, so it wrote to address 0. Kernel patch **0003** takes normal
  memory instead. Until the board reboots after such a crash, USB is stuck (a mouse plugged in
  later isn't seen).
- **Sound:** the onboard codec's first output only does 8 kHz (telephone quality); the mixer now
  uses the second one (`plughw:CARD=Audio,DEV=1`, 48 kHz). `/etc/init.d/audio-mixer restart`
  killed itself (the script and the program have the same name): fixed. In Android 7, `mkfifo`
  and `netcat` exist only as `toybox mkfifo` / `toybox netcat`: fixed. A ringtone played in
  Android reached the mixer.
- **Android's screen works now.** The "freeze 1–2 minutes after boot" from Step 26 was really
  Android going to **sleep** like a phone when its screen timed out, and a sleeping Xen guest has
  nothing that wakes it up (the log says `PM: suspend entry (s2idle)`). Android now holds a
  "stay awake" lock from the start and keeps its screen on; it ran over 6 minutes with the screen,
  past the old freeze. SystemUI crashed on its 3D wallpaper; "low-RAM mode" makes it draw the
  wallpaper in software.
- **The HDMI screen** now shows Android, and the rear camera takes it over while reversing, like a
  car's head unit (`hdmi=rearcam:vnc:5900`). The mouse (or a touchscreen) taps on Android's
  screen; there's no arrow, because Android sees it as a touchscreen.

---

## Chapter 10a – Part 7 – Three guests: the HDMI fix and FreeRTOS's own screen

*2026-11-04. Everything in this chapter was tested on the board.*

### Step 41 – Back to three operating systems

**What changed:** the Android guest was taken out of the project (commit `5986a0e`, "Remove the
Android guest"). The board now runs three systems at once:

| System | Job | Its screen |
|---|---|---|
| **dom0** (Yocto Linux) | runs Xen's tools, the disks, the network, the pretend car | the serial cable (UART) |
| **rtos1** (FreeRTOS) | real-time checks of the car data, on its own core (CPU 3) | its **own small SPI screen** (ILI9341 TFT, 320x240) |
| **media1** (Yocto Linux) | plays videos and pictures in a loop | the **HDMI monitor** (through dom0) |

Parts of the older chapters still talk about Android: that is the history. The tables in this
chapter and in Part 2, section 9.12, describe the system as it is now.

### Step 42 – "This VM has no graphic display device" on the HDMI screen

**What we wanted:** media1's video on the HDMI monitor, all the time.

**What went wrong:** sometimes, while a video was playing, the monitor suddenly showed the
grey text **"This VM has no graphic display device"** instead of the video.

**Why:** media1 doesn't own the HDMI port. Its picture travels like this:

```
 media1 draws into its virtual screen (PV framebuffer, 800x480)
   → QEMU in dom0 offers that screen as a VNC server (127.0.0.1:5901)
     → guest-vnc in dom0 (a tiny VNC viewer) copies it onto the HDMI monitor (/dev/fb0)
       (display-map starts guest-vnc and restarts it when it stops)
```

When media1 restarts (a crash, a reboot, or `xl destroy` + `xl create`), QEMU is started again.
For the first seconds, before media1's kernel has connected its screen, QEMU has nothing to show,
so it shows a **placeholder page**, 640x480, with exactly that text.

`display-map` already knew this. Before it starts the viewer it waits until media1's screen is
really connected. But `guest-vnc` had its **own** "reconnect" loop: when the connection broke, it
reconnected by itself after 2 seconds, without asking `display-map`. It got the placeholder page and
put it on the monitor. The log showed it clearly:

```
guest-vnc: connection lost, retrying
guest-vnc: guest 640x480 shown 1680x1050 ...     ← the placeholder
guest-vnc: guest 800x480 shown 1680x1050 ...     ← media1's real screen, seconds later
```

**How we fixed it:**

1. `guest-vnc` has a new option, **`-1`** ("one connection"): when the connection is lost it clears
   the monitor to black and **exits** instead of reconnecting.
2. `display-map` always starts it with `-1`. So every reconnect goes through `display-map`'s
   check, which waits for media1's real screen.
3. That check got stricter: it used to look only at dom0's side of the screen connection. It now
   also asks media1's side, because right after a guest is destroyed, dom0's side can still say
   "connected" for a moment.

**Tested:** media1 was destroyed and created again while it was playing. The log now shows:

```
guest-vnc: connection lost, exiting (-1)
hdmi: waiting for the guest screen on VNC port 5901
guest-vnc: guest 800x480 shown 1680x1050 on 1680x1050 monitor at +0+0
```

The placeholder never reached the monitor: it stays black for a few seconds, then the video is back.

### Step 43 – FreeRTOS's own screen stayed blank

**What we wanted:** FreeRTOS shows its own dashboard (speed, RPM, warnings, timing) on a small
2.8" SPI screen with an **ILI9341** chip, wired to the 40-pin header. It draws it **itself**:
Xen gives rtos1 two pieces of the chip directly (the SPI2 controller and the GPIO5 pins), and
nothing else goes through Linux.

**What went wrong:** the screen stayed blank, although FreeRTOS printed
`[tft] ILI9341 320x240 on SPI2 initialised` and everything else in rtos1 ran perfectly.

**How we searched:** we read the chip's registers from dom0 (read-only) and measured the pins
while FreeRTOS was drawing:

| Checked | Found |
|---|---|
| SPI2 clocks switched on by dom0 (`rtos1-hwprep`) | ✓ on, 49.5 MHz |
| pins set to SPI2 / GPIO | ✓ all six correct |
| SPI2 controller set up by FreeRTOS | ✓ enabled, mode 0, 8 bits, send only |
| DC and RESET lines | ✓ outputs, RESET high |
| is data actually sent? | ✓ SPI2 busy ~6 % of the time, DC toggling |

So the board was talking. The screen just wasn't listening.

**Why:** two things in the FreeRTOS screen driver (`tft.c`):

1. **Too fast.** The SPI clock was 49.5 MHz ÷ 2 = **24.75 MHz**. The ILI9341's data sheet allows
   one bit every 100 ns at the fastest, that is **10 MHz**. Some panels manage more on a short
   circuit board, but over loose jumper wires 2.5 times too fast usually means the panel
   understands nothing and stays white (or black).
2. **No way to get back in step.** The chip-select line (CS) was switched on once and never off
   again. The panel counts the bits of each byte and only starts counting again from zero when CS
   goes off and on. With CS always on, a single lost bit shifts every following byte for good.

**How we fixed it:**

1. The SPI clock is now 49.5 MHz ÷ **6** = **8.25 MHz** (inside the data sheet). It can still be
   changed when building (`SPI_BAUD_DIV`).
2. CS is switched off and on again before **every command**, so the panel always starts fresh.

The slower clock makes drawing a bit slower, but the dashboard only redraws the parts that change.
FreeRTOS's timing didn't change at all (10 ms task 9941–10066 µs), because the screen is drawn by
the lowest-priority task.

### Step 44 – The wiring, and a restart of rtos1

The pins on the board were checked while FreeRTOS drew (all six measured working), then the
wires to the panel were corrected. This is the full wiring:

| Panel pin | Header pin | What it is |
|---|---|---|
| VCC | **17** (or 1) | 3.3 V power |
| GND | **20** (or 6, 9, 14, 25) | ground |
| CS | **24** | chip select (SPI2_CSN0) |
| RESET | **18** | reset (GPIO5_B3) |
| DC / RS | **22** | command or data (GPIO5_C3) |
| SDI / MOSI | **19** | data to the panel (SPI2_TXD) |
| SCK | **23** | SPI clock (SPI2_CLK) |
| LED | **1** (3.3 V) | backlight |
| SDO / MISO | 21 (optional) | not used: FreeRTOS only sends |
| T_CLK, T_CS, T_DIN, T_DO, T_IRQ | not connected | the touch chip is not used |

> **Use 3.3 V, not 5 V**, for VCC, unless the module has its own regulator. Keep the wires short
> (under 15 cm), above all SCK. Don't use pin 7: it belongs to the ignition input.

**One more thing:** the panel only gets its setup commands once, when rtos1 starts. If the panel
is (re)wired or loses power while the board is running, it forgets them, so restart rtos1:

```
xl destroy rtos1; rtos1-start
```

After that, the screen showed the dashboard: a navy title bar "FreeRTOS rtos1 – Xen guest, CPU 3",
big speed in km/h, RPM with a green/red bar, warnings, the real-time numbers, and a small square
that blinks green top right.

### Step 45 – Making it permanent

- **Both guests start by themselves** at every boot: `xen-guests` (`XEN_GUESTS="rtos1 media1"`)
  starts rtos1 first (on CPU 3 with the real-time scheduler, and `rtos1-hwprep` before it), then
  media1; `display-map` then puts media1 on HDMI.
- **Every console logs in by itself** (no user name or password): dom0 and media1, on the Xen
  console (hvc0), tty1 and the board UART. SSH still needs the key.
- The fixed programs were put on the card in the board, and the image was built again with them
  (now `tinker-xen-test-image-tinker-board-20261104074956.rootfs.wic`, see Step 46) for new cards.
- **Checked with a full restart:** U-Boot → Xen → dom0 logged in by itself → rtos1 started and set
  up its TFT → media1 started, logged in and played its video → HDMI showed it (800x480 stretched to
  the 1680x1050 monitor).

### Step 46 – The video was gone after a power cut

**What went wrong:** after switching the power off and on, the HDMI screen stayed black: no video.

**Why:** in the first seconds after the board starts, some of the blocks media1 reads from its
disk arrive **corrupted**. Which program is hit changes from start to start:

- `init` misreads its own settings file (`INIT: /etc/inittab[..]: wait: unknown action field`) and
  runs none of media1's start scripts: no network, no video;
- or the network setup crashes (`Configuring network interfaces... Segmentation fault`): video, but
  no network, so no rear camera and no sound;
- or the disk itself reports a broken block (`EXT4-fs error ... checksum invalid`) and media1 can't
  even start `init`.

The files on the card are fine, and a second start of media1 always worked. We tested the two things
that happen just before media1 starts (dom0's disk check, and the board's SDIO controller being
probed again): neither causes it on its own. The real cause is still unknown.

**How we fixed it:** `xen-guests` now **checks** media1 after starting it. media1 counts as
started only when **both** are true:

1. its login prompt (`root@media1`) appears in its console log, and
2. it answers a ping on its network address (192.168.100.4).

If a program crashes during its start (`unknown action field`, `Segmentation fault`,
`terminated by signal`, `EXT4-fs error`, `couldn't execute`, `Kernel panic`), or the two checks
aren't both true within 45 seconds, it starts media1 again (up to 3 times). What it did is written
to `/var/log/xen-guests.log`:

```
media1 start broken: INIT: /etc/inittab[12]: wait: unknown action field
media1 did not start properly, restarting it (1/3)
media1 started properly after 1 restart(s)
```

**Tested:** a forced failure (restart, then "giving up" after the set number of tries); normal
starts ("started properly" the first time, network up); and several board restarts and a power cut
where the fault happened. Each time media1 was restarted once and came back with video, network
and HDMI, about 45 seconds after the board started.

---

## Chapter 11 – How the finished system works

> This chapter shows the system **after Part 6** (Chapter 10). Part 6 is built but not yet tested on
> the board; Android is still Android 7 until Android 10 is ready.
>
> **Since Part 7 (Chapter 10a) Android is gone.** The board runs dom0, rtos1 and media1: HDMI shows
> media1 (`SCREENS="hdmi=vnc:5901"`), and rtos1 draws on its own SPI TFT. Read "android1" below
> as history.

### Who runs where

```
   Core 0      Core 1      Core 2     │    Core 3
  ┌──────────────────────────────────┐│  ┌──────────────────────┐
  │ Pool-0, fair scheduler (credit2) ││  │ Pool "rt", real-time │
  │                                  ││  │ scheduler (RTDS)     │
  │  Linux dom0   (1 core, 320 MB)   ││  │                      │
  │  Android      (2 cores, 512 MB)  ││  │  FreeRTOS (4 MB)     │
  │  media1       (2 cores, 192 MB)  ││  │  the whole core:     │
  │                                  ││  │  1000 µs every 1 ms  │
  └──────────────────────────────────┘│  └──────────────────────┘
```

### What happens when you switch on

The short version:

```
 1. The chip's boot ROM loads U-Boot from the SD card.
 2. U-Boot finds /boot.scr on the card and runs it.
 3. The script loads Xen, Linux and the board description, fixes a few
    settings, switches the CPU to HYP mode and starts Xen.
 4. Xen switches on all 4 cores (through PSCI) and starts Linux (dom0).
 5. Linux starts its services in this order:
      watchdog → network bridge → Xen tools → guests (FreeRTOS, Android, media1)
      → pretend car + gateway → display-map (a viewer per screen) → ignition watcher (off)
 6. You see:  tinker-board login:
```

If Xen can't start, the script automatically starts plain Linux instead, so you're never stuck.

### How the domains start (flow diagram)

```
 POWER ON
    │
    ▼
┌──────────────────────────┐
│ Boot ROM (inside chip)   │  reads the SD card, sector 64
└────────────┬─────────────┘
             ▼
┌──────────────────────────┐
│ TPL → SPL → U-Boot       │  sets up memory, switches the CPU to HYP mode
│ (partitions 1 and 4)     │  PSCI ready for 4 cores
└────────────┬─────────────┘
             ▼
┌──────────────────────────┐
│ /boot.scr (partition 6)  │  loads  /xen          → 0x02000000
│ start script             │         /zImage (dom0)→ 0x04000000
│                          │         /rk3288-tinker.dtb
│                          │  sets   dom0_mem=320M, 1 vCPU, sched=credit2
└────────────┬─────────────┘
             │  Xen fails to start? ──► plain Linux without Xen (fallback)
             ▼
╔══════════════════════════╗
║ XEN HYPERVISOR           ║  turns on all 4 cores, takes all memory,
║                          ║  makes Pool-0 (cores 0–3, credit2)
╚════════════╤═════════════╝
             ▼
┌──────────────────────────┐
│ DOM0  (Linux 5.15)       │  kernel boots, mounts partition 7 (root)
└────────────┬─────────────┘
             ▼
   dom0 services start in this order
             │
   S05 ──► hw-watchdog       restarts the board if everything hangs
   S79 ──► xenbr0            virtual network 192.168.100.1 + NAT
   S80 ──► xencommons        xenstored + xenconsoled (Xen's helpers)
   S90 ──► xen-guests  ──────────────────────────────┐
   S92 ──► vehicle-bench     pretend car on vcan0    │
   S93 ──► display-map       one viewer per screen   │
   S94 ──► ignition-watch    (switched off)          │
             │                                       │
             ▼                                       │
        tinker-board login:                          │
                                                     ▼
              ┌───────────────────── xen-guests starts the guests ─────┐
              │                                                        │
              ▼ 1st                       ▼ 2nd                ▼ 3rd   │
  ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
  │ rtos1-start         │  │ xl create           │  │ xl create           │
  │  core 3 → pool "rt" │  │  android1.cfg       │  │  media1.cfg         │
  │  (RTDS scheduler)   │  │                     │  │                     │
  │  xl create rtos1    │  │ kernel 4.14 +       │  │ dom0's zImage       │
  │  budget 1000/1000µs │  │ ramdisk from dom0   │  │ disk: media-root    │
  ├─────────────────────┤  │ disks: p8 + p9      │  │ (p10)               │
  │ RTOS1  (FreeRTOS)   │  ├─────────────────────┤  │ QEMU screen :5901   │
  │ 4 MB, core 3 alone  │  │ ANDROID1            │  ├─────────────────────┤
  │ 10 ms task starts   │  │ 512 MB, cores 0–2   │  │ MEDIA1  (Yocto)     │
  │ in < 1 second       │  │ boot done ~2–3 min  │  │ 192 MB, cores 0–2   │
  └─────────────────────┘  │ adb 192.168.100.3   │  │ 192.168.100.4       │
                           └─────────────────────┘  │ media-player starts │
                                                    └─────────────────────┘

  Then display-map shows them:   HDMI ← android1    USB 1 ← media1
                                 USB 2 ← rtos1 cluster   USB 3 ← dom0 console
```

- **Xen starts dom0, and dom0 starts the guests.** Only Xen and dom0 are started by the boot itself.
- **rtos1 starts first.** It's moved onto core 3 before Android and media1 start, so it never shares
  a core. FreeRTOS boots in under a second.
- **Android is the slowest.** It takes about 2–3 minutes, and longer on the very first boot while it
  compiles its framework.
- **Shutdown runs in reverse.** On `poweroff`, `xen-guests` stops media1, then android1, then
  rtos1, and dom0 switches off last.

### How the car data flows

```
 vehicle-sim ──(CAN, every 10 ms)──► vcan0 ──► can2rtos ──(text lines)──► FreeRTOS
   (pretend car: speed,                 │      (listen only)                   │
    rpm, gear)                          │                                  checks and
                                        ├──────────► cluster-hdmi ◄──── warnings in its log
                                        │            (dashboard, 2nd USB screen)    │
                                        └─ gear R ─► rear-camera                     ▼
                                                     (webcam on the same screen) vehicle-chimes
```

### How the sound flows

```
 vehicle-chimes (FreeRTOS warnings) ─┐
 rear-camera (reverse beep) ─────────┤ chime requests
                                     ▼
 media1: ffmpeg ──UDP 5601──────► audio-mixer ──► speaker / 3.5 mm jack
 android1: /dev/eac ──TCP 5602──►  (dom0)          (onboard USB codec)
                  (guests turned down while a chime plays)
```

### Which screen shows what

```
 android1 ──PV screen──► QEMU :5900 ──► android-hdmi ──► HDMI
 webcam, only in reverse ─────────────► rear-camera ───► HDMI (pauses Android's picture)
 media1   ──PV screen──► QEMU :5901 ──► android-hdmi ──► USB display 1
 rtos1 + car (dom0 draws it) ─────────► cluster-hdmi ──► USB display 2
 dom0 text console (tty1) ────────────► con2fb ────────► USB display 3
                       (all started and watched by display-map)
```

With only the HDMI display, you pick which one it shows (see "Showing each OS on the HDMI
screen" in Chapter 12).

### How fast and how big each system is (measured 2026-11-04)

Measured on the board while media1 played its video: boot times from a restart with every serial
line timestamped, CPU from Xen's own accounting over 10 seconds.

**How long the start takes** (seconds after the board resets):

```
  0.7 s   U-Boot starts (its "Hit any key" countdown is 2 s)
 17.5 s   Xen starts
 20.5 s   dom0's Linux starts
 37.3 s   rtos1 starts → its TFT dashboard appears about half a second later
 38.1 s   media1 starts
 42.6 s   dom0 logged in
 ~53 s    media1 playing on HDMI (good start, ~15 s after it was created)
 ~61 s    … if media1 had to be restarted once (common after switching on, Step 46)
```

**What each system gets and uses:**

| | dom0 (Yocto Linux) | rtos1 (FreeRTOS) | media1 (Yocto Linux) |
|---|---|---|---|
| Ready after reset | 42.6 s (logged in) | ~38 s (dashboard on the TFT) | ~53 s (~61 s with one restart) |
| CPU cores | 1, shared on cores 0–2 | 1, **core 3 all to itself** | 2, shared on cores 0–2 |
| CPU used | 88 % of a core (mostly copying the video to HDMI) | 12 % of its core | ~107 % (decoding the video) |
| Memory given | 320 MB | 4 MB | 191 MB |
| Memory used | 44–96 MB | 16.5 KB (of a 64 KB heap) | 45–73 MB |
| Space on the card | 145 MB partition, 55 MB used | 27.8 KB (one file in dom0) | 122 MB partition, 41 MB used (60 MB free for videos) |
| Its program | Linux 5.15 `zImage` (10 MB) | `freertos-xen-guest.bin` (27.8 KB) | uses dom0's `zImage` |

The board has 4 cores at 500 MHz and 2048 MB of memory; 1353 MB stays free. The whole card image is
331.5 MB, of which only 116.6 MB is really written to the card.

### What's on the SD card

```
 part 1     loader     the first tiny starter program
 part 4     U-Boot     our patched bootloader
 part 6     boot       xen, zImage (Linux), board description, boot.scr
 part 7     root       Linux dom0's files
 part 8     android-system   Android's programs
 part 9     android-data     Android's data
 part 10    media-root       media1's files (+ 64 MB for your videos and pictures)
 (2, 3, 5 are reserved and empty)
```

### Where our work lives (the layer)

```
meta-tinker-xen/
├── recipes-bsp/          U-Boot fixes (HYP mode, PSCI) and the Xen start script
├── recipes-extended/
│   ├── xen/              Xen fixes 0001–0005 and its settings
│   ├── xenbr0/           the virtual network switch
│   ├── xen-guests/       start guests at boot, watchdog, USB hub rule
│   ├── vehicle-bench/    pretend car + gateway
│   ├── cluster-hdmi/     dashboard
│   ├── ignition-watch/   key-off shutdown (off)
│   ├── android-hdmi/     viewer for a guest's screen (used by display-map)
│   ├── display-map/      one screen per OS (HDMI + USB displays)
│   ├── media-guest/      media1's xl config
│   ├── media-player/     video + picture player (inside media1)
│   └── xen-consoles/     tmux consoles for every OS
├── recipes-kernel/       Linux dom0 fix (timer7), HDMI pixel clocks, extra features (bridge, CAN, USB displays)
├── recipes-rtos/         FreeRTOS guest
├── recipes-android/      Android and its 4.14 kernel
├── recipes-core/         the dom0 and media1 image recipes; login-prompt fix; dropbear PATH
├── classes/              tinker-ssh: SSH key setup shared by dom0 and media1
├── recipes-devtools/     QEMU (only needed for the Android screen)
└── wic/                  SD card layout
```

---

## Chapter 12 – How to build, flash and use it

### Build (on the PC)

```
cd ~/xen-hypervisor
./build.sh
```

`build.sh` runs `sync.sh` first if the layers or `build/conf` are missing, stops if a layer is on the
wrong version, saves a log in `build/logs/` and prints the image's checksum at the end. Useful
options: `./build.sh --sync` (update the layers first) and `./build.sh --clean` (rebuild from scratch).

This also builds media1's image (`media-guest-image`) and puts it on the card. The card needs to be
**at least 8 GB** (16 GB once Android 10 is in).

### Build Android 10 (on the PC, in progress)

```
cd ~/lineage-17.1
source build/envsetup.sh
lunch lineage_arm-userdebug
m -j8
```

Needs the packages, `git-lfs` and 16 GB swap from Step 35. The first build takes several hours.

### Write the SD card (on the PC)

> **Careful:** this erases the whole card. Make sure you pick the card and not your PC's own disk!

1. Put the card in the PC and find its name. Look for its size (for example 14.8G or 29.7G):
   ```
   cd ~/xen-hypervisor
   ./flash.sh --list
   ```
2. Erase the card and write the image (it asks you to type `yes` and for your sudo password):
   ```
   ./flash.sh /dev/sda
   ```

`flash.sh` refuses anything that isn't a real, removable whole disk (so it won't write to a
partition, to a file, or to the PC's own disk). It unmounts the card, wipes the old partition table,
writes the image with `bmaptool` and prints the new partitions. To write a different image:
`./flash.sh /dev/sda path/to/image.wic`.

Always write to the whole card (`/dev/sda`), never to one partition (`/dev/sda1`).

> **Something that happened to us:** once the card wasn't really connected, and the write went into
> an ordinary 3.2 GB *file* called `/dev/sda` instead. You can recognise this when `ls -l /dev/sda`
> starts with `-` instead of `b`. Only in that case is it safe to delete it (`sudo rm /dev/sda`) and
> re-insert the card.

### First start

1. Put the card in the board and connect the serial adapter.
2. Start `picocom -b 115200 /dev/ttyUSB0` on the PC.
3. Switch on the board. **Don't press keys** until you see `tinker-board login:`.
4. Type `root` and press Enter (there's no password).

### Testing the screen, camera, sound and mouse (after writing the card)

Plug in **before** switching on: the HDMI display (on the board's HDMI port), the USB webcam, the
mouse, and headphones or a speaker in the 3.5 mm jack.

| Test | Command (on the board) | What you should see / hear |
|---|---|---|
| Android on the screen | wait about 2 minutes after `login:` | Android's home screen on HDMI |
| Android finished starting | `adb connect 192.168.100.3:5555` then `adb shell getprop sys.boot_completed` | `1` |
| Android stays awake | `adb shell dumpsys power \| grep -E "mWakefulness=\|mStayOn="` | `Awake`, `true` |
| mouse | click / drag on the screen | taps and swipes in Android (no arrow) |
| mouse is seen | `grep -A4 Mouse /proc/bus/input/devices` | your mouse, with an `event` handler |
| rear camera on | `/etc/init.d/vehicle-bench reverse` | webcam picture, guide lines, "CHECK SURROUNDINGS", reverse beep |
| rear camera off | `/etc/init.d/vehicle-bench reverse` (again) | Android back after 1 s |
| camera log | `tail -3 /var/log/display-map.log` | `rear-camera: in reverse`, `/dev/video0 640x480 YUYV` |
| chimes | `audio-mixer -c warn` (also `reverse`, `info`) | beeps in the headphones |
| sound output | `grep -E "^rate\|^state" /proc/asound/card*/pcm1p/sub0/hw_params /proc/asound/card*/pcm1p/sub0/status` | `rate: 48000`, `state: RUNNING` |
| volume | `amixer -c Audio sget PCM,1` | `[100%] ... [on]` (`amixer -c Audio sset PCM,1 80%` to change) |
| sound log | `tail /var/log/audio-mixer.log` | `playing on plughw:CARD=Audio,DEV=1`, `android: connected from 192.168.100.3` |
| Android sound | `adb shell am start -a android.intent.action.VIEW -t audio/ogg -d file:///system/media/audio/ringtones/Andromeda.ogg -n com.android.music/.AudioPreview` | a ringtone in the headphones |

To show another OS on the screen, see "Showing each OS on the HDMI screen" below.

### Everyday commands (on the board)

| I want to… | Type |
|---|---|
| see all running systems | `xl list` |
| see how cores are shared | `xl cpupool-list` |
| watch FreeRTOS | `xl console rtos1` (leave with `Ctrl-]`) |
| use Android's shell | `xl console android1`, or `adb connect 192.168.100.3:5555` then `adb shell` |
| use media1's shell | `xl console media1`, or `ssh root@192.168.100.4` |
| play something on media1 | copy it to `/home/root/media/` in media1 (it loops that folder) |
| all consoles at once | `consoles` (tmux; `Ctrl-b d` leaves) |
| change which OS is on which screen | edit `/etc/default/display-map`, then `/etc/init.d/display-map restart` |
| stop / start the guests | `/etc/init.d/xen-guests stop` / `start` |
| see the raw car messages | `candump vcan0` |
| see FreeRTOS's car checks | `grep vehicle /var/log/xen/console/guest-rtos1.log \| tail` |
| test "signal lost" | `/etc/init.d/vehicle-bench pause` (run it again to resume) |
| use Android as root | `adb root`, then `adb connect 192.168.100.3:5555` again |
| restart Android | `xl destroy android1; xl create /etc/xen/android1.cfg` |
| restart the screen viewers | `/etc/init.d/display-map restart` |
| restart the sound | `/etc/init.d/audio-mixer restart` |
| test the rear camera | `/etc/init.d/vehicle-bench reverse` (run it again to release) |
| hear a chime | `audio-mixer -c warn` (or `reverse`, `info`) |
| see the sound log | `cat /var/log/audio-mixer.log` |
| change the sound card or levels | edit `/etc/default/audio-mixer`, then `/etc/init.d/audio-mixer restart` |
| read the temperature | `cat /sys/class/thermal/thermal_zone1/temp` (in thousandths of °C) |
| restart / switch off | `reboot` / `poweroff` |

What `xl list` should show:

```
Name                                        ID   Mem VCPUs	State	Time(s)
Domain-0                                     0   320     1     r-----     423.3
rtos1                                        1     4     1     -b----       8.9
android1                                     2   511     2     r-----     458.9
media1                                       3   192     2     -b----      35.0
```

(Expected after Part 6; the times are only examples.)

### Showing each OS on the HDMI screen (on the board)

With one HDMI display, one OS is shown at a time. You choose it in `/etc/default/display-map`
and restart `display-map`. The card shows **Android** at first.

**1. Android (android1)**, with the rear camera taking over in reverse:
```
sed -i 's/^SCREENS=.*/SCREENS="hdmi=rearcam:vnc:5900"/' /etc/default/display-map
/etc/init.d/display-map restart
```
Check it:
```
xl list | grep android1
tail -3 /var/log/display-map.log        # "connected to 127.0.0.1:5900", "guest 800x480"
adb connect 192.168.100.3:5555
adb shell getprop sys.boot_completed     # 1 = Android has finished starting
```
Android needs 1–2 minutes to start. The mouse taps on the screen (no arrow: Android sees it as a
touchscreen).

**2. media1 (video player):**
```
sed -i 's/^SCREENS=.*/SCREENS="hdmi=vnc:5901"/' /etc/default/display-map
/etc/init.d/display-map restart
```
Check it: `xl list | grep media1`, and `tail -3 /var/log/display-map.log` shows
"connected to 127.0.0.1:5901". The river clip plays in a loop.

**3. FreeRTOS (rtos1) and the car, on the dashboard.** FreeRTOS has no screen of its own; the
dashboard shows its live checks (speed, rpm, gear, the OVERSPEED / REDLINE / SIGNAL / RTOS lamps):
```
sed -i 's/^SCREENS=.*/SCREENS="hdmi=rearcam:cluster"/' /etc/default/display-map
/etc/init.d/display-map restart
```
Check it:
```
xl list | grep rtos1
grep vehicle /var/log/xen/console/guest-rtos1.log | tail -3
/etc/init.d/vehicle-bench pause          # SIGNAL lamp turns red; run it again to resume
```
FreeRTOS's own text console: `xl console rtos1` (leave with `Ctrl-]`).

**4. dom0 (Linux text console):**
```
sed -i 's/^SCREENS=.*/SCREENS="hdmi=console"/' /etc/default/display-map
/etc/init.d/display-map restart
```
dom0's login prompt appears on the screen; log in with a USB keyboard as `root`.

**5. Rear camera** (works with 1 and 3, because of `rearcam:`):
```
/etc/init.d/vehicle-bench reverse        # webcam with guide lines + reverse beep
/etc/init.d/vehicle-bench reverse        # again: back to Android / the dashboard
tail -3 /var/log/display-map.log         # "rear-camera: in reverse", "/dev/video0 640x480 YUYV"
```
Every 60 s drive cycle also backs up for 6 s by itself.

**6. Sound** (whatever the screen shows):
```
audio-mixer -c warn                      # warning chime (also: reverse, info)
tail /var/log/audio-mixer.log
```

**Everything at once:**
```
xl list                                  # all 4 OSes and their memory
consoles                                 # tmux: every console side by side (Ctrl-b d leaves)
grep ^SCREENS /etc/default/display-map   # what the screen shows now
```

With USB displays (DisplayLink DL-1x0/1x5) as well, list one entry per screen, e.g.
`SCREENS="hdmi=rearcam:vnc:5900 usb1=vnc:5901 usb2=cluster usb3=console"`.

**If the screen stays black:** `cat /sys/class/drm/card0-HDMI-A-1/status` must say `connected`
(the display must be on the board's HDMI port; a USB *capture* stick can't show a picture), and
`tail -5 /var/log/display-map.log` shows what the viewer is doing.

### Reading the logs (on the board)

Every system writes a diary of what it did: a **log**. Two things to know first:

- **Logs disappear when the board restarts.** They are kept in memory, not on the card. If you
  want to keep them, save them first (see the end of this section).
- **Type or paste one short line at a time.** Xen only holds 128 typed characters at once, so a
  long pasted line gets scrambled.

The very first messages (U-Boot and Xen starting up) only go to the serial cable. To see them,
start `picocom -b 115200 /dev/ttyUSB0` on the PC *before* switching the board on.

| I want to see… | Type |
|---|---|
| **Starting up** | |
| Xen's own log (cores, schedulers, guests created) | `xl dmesg` |
| Linux's start-up messages | `cat /var/log/dmesg` |
| Linux's messages right now | `dmesg` |
| which services started | `cat /var/log/boot` |
| **Yocto Linux** | |
| everything the services reported | `cat /var/log/messages` |
| the dashboard | `cat /var/log/cluster-hdmi.log` |
| which screen shows what (and plug-ins) | `cat /var/log/display-map.log` |
| the pretend car | `cat /var/log/vehicle-bench.log` |
| **FreeRTOS** | |
| everything FreeRTOS printed | `cat /var/log/xen/console/guest-rtos1.log` |
| only the timing reports | `grep '10 ms task' /var/log/xen/console/guest-rtos1.log` |
| only the car warnings | `grep ALERT /var/log/xen/console/guest-rtos1.log` |
| FreeRTOS live | `xl console rtos1` (leave with `Ctrl-]`) |
| **Android** | |
| Android's start-up messages | `cat /var/log/xen/console/guest-android1.log` |
| Android live | `xl console android1` (leave with `Ctrl-]`) |
| connect to Android first (for the lines below) | `adb connect 192.168.100.3:5555` |
| the apps' log | `adb logcat -d` |
| only crashes | `adb logcat -d -b crash` |
| has Android finished starting? (`1` = yes) | `adb shell getprop sys.boot_completed` |
| **media1** | |
| media1's start-up messages | `cat /var/log/xen/console/guest-media1.log` |
| the player (inside media1) | `ssh root@192.168.100.4 cat /var/log/media-player.log` |

To **watch a log live**, use `tail -f` instead of `cat` (for example
`tail -f /var/log/messages`), or `adb logcat` without `-d`. Press `Ctrl-C` to stop watching.

**Watching live from the build PC** (arjune; dom0 is `192.168.88.110`, media1 `192.168.100.4` can
only be reached through dom0; `Ctrl-C` stops):

| I want to watch… | Type on the PC |
|---|---|
| the serial console (U-Boot, Xen, dom0) | `picocom -b 115200 /dev/ttyUSB0` (leave: `Ctrl-a Ctrl-x`) |
| which screen shows what | `ssh -t root@192.168.88.110 tail -f /var/log/display-map.log` |
| FreeRTOS | `ssh -t root@192.168.88.110 tail -f /var/log/xen/console/guest-rtos1.log` |
| media1's start-up and console | `ssh -t root@192.168.88.110 tail -f /var/log/xen/console/guest-media1.log` |
| media1's player | `ssh -t root@192.168.88.110 ssh -t -y root@192.168.100.4 tail -f /var/log/media-player.log` |
| a guest's own console | `ssh -t root@192.168.88.110 xl console media1` (or `rtos1`; leave: `Ctrl-]`) |

> Don't press keys in `picocom` while the board starts: a key during "Hit any key to stop autoboot"
> stops in U-Boot. Type `boot` to go on.

**Saving all logs to the card** (one line at a time):

```
D=/home/root/logs-$(date +%H%M%S)
mkdir -p $D
cp -r /var/log/* $D/
xl dmesg > $D/xen-dmesg.txt
dmesg > $D/dom0-dmesg-now.txt
xl list > $D/xl-list.txt
adb connect 192.168.100.3:5555
adb logcat -d > $D/android-logcat.txt
sync; ls $D
```

To read them on the PC, switch the board off, put the card in a card reader and open
`/media/<your user>/root/home/root/` – each save is a folder called `logs-<time>`.

### Reading a real car (later, listen only)

1. Plug in a USB CAN adapter.
2. Edit `/etc/default/vehicle-bench` and set `IFACE=can0`, `SIM=0`, `BITRATE=500000`.
3. Run `/etc/init.d/vehicle-bench restart`.

The adapter is put in "listen-only" mode, so it never sends anything. Real cars use their own
message numbers, so `can2rtos` would need to learn them first. **Never connect the pretend car
program to a real car.**

---

## Chapter 13 – Every problem we hit, in plain words

| # | What we saw | What was really wrong | How we fixed it |
|---|---|---|---|
| 1 | Linux stopped after listing partitions | the card had an old, different project on it | wrote our image |
| 2 | typing didn't reach the board | wires on the wrong serial pins | pins 32/33/34 |
| 3 | "Xen must be entered in NS Hyp mode" | U-Boot couldn't hand over in hypervisor mode | U-Boot patch 0001 |
| 4 | silence after "Starting kernel" | a CPU setting held random leftovers | set it to a clean value |
| 5 | non-secure programs locked out | chip devices were "secure only" | open them in U-Boot |
| 6 | "Missing processor info" | Xen didn't know this CPU | Xen patch 0001 |
| 7 | Linux crashed reading L2CTLR | Xen didn't answer that register | Xen patch 0002 |
| 8 | Linux crashed at a DMA address | it used the secure-only address | start script fixes the address |
| 9 | Linux hung after 2 seconds | Linux reset the clock timer, so Xen's time ran backwards | Linux patch: leave timer7 alone |
| 10 | board restarted once at `xl create` | probably a power dip | use a 5 V / 3 A supply |
| 11 | FreeRTOS repeated old lines | caches off | caches on |
| 12 | FreeRTOS period 10.15 ms | small delays added up | fixed schedule |
| 13 | FreeRTOS used 100 % CPU | busy waiting | sleep when idle |
| 14 | `reboot` never finished | Xen couldn't reset this chip | Xen patch 0003 |
| 15 | "Cannot find the RK3288 CRU node" | RK3288W uses a different name | accept both names |
| 16 | only 1 CPU core used | no PSCI firmware | PSCI in U-Boot (patch 0002) |
| 17 | only 2 cores came up | one mailbox woke all cores | switch them off first |
| 18 | Android crash: no /dev/input | no input devices | create the folder |
| 19 | Android alarm crash | missing permission in Android 7 | small kernel patch |
| 20 | USB hub kept resetting | hub's power saving | keep it awake |
| 21 | Xen assertion rt.c:587 | Xen scheduler bug (see 32) | RTDS only on core 3 |
| 22 | release Xen had no real-time scheduler | turned off by default | turn it on |
| 23 | no temperature readings | "CPU cooling" link impossible under Xen | remove the link |
| 24 | Android network service refused | no security label | add `seclabel` |
| 25 | "respawning too fast" spam | login prompt on Xen's port | don't start it there |
| 26 | "Device or resource busy" when flashing | card partition still mounted | unmount again |
| 27 | `/dev/sda` was a file, not the card | wrote while the card was missing | delete only if it starts with `-` |
| 28 | Android screen: "no suitable EGLConfig" | wrong colour depth | 16-bit colour patch |
| 29 | Android froze with the screen on | no 3D graphics; timer got stuck | not solved → screen off |
| 30 | dashboard RTOS lamp empty | log folder missing | create it at boot |
| 31 | car messages arrived in 105 ms bursts | FreeRTOS signalled too often and got ignored | signal only when needed |
| 32 | Xen crash in `repl_timer_handler` | guest pause broke a scheduler list (old Xen bug) | official Xen fixes 0004 + 0005 |
| 33 | U-Boot said "Unknown command" | Enter pressed during the countdown | type `boot`; wait for login |
| 34 | board went silent twice | probably the power supply | power-cycle; better supply |
| 35 | Android's home screen keeps restarting | needs 3D graphics | accepted (Android is screen-less) |
| 36 | "Android 17" wanted | 32-bit ARM chip, 2 GB, no 3D: not possible | Android 10 from source (LineageOS 17.1) |
| 37 | 3 WebView packages "Cannot checkout" | stored with Git LFS, which wasn't installed | install git-lfs; drop arm64/x86, `git lfs pull` the ARM one |
| 38 | the PC had no swap after resizing it | `!` in front of the command means "NOT" in bash | run the commands without `!` |
| 39 | FreeRTOS pinned with `cpus = "3"` | could clash with its `rt` pool at start | removed; the pool is enough |
| 40 | HDMI: "This VM has no graphic display device" while a video played | after media1 restarted, the viewer reconnected by itself and showed QEMU's placeholder page | `guest-vnc -1`: the viewer exits, `display-map` waits for media1's real screen |
| 41 | FreeRTOS's TFT blank, although "initialised" | SPI clock 24.75 MHz, the panel allows 10 MHz; CS never released | 8.25 MHz, CS toggled before every command |
| 42 | TFT still blank after rewiring | the panel lost its setup when it was rewired | `xl destroy rtos1; rtos1-start` |
| 43 | no video after a power cut (`unknown action field` in media1) | media1's init misreads its settings on cold starts (cause unknown) | `xen-guests` checks media1 and restarts it automatically |

---

## Chapter 14 – What doesn't work yet, and how to recover

### Not working, or not tested yet

- **Android's screen is new (Step 40):** apps draw in software, so it's slow; there's no mouse
  arrow (Android sees the mouse as a touchscreen).
- **Part 6 tested on the board** (Step 38): all four domains at the new sizes, FreeRTOS 1000/1000,
  Android 7, media1 and its video. **Still not tested:** the screens (`display-map` on real
  displays, the USB displays with `udl`, only DisplayLink DL-1x0/1x5) and the HDMI pixel-clock
  patch 0002.
- **Rear camera and sound (Step 39) not tested on the board yet:** needs a USB webcam with YUYV,
  and something plugged into the 3.5 mm jack. Android 10 has no sound path yet.
- **Android 10 is in progress:** source downloaded, first build running. Graphics without a 3D chip may
  not work at all (fallback: Android 9 or 7.1.1).
- **Not tested, because the equipment is missing:** internet for the guests (no Ethernet cable),
  the dashboard on a real monitor, the ignition wire, a real CAN adapter.
- **Not for a real car's controls.** This is a test bench and a listen-only monitor. It isn't
  certified for safety (ISO 26262) and must never control anything in a car.
- **The car data travels through Linux** on its way to FreeRTOS, so delivery can lag by up to about
  35 ms. Only FreeRTOS's own checks are truly real-time.
- **The CPU stays at 500 MHz**, because this Xen version can't change the CPU speed.
- **Security was opened up** for bring-up: U-Boot makes everything "non-secure". That's fine for a
  test board, not for a product.
- **License:** the Android image is for development only and mustn't be given away.
- **media1 start-up after a power cut (Step 46):** media1's disk reads are often corrupted in the
  first seconds after a cold start (different programs break each time). `xen-guests` detects it and
  restarts media1 automatically, so the video takes about 45 s to appear. The root cause is unknown.
- **The TFT keeps its picture only while powered:** after rewiring it or a power loss of the panel
  alone, restart rtos1 (Step 44).

### If something goes wrong

| Problem | What to do |
|---|---|
| a guest misbehaves | `xl destroy <name>`, then `/etc/init.d/xen-guests start` |
| the whole system freezes | wait ~45 s: the watchdog restarts it. Otherwise switch off and on |
| dom0 stuck (no prompt), but Xen answers | press `Ctrl-a` three times, then `R`: Xen restarts the board. (`Ctrl-a` three times again switches back to dom0) |
| USB stopped working (`lsusb` hangs, a new mouse isn't seen) | restart the board. It happened after the webcam crash that kernel patch 0003 fixes |
| the screen is black | `cat /sys/class/drm/card0-HDMI-A-1/status` must say `connected`; then `tail -5 /var/log/display-map.log` |
| HDMI shows "This VM has no graphic display device" | the image is older than Part 7: flash the new one. Right now: `/etc/init.d/display-map restart` |
| media1 has no video and no network after a start | `cat /var/log/xen-guests.log` (the automatic restart should have fixed it). By hand: `xl destroy media1; /etc/init.d/xen-guests start` |
| FreeRTOS's TFT is blank or white | check VCC, GND, LED, SCK (23), MOSI (19); then `xl destroy rtos1; rtos1-start`. White = no data, black = no backlight |
| Android freezes after 1–2 minutes | it went to sleep: `adb shell cat /sys/power/wake_lock` must show `xen` |
| no sound | `tail /var/log/audio-mixer.log`; the device must be `plughw:CARD=Audio,DEV=1` in `/etc/default/audio-mixer` |
| Xen doesn't start | press a key at "Hit any key", then type `sysboot mmc 1:6 any ${scriptaddr} /native/extlinux.conf` to start Linux without Xen |
| Android's data is broken | write the card again |
| the card doesn't start at all | write the card again from the PC. The original working image is in `diagnostics/baseline/` |

The board's own built-in storage is never touched. Everything lives on the SD card, so writing the
card again always fixes it.

> **Never type `saveenv` at the U-Boot prompt.** It permanently changes U-Boot's settings.

### The rules we followed the whole time

1. Only you write the SD card. The PC never does it automatically.
2. No commands that permanently change the bootloader or erase disks.
3. Every new bootloader or Xen was first tested from memory only.
4. Nothing counts as "tested" without a log file from the board. They're all in `diagnostics/`.
5. Nothing ever sends messages to a car.

---

## Chapter 15 – Word list

| Word | Simple meaning |
|---|---|
| **ACC** | the car wire that has power while the key is turned on |
| **adb** | a tool to control Android from another computer |
| **bitbake** | the command that runs the Yocto build |
| **boot ROM** | a tiny program inside the chip that runs first |
| **bootloader / U-Boot** | the program that prepares the board and starts the next one |
| **bridge** | a virtual network switch inside Linux |
| **CAN bus** | the network cars use between their computers |
| **console / UART / serial** | the text connection to the board through the USB adapter |
| **core / CPU** | one "brain" of the processor (this board has 4) |
| **cpupool** | a group of cores with its own scheduler |
| **credit2** | Xen's fair-share scheduler |
| **display-map** | the dom0 service that puts each OS on its own screen |
| **DisplayLink / udl** | USB display adapters, and the Linux driver for the older USB 2.0 ones |
| **dom0 / Domain-0** | the boss Linux that controls Xen |
| **domain / guest** | one operating system running on Xen |
| **fail-safe** | when unsure, choose the safe answer ("data invalid") |
| **flash / write the card** | copy the image onto the SD card |
| **Git LFS** | a git add-on for big files; some Android parts are stored with it |
| **GSI** | a "generic" Android system image that runs on many devices |
| **HYP mode** | the CPU level a hypervisor needs |
| **hypervisor** | software that runs several operating systems at once, kept apart |
| **hysteresis** | the warning switches off a bit below where it switched on, to avoid flicker |
| **image (.wic)** | one file containing the whole SD card |
| **kernel** | the core of an operating system |
| **layer** | a folder of Yocto recipes; ours is `meta-tinker-xen` |
| **LineageOS** | a community version of Android; 17.1 is Android 10 |
| **listen-only** | a CAN mode where the board never sends anything |
| **media1** | the 4th domain: a small Yocto Linux that plays videos and pictures |
| **patch** | a file describing small changes to source code |
| **PSCI** | a standard way to ask firmware to switch CPU cores on and off |
| **PV screen (vfb)** | a virtual screen a Xen guest draws into; dom0 shows it |
| **real-time** | always on time, not just fast on average |
| **recipe / bbappend** | Yocto files: how to build something / extra changes to another recipe |
| **RTDS** | Xen's real-time scheduler (guaranteed time slices) |
| **scheduler** | the part that decides which program uses a core next |
| **SELinux** | Android's security system |
| **swap** | disk space the PC uses as extra memory when its memory is full |
| **SwiftShader** | a program that does 3D graphics on the CPU, for systems without a 3D chip |
| **vcan** | a pretend CAN bus inside Linux, for testing |
| **watchdog** | a timer that restarts the board if the system stops responding |
| **xl** | the command to control Xen (list, create, stop guests) |
| **Yocto** | the "factory" that builds a custom Linux from recipes |

---

*Exact measurements, full code listings, addresses and image checksums are in
[Part 2 – Technical reference](#part-2--technical-reference). The full engineering log is `diagnostics/REPORT.md`, sections A–Z. Every
board test has its own log file in `diagnostics/`.*

---

# Part 2 – Technical reference

*Tinker Board R2.0 (RK3288) – Yocto + Xen Mixed-Criticality System*
**Complete project documentation: from the first boot log to the automotive bench**

| | |
|---|---|
| Board | ASUS Tinker Board R2.0 – Rockchip RK3288 (RK3288W), 4 × Cortex-A17, 2 GB RAM |
| Build system | Yocto Project 4.0 "kirkstone" (Poky) |
| Hypervisor | Xen 4.16.1 (ARM32) |
| Operating systems | Yocto Linux 5.15 (dom0), Android 7.0 AOSP (guest), FreeRTOS 11.1 (real-time guest) |
| Project layer | `~/xen-hypervisor/meta-tinker-xen` |
| Test evidence | `~/xen-hypervisor/diagnostics/` (REPORT.md sections A–Z, UART logs, bitbake logs) |
| Period | 2026-10-22 to 2026-10-25 |
| Final image | `tinker-xen-test-image-tinker-board-20261025094250.rootfs.wic`, sha256 `99a3fec640201d6b8e74c675a8d039f611ef7c67394d18ed555a84a18e5f9412` (flashed and verified) |
| Current image (2026-11-04) | `tinker-xen-test-image-tinker-board-20261104074956.rootfs.wic`, sha256 `8dd49e115fa02d6a55647f78d5018868a0cae5d2c232ef9ce8f91c1dca30c2db` – dom0 + rtos1 (SPI TFT) + media1 (HDMI) with start check, no Android; see 9.12 |

---

## Contents

1. [What this project is](#1-what-this-project-is)
2. [Final result – what you get](#2-final-result--what-you-get)
3. [Hardware and host setup](#3-hardware-and-host-setup)
4. [Software stack](#4-software-stack)
5. [System architecture](#5-system-architecture)
6. [Directory trees](#6-directory-trees)
7. [Build environment setup](#7-build-environment-setup)
8. [Project history, stage by stage](#8-project-history-stage-by-stage)
9. [Component reference (code and configuration)](#9-component-reference-code-and-configuration)
10. [Build and flash procedure](#10-build-and-flash-procedure)
11. [Operating the system (commands and expected output)](#11-operating-the-system-commands-and-expected-output)
12. [Testing and verification](#12-testing-and-verification)
13. [All errors and fixes](#13-all-errors-and-fixes)
14. [Known limitations](#14-known-limitations)
15. [Recovery plan](#15-recovery-plan)
16. [Working rules and safety](#16-working-rules-and-safety)
17. [Future work](#17-future-work)
18. [Appendix](#18-appendix)

---

## 1. What this project is

The goal was to run several operating systems **at the same time** on one cheap ARM board, each
isolated from the others by a hypervisor, the way modern cars combine an infotainment system, a
control computer and a safety-critical real-time controller on one chip
("mixed-criticality system").

```
            one board, one SD card, power on → everything starts by itself

   ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
   │  Yocto Linux     │  │  Android 7.0     │  │  FreeRTOS 11.1   │
   │  (control, dom0) │  │  (apps, headless)│  │  (hard real time)│
   └──────────────────┘  └──────────────────┘  └──────────────────┘
   ┌──────────────────────────────────────────────────────────────┐
   │                    Xen 4.16 hypervisor                       │
   └──────────────────────────────────────────────────────────────┘
   ┌──────────────────────────────────────────────────────────────┐
   │    ASUS Tinker Board R2.0 – RK3288, 4 × Cortex-A17, 2 GB     │
   └──────────────────────────────────────────────────────────────┘
```

The RK3288 was never supported by Xen: the bootloader could not start a hypervisor, Xen did not
know the CPU, could not start the other CPU cores, could not reboot the board, and the Linux
kernel broke Xen's clock. All of that had to be found and fixed (Section 8). The project ends with
an automotive bench application: a simulated vehicle on a CAN bus, a read-only gateway into the
real-time OS, real-time safety checks, and an instrument-cluster dashboard for HDMI.

---

## 2. Final result – what you get

### 2.1 What runs on the board

| Domain | OS | CPUs | Memory | Scheduler | Job |
|---|---|---|---|---|---|
| Domain-0 | Yocto Linux 5.15 (Poky kirkstone) | 1 vCPU (Pool-0: pCPU 0-2) | 512 MB | credit2 | Control OS: Xen tools, network, CAN gateway, dashboard, watchdog |
| android1 | Android 7.0 AOSP (Linux 4.14 guest kernel) | 2 vCPUs (Pool-0) | 768 MB | credit2 | Application OS, headless, adb over network |
| rtos1 | FreeRTOS 11.1 | 1 vCPU, alone on pCPU 3 | 16 MB | RTDS (200 µs every 1 ms) | Hard real-time: 10 ms control task, vehicle safety checks |

### 2.2 Features and their status

| Feature | Status |
|---|---|
| Power on → U-Boot → Xen → dom0 → guests start, no key pressed | ✅ tested |
| Xen on all 4 CPUs (PSCI added to U-Boot) | ✅ tested |
| `reboot` / `poweroff` from dom0 | ✅ tested |
| Hardware watchdog resets a hung system (~43 s) | ✅ tested |
| FreeRTOS 10 ms task: 9958–10040 µs while Android runs | ✅ tested |
| Android boots (`sys.boot_completed=1`), adb from dom0 | ✅ tested |
| Guest network 192.168.100.0/24, NAT rule in dom0 | ✅ tested (internet itself untested: no Ethernet) |
| Temperatures (CPU/GPU) and hardware over-temperature shutdown | ✅ tested |
| Automotive bench: simulated CAN → FreeRTOS, 0 lost frames, gaps ≤ 35 ms | ✅ tested |
| Overspeed, redline and signal-loss alerts in FreeRTOS | ✅ tested |
| Instrument-cluster dashboard (HDMI framebuffer) | ✅ tested on a RAM framebuffer, ⏳ no monitor yet |
| Ignition (ACC) power-off service | ⏳ built, disabled, needs wiring |
| Real CAN bus (listen-only) | ⏳ built, needs a USB CAN adapter |
| Android screen + touch on HDMI | ⚠️ built, **disabled** (guest freezes with software rendering) |
| Sound in dom0 (onboard USB codec) | ✅ detected as ALSA card 0 |

### 2.3 What you see on the console

```
(XEN) Xen version 4.16.1 (arjune@) (arm-poky-linux-gnueabi-gcc (GCC) 11.5.0) debug=n Sun Oct 25 09:43:12 UTC 2026
(XEN) Using PSCI v1.0
(XEN) Using scheduler: SMP Credit Scheduler rev2 (credit2)
(XEN) Brought up 4 CPUs
[    0.000000] Linux version 5.15.201-yocto-standard ...
[    0.000000] OF: fdt: Machine model: Rockchip RK3288 Asus Tinker Board
[    0.000000] Xen 4.16 support found
Starting hardware watchdog keep-alive (/dev/watchdog, every 5s)
Setting up bridge xenbr0 (192.168.100.1/24)
Starting Xen guest rtos1
Starting Xen guest android1
Starting vehicle bench on vcan0 (simulated vehicle)
Starting cluster-hdmi (waits for /dev/fb0, i.e. an HDMI monitor)

Poky (Yocto Project Reference Distro) 4.0.35 tinker-board /dev/hvc0

tinker-board login:
```

```
root@tinker-board:~# xl list
Name                                        ID   Mem VCPUs	State	Time(s)
Domain-0                                     0   512     1     r-----     423.3
rtos1                                        1    16     1     -b----       8.9
android1                                     2   767     2     r-----     458.9
```

FreeRTOS reports (from `xl console rtos1` or `/var/log/xen/console/guest-rtos1.log`):

```
[rtos] 10 ms task: 1000 periods, min 9958 us, max 10040 us; heartbeats 469, queue messages 186 (report 47)
[vehicle] 10s: frames 1000, lost 0, bad 0, max gap 25000 us,  speed 135 km/h, rpm 4590; alerts: overspeed 8, redline 15, signal lost 23
[vehicle] ALERT engine over redline: 6293 rpm (limit 6000)
[vehicle] redline cleared: 5694 rpm
```

### 2.4 Expected HDMI output

With a monitor plugged in, `cluster-hdmi` starts by itself and draws the instrument cluster:
speed in km/h, rpm (with a bar), gear, and four lamps – OVERSPEED, REDLINE, SIGNAL, RTOS – driven by
the FreeRTOS verdicts, plus a status line. Snapshot taken **on the board** (RAM framebuffer, no
monitor connected): 135 km/h, OVERSPEED red, SIGNAL and RTOS green.

![Dashboard snapshot from the board](images/cluster-dashboard-board.png)

Android itself is headless (no picture on HDMI), see Section 14.

### 2.5 Measured boot time and resources (2026-11-04)

Image `20261104074956`, board running dom0 + rtos1 + media1 with media1 playing the default clip.

**Method.** Boot: `reboot` in dom0 while arjune timestamped every UART line (`$EPOCHREALTIME`, t = 0
at the first U-Boot TPL line); media1 milestones from `/var/log/boot` and `/var/log/xen-guests.log`
(1 s resolution), aligned on "Starting Xen guest media1". CPU: difference of `xl list` Time(s) over
10 s (100 % = one core). Memory: `xl list`, `free` in dom0 and media1 (media1 through
`xl console` in tmux), rtos1 shell `tasks`. Storage: `/proc/partitions`, `df`, bmap of the image.

Boot milestones (seconds after reset):

| t (s) | Event (UART unless noted) |
|---|---|
| 0.00 | `U-Boot TPL 2022.01` |
| 0.67 | U-Boot proper (autoboot countdown 2 s, then loads xen, zImage, dtb from p6) |
| 17.53 | `Xen 4.16` |
| 20.45 | dom0 `Booting Linux` |
| 23.94 | `Run /sbin/init` |
| 37.30 | `Starting Xen guest rtos1` (TFT init ≈ 0.45 s of delays + ≈ 0.15 s full-screen fill at 8.25 MHz) |
| 38.08 | `Starting Xen guest media1` |
| 42.07 | `Starting display-map: hdmi=vnc:5901` |
| 42.64 | `root@tinker-board:~#` (autologin) |
| ≈ 46 | media1 start broken (`udevd ... terminated by signal 11`), restart 1/3 (`xen-guests.log`) |
| ≈ 61 | `media1 started properly after 1 restart(s)` (login prompt + ping) |

A clean media1 start takes ≈ 13–15 s from `xl create` to ready (login, network, `media-player`),
i.e. ≈ 53 s after reset; with one restart ≈ 61 s.

Resources:

| | Xen | dom0 | rtos1 | media1 |
|---|---|---|---|---|
| vCPUs / pCPUs | 4 × Cortex-A17, 500 MHz | 1 vCPU, Pool-0 (CPUs 0–2) | 1 vCPU, pool `rt` (CPU 3) | 2 vCPUs, `cpus="0-2"`, Pool-0 |
| Scheduler | – | credit2 | RTDS period 1000 µs, budget 1000 µs | credit2 |
| CPU use (10 s) | – | 88 % (guest-vnc 50 %, QEMU media1 17 %, vif/stub_tx) | 12 % | 107 % (ffmpeg software decode) |
| Memory assigned | 2048 MB total, 1353 MB free, ≈ 180 MB Xen + reserved | 320 MB (`dom0_mem=320M`) | 4 MB | 191 MB (`memory = 192`) |
| Memory seen / used | – | 283 MB / 44–96 MB + ≈ 40 MB cache | heap 65536 B, 49032 B free (16504 B used) | 166 MB / 45–73 MB + ≈ 20 MB cache |
| Storage | p6 `boot` 48 MB: `xen` 917560 B, `zImage` 10.0 MB, dtb 40884 B, 10.9 MB used | p7 `root` 145 MB, 54.6 MB used (44 %) | `/var/lib/xen/rtos1/freertos-xen-guest.bin` 27828 B (in p7) | p8 `media-root` 122 MB, 40.7 MB used (40 %) |
| Build output | `xen-tinker-board` 0.9 MB | rootfs 60 MB (files), kernel 10.0 MB | 27.8 KB | `media-guest-image…ext4` 122.5 MB (44 MB of files); kernel shared with dom0 |

Card: SC16G, 14.8 GiB, p1–p5 (loader, U-Boot, reserved) ≈ 16 MB. Image
`tinker-xen-test-image-tinker-board-20261104074956.rootfs.wic` 331.5 MB, bmap 29849 of 84876
4-KiB blocks mapped (116.6 MB written by `bmaptool`).

---

## 3. Hardware and host setup

### 3.1 Hardware

| Item | Detail |
|---|---|
| Board | ASUS Tinker Board R2.0, RK3288W (U-Boot reports it; the CRU node is renamed `rockchip,rk3288w-cru`) |
| Boot medium | micro-SD card, 32 GB (29.7 GiB). U-Boot sees it as `mmc 1`; Linux as `mmcblk0`/`mmcblk1` |
| Serial adapter | CP210x USB-UART, 3.3 V, appears as `/dev/ttyUSB0` on the PC |
| Power | 5 V / 3 A recommended (two unexplained silent hangs under full load, see Section 14) |
| Optional | HDMI monitor, Ethernet cable, USB CAN adapter (gs_usb/candleLight, PEAK, slcan), ACC wiring for ignition |

### 3.2 Serial console wiring (the important one)

The console is **UART2**, not UART1. Pins 8/10 are UART1 and were the first, wrong guess (board →
PC worked, PC → board did not).

```
  Tinker Board 40-pin header                 USB-UART adapter (3.3 V!)
  ────────────────────────────               ─────────────────────────
  pin 32  UART2 TX  (GPIO7_C7)  ───────────►  RX
  pin 33  UART2 RX  (GPIO7_C6)  ◄───────────  TX
  pin 34  GND                   ────────────  GND
```

Terminal: `picocom -b 115200 /dev/ttyUSB0` (or minicom), 115200 8N1, no flow control.
Under Xen this one UART is shared: Xen prints `(XEN) ...`, dom0 logs in on `hvc0`, and
`Ctrl-a` three times switches the input between Xen and dom0.

### 3.3 Host PC

Ubuntu, kernel 6.8, user `arjune` (groups `dialout`, `sudo`). Yocto build directory
`~/xen-hypervisor/build`, ~65 GB free at the start. Tools: `bmaptool`, `picocom`, Python 3 with
`pyserial` (used for all automated board tests over the UART).

---

## 4. Software stack

### 4.1 Versions

| Layer / component | Version / commit | Source |
|---|---|---|
| poky | kirkstone, `445a622392` | git.yoctoproject.org |
| meta-openembedded | kirkstone, `ce8539c941` (meta-oe, meta-networking, meta-python, meta-filesystems) | |
| meta-virtualization | kirkstone, `92b6abcd` (Xen 4.16) | |
| meta-arm | kirkstone, `c3e9fb12` (toolchain) | |
| meta-rockchip | kirkstone, `1e27f83` (MACHINE `tinker-board`) | |
| **meta-tinker-xen** | this project (priority 10) | `~/xen-hypervisor/meta-tinker-xen` |
| U-Boot | 2022.01, `tinker-rk3288_defconfig` + 2 patches | |
| Xen | 4.16.1 stable `f265444922` + 5 patches, release config | |
| dom0 kernel | linux-yocto 5.15.201, `multi_v7_defconfig` + 1 patch + 3 fragments | |
| Android guest kernel | Linux 4.14.336 LTS + 3 patches + `android-guest.cfg` | kernel.org |
| Android user space | AOSP 7.0 `sdk_phone_armv7-userdebug` NYC 3245079 (`armeabi-v7a-24_r07.zip`) | dl.google.com |
| FreeRTOS | FreeRTOS-Kernel V11.1.0 `dbf70559`, ARM_CA9 GCC port | github.com/FreeRTOS |
| Toolchain | GCC 11.5.0, binutils 2.38 | Yocto |
| Init system | SysVinit + BusyBox 1.35 | Yocto |

### 4.2 Stack diagram

```
 ┌─────────────────────────────── user space ───────────────────────────────┐
 │ dom0 (Yocto Linux 5.15)            │ android1             │ rtos1        │
 │  xl, xenstored, xenconsoled        │  init, zygote,       │  FreeRTOS    │
 │  QEMU (device model, off)          │  system_server,      │  tasks:      │
 │  adb, iptables, bridge-utils       │  surfaceflinger,     │   rt10ms     │
 │  vehicle-sim, can2rtos             │  adbd (TCP 5555)     │   vehicle    │
 │  cluster-hdmi, android-hdmi(off)   │                      │   heartbeat  │
 │  hw-watchdog, ignition-watch(off)  │                      │   producer/  │
 │  can-utils, alsa-utils, libgpiod   │                      │   consumer   │
 ├────────────────────────────────────┼──────────────────────┼──────────────┤
 │ Linux 5.15 kernel: Xen backends    │ Linux 4.14 kernel:   │ startup.S,   │
 │ (blkback, netback, gntdev), bridge,│ Xen frontends (blk,  │ vGIC, virtual│
 │ vcan/gs_usb/peak/slcan, dw_wdt,    │ net, console, fb,    │ timer, PV    │
 │ rockchip drm/hdmi, snd-usb-audio   │ kbd), binder 32-bit  │ console ring │
 ├────────────────────────────────────┴──────────────────────┴──────────────┤
 │ Xen 4.16.1 (EL2 / HYP): credit2 Pool-0 (CPU 0-2), RTDS pool "rt" (CPU 3), │
 │ vGICv2, event channels, grant tables, RK3288 platform (reset)            │
 ├──────────────────────────────────────────────────────────────────────────┤
 │ U-Boot 2022.01: non-secure HYP entry, SoC opened to non-secure,          │
 │ resident PSCI 1.0 monitor (CPU_ON/OFF, SYSTEM_RESET) in reserved RAM     │
 ├──────────────────────────────────────────────────────────────────────────┤
 │ RK3288 boot ROM → TPL/SPL (idbloader, SD sector 64)                       │
 └──────────────────────────────────────────────────────────────────────────┘
```

---

## 5. System architecture

### 5.1 CPU and scheduler layout

```
          pCPU 0          pCPU 1          pCPU 2       │      pCPU 3
   ┌───────────────────────────────────────────────┐   │ ┌──────────────────┐
   │ cpupool "Pool-0", scheduler credit2           │   │ │ cpupool "rt",    │
   │                                               │   │ │ scheduler RTDS   │
   │  Domain-0 (1 vCPU)   android1 (2 vCPUs)       │   │ │  rtos1 (1 vCPU)  │
   │                                               │   │ │  period 1000 µs  │
   └───────────────────────────────────────────────┘   │ │  budget  200 µs  │
                                                        │ │  extratime yes   │
                                                        │ └──────────────────┘
```

Why the split: RTDS on all 4 CPUs crashed Xen 4.16 (Section 8, Stage 13 and Stage 26). Credit2 is
better for general-purpose loads; RTDS gives the RTOS a guaranteed reservation on a CPU nobody else
uses. `rtos1-start` creates the pool at boot:

```
xl cpupool-cpu-remove Pool-0 3
xl cpupool-create 'name="rt"' 'sched="rtds"' 'cpus="3"'
xl create /etc/xen/rtos1.cfg                    # pool = "rt"
xl sched-rtds -d rtos1 -v all -p 1000 -b 200 -e 1
```

### 5.2 Boot flow

```
 power on
   │
   ▼
 RK3288 boot ROM ── reads SD sector 64 ──► TPL (DDR init) ► SPL ► U-Boot proper (sector 16384)
                                                                   │
                       distro_bootcmd scans mmc 1:6 (FAT "boot")   │
                       no /extlinux/extlinux.conf → /boot.scr ◄────┘
                                                   │
 boot.scr (= xen-boot.cmd):                        ▼
   setenv bootm_boot_mode nonsec                   load /rk3288-tinker.dtb, /xen, /zImage
   fdt: DMAC → non-secure, rsvmem U-Boot area, rm cpu-thermal cooling-maps,
        /chosen xen,xen-bootargs + module@4000000 (dom0 zImage + bootargs)
   bootz ${xen_addr} - ${fdt_addr_r}
                                                   │
 U-Boot armv7 nonsec switch:                       ▼
   psci_board_init(): SGRF/TZPC → non-secure, power off CPU 1-3
   install PSCI monitor (secure, reserved RAM), add /psci to DT
   SCR.NS=1, HSCTLR=0x30c50830, ERET to HYP ────► Xen 4.16 (HYP mode)
                                                     │  PSCI CPU_ON ×3 → 4 CPUs
                                                     │  RK3288 platform, credit2
                                                     ▼
                                                   dom0 Linux 5.15 (console hvc0)
                                                     │ SysVinit rc5.d:
                                                     │  S05 hw-watchdog
                                                     │  S79 xenbr0 (bridge + NAT)
                                                     │  S80 xencommons (xenstored, xenconsoled)
                                                     │  S90 xen-guests → rtos1-start, xl create android1
                                                     │  S92 vehicle-bench (vcan0, vehicle-sim, can2rtos)
                                                     │  S93 cluster-hdmi (waits for /dev/fb0)
                                                     │  S94 ignition-watch (ENABLED=0 → exits)
                                                     ▼
                                                   login: on hvc0

 If /xen is missing or bootz returns → boot.scr runs
   sysboot mmc 1:6 any ${scriptaddr} /native/extlinux.conf   (Linux without Xen)
```

### 5.3 Memory and address map (important values)

| What | Address / value |
|---|---|
| DDR | 2 GiB at 0x00000000 |
| Xen load address (`xen_addr`) | 0x02000000 |
| dom0 zImage (`dom0_addr`, `/chosen/module@4000000`) | 0x04000000 |
| U-Boot reserved area (kept from Xen with `fdt rsvmem`) | 0x79e00000 – 0x7fffffff |
| GIC-400 | 0xffc00000 (GICD +0x1000, GICC +0x2000) |
| UART2 (console) | 0xff690000, reg-shift 2 |
| CRU (clock/reset) | 0xff760000; GLB_SRST_FST at +0x1b0, value 0xfdb9 |
| PMU | 0xff730000 (PWRDN_CON +0x08, PWRDN_ST +0x0c) |
| Boot ROM mailbox (SRAM) | 0xff700000: +4 magic 0xdeadbeaf, +8 entry address |
| SGRF / TZPC | 0xff740000 / 0xffb00000 |
| Bus DMAC | secure 0xffb20000 → non-secure 0xff600000 |
| FreeRTOS guest RAM | 0x40000000, 16 MB; entry 0x40008000 |
| Guest vGIC | GICD 0x03001000, GICC 0x03002000; virtual timer PPI 27 |
| Arch timer | 24 MHz (CNTFRQ 0x016e3600), driven by RK3288 timer7 |

### 5.4 Network

```
              PC / LAN (optional, eth0 DHCP)
                       │
           ┌───────────┴─────────────────────────────────────────┐
           │ dom0  eth0 ── routing + iptables MASQUERADE ──┐      │
           │                                               │      │
           │              xenbr0 192.168.100.1/24 ◄────────┘      │
           │                │                                     │
           │             vif2.0                                   │
           └────────────────┼─────────────────────────────────────┘
                            │ (Xen netfront/netback)
                     android1 eth0 192.168.100.3
                     default route via 192.168.100.1, DNS 8.8.8.8 / 1.1.1.1
                     adbd TCP 5555  ◄── "adb connect 192.168.100.3:5555" from dom0
```

### 5.5 Automotive data flow

```
 ┌──────────── dom0 (Linux) ───────────────────────────────────────────────┐
 │                                                                          │
 │ vehicle-sim ──CAN 0x0C0 speed, 0x0C1 rpm, every 10 ms──► vcan0           │
 │ (or a real car bus: can0 in LISTEN-ONLY mode, SIM=0)        │            │
 │                                                             ├──► cluster-hdmi ─► /dev/fb0 (HDMI)
 │                                         can2rtos (CAN_RAW,  │       ▲
 │                                         receive only) ◄─────┘       │ reads verdicts
 │                                              │                       │
 │                       "V <seq> <speed> <rpm>\n" into rtos1's        /var/log/xen/console/
 │                        console pty (from xenstore)                   guest-rtos1.log
 │                                              │                       ▲
 │                                         xenconsoled ────────────────┘ (XENCONSOLED_TRACE=guest)
 └──────────────────────────────────────────────┼───────────────────────────┘
                                                │ shared ring page + event channel
 ┌──────────── rtos1 (FreeRTOS, pCPU 3, RTDS) ──▼───────────────────────────┐
 │ vVehicleTask every 5 ms: parse frames, count lost/bad, max gap,          │
 │   ALERT overspeed  > 120 km/h (clear < 115)                              │
 │   ALERT redline    > 6000 rpm (clear < 5700)                             │
 │   SIGNAL LOST      no frame for 100 ms (fail-safe: data marked invalid)  │
 │   10 s report                                                            │
 │ vRealTimeTask every 10 ms: measures its own period (min/max µs)          │
 └──────────────────────────────────────────────────────────────────────────┘
```

Safety principle: nothing in this system ever transmits on a vehicle bus. `can2rtos` only receives;
a real interface is configured `listen-only on`, so the controller does not even send ACK bits.

---

## 6. Directory trees

### 6.1 Project directory

```
~/xen-hypervisor/
├── poky/                     Yocto core (kirkstone)
├── meta-openembedded/        meta-oe, meta-networking, meta-python, meta-filesystems
├── meta-virtualization/      Xen recipes
├── meta-arm/                 toolchain
├── meta-rockchip/            MACHINE tinker-board, rockchip.wks
├── meta-tinker-xen/          ★ THIS PROJECT'S LAYER (all changes live here)
├── build/
│   ├── conf/local.conf       MACHINE = "tinker-board", DISTRO_FEATURES += "virtualization xen"
│   ├── conf/bblayers.conf    (backup: bblayers.conf.pre-meta-tinker-xen)
│   └── tmp/deploy/images/tinker-board/
│       ├── tinker-xen-test-image-tinker-board.wic(.bmap)   → card image
│       ├── xen-tinker-board                                → Xen binary
│       ├── zImage, rk3288-tinker.dtb, u-boot.*, idbloader.img
│       ├── android-system.img, android-userdata.img
│       └── freertos-xen-guest.bin/.elf, android-guest-zImage
├── diagnostics/              REPORT.md (A–Z), BOARD-TESTS.md, uart-*.log, bitbake-*.log,
│   └── baseline/             known-good original image + original U-Boot binaries
└── docs/
    ├── DOCUMENTATION.md           (this file)
    └── images/cluster-dashboard-board.png
```

### 6.2 The layer `meta-tinker-xen`

```
meta-tinker-xen/
├── conf/layer.conf                       priority 10, LAYERSERIES_COMPAT kirkstone
├── COPYING.MIT
├── README                                usage, recipes, limitations, recovery
├── wic/
│   └── tinker-xen.wks                    card layout (no extlinux; android partitions)
├── recipes-bsp/
│   ├── u-boot/
│   │   ├── u-boot_2022.01.bbappend
│   │   └── files/
│   │       ├── 0001-rockchip-rk3288-allow-booting-in-non-secure-HYP-mode.patch
│   │       └── 0002-rockchip-rk3288-add-PSCI-to-start-the-secondary-CPUs.patch
│   └── xen-boot-script/
│       ├── xen-boot-script.bb            mkimage → xen-boot.scr (= /boot.scr)
│       └── files/{xen-boot.cmd, native-extlinux.conf}
├── recipes-extended/
│   ├── xen/
│   │   ├── xen_4.16.bbappend             patches + release/debug config fragment
│   │   ├── xen-tools_4.16.bbappend       guest console logs (XENCONSOLED_TRACE)
│   │   └── files/
│   │       ├── 0001-xen-arm32-add-Cortex-A12-and-Cortex-A17-processor-info.patch
│   │       ├── 0002-xen-arm32-emulate-L2CTLR-for-guests.patch
│   │       ├── 0003-xen-arm-add-Rockchip-RK3288-platform-with-reset.patch
│   │       ├── 0004-xen-sched-fix-race-in-RTDS-scheduler.patch            (upstream backport)
│   │       ├── 0005-xen-sched-try-harder-to-find-a-runnable-unit-in-rt_schedule.patch (backport)
│   │       ├── tinker-rk3288-release.cfg
│   │       └── tinker-rk3288-early-printk.cfg
│   ├── xenbr0/                           bridge 192.168.100.1/24 + NAT (S79)
│   ├── xen-guests/                       guest autostart (S90/K10), hw-watchdog (S05), USB hub udev rule
│   ├── vehicle-bench/                    vehicle-sim.c, can2rtos.c, vehicle-bench.init (S92)
│   ├── cluster-hdmi/                     cluster-hdmi.c (dashboard), init (S93)
│   ├── ignition-watch/                   ACC → clean poweroff (S94, disabled)
│   └── android-hdmi/                     VNC client for Android's PV screen (disabled)
├── recipes-kernel/linux/
│   ├── linux-yocto_5.15.bbappend
│   └── files/
│       ├── 0001-ARM-rockchip-rk3288-keep-timer7-running-if-already-started.patch
│       ├── xen-dom0-bridge.cfg           CONFIG_BRIDGE=y
│       ├── xen-dom0-display.cfg          CONFIG_FB_VIRTUAL=m
│       └── xen-dom0-can.cfg              vcan, gs_usb, peak_usb, slcan
├── recipes-rtos/freertos-xen-guest/
│   ├── freertos-xen-guest.bb
│   └── files/{startup.S, guest.ld, main.c, FreeRTOSConfig.h, Makefile, rtos1.cfg, rtos1-start}
├── recipes-android/
│   ├── linux-android-guest/              Linux 4.14.336 guest kernel
│   │   ├── linux-android-guest_4.14.336.bb
│   │   └── files/{android-guest.cfg, 0001-timerfd..., 0002-xen-kbdfront..., 0003-xen-fbfront...}
│   └── android-guest/                    AOSP 7.0 image adapted to Xen
│       ├── android-guest.bb
│       └── files/{android1.cfg, init.xen.rc, fstab.xen, xen-net.sh}
├── recipes-core/
│   ├── images/tinker-xen-test-image.bb   the image
│   └── sysvinit/                         no getty on the Xen-owned UART
└── recipes-devtools/qemu/qemu_%.bbappend QEMU only as Xen device model (i386 target)
```

### 6.3 SD card layout (`tinker-xen.wks`, GPT)

```
 sector    size     partition            content
 ───────── ──────── ──────────────────── ──────────────────────────────────────────
        64   3.9 MB p1 loader1           TPL/SPL (idbloader.img)
      8064    64 KB p2 reserved1
      8192     4 MB p3 reserved2
     16384     4 MB p4 loader2           U-Boot 2022.01 with HYP + PSCI patches
     24576     4 MB p5 atf               (unused)
     32768   146 MB p6 boot (FAT, active)  /xen  /zImage  /rk3288-tinker.dtb
                                           /boot.scr  /xen-boot.scr  /native/extlinux.conf
    330956   571 MB p7 root (ext4)        dom0 root filesystem
   1499410   1.8 GB p8 android-system     Android /system  (xvda of android1, read-only)
   5169426   550 MB p9 android-data       Android /data    (xvdb of android1)
```

### 6.4 Important files on the running board (dom0)

```
/boot/                         (= SD p6) xen, zImage, rk3288-tinker.dtb, boot.scr
/etc/xen/rtos1.cfg             FreeRTOS guest config (pool "rt")
/etc/xen/android1.cfg          Android guest config
/var/lib/xen/rtos1/freertos-xen-guest.bin
/var/lib/xen/android/{zImage, ramdisk.img}
/usr/sbin/rtos1-start          creates cpupool rt, starts rtos1, sets RTDS budget
/usr/bin/{vehicle-sim, can2rtos, cluster-hdmi, android-hdmi}
/usr/sbin/ignition-watch
/etc/init.d/{hw-watchdog, xenbr0, xencommons, xen-guests, vehicle-bench, cluster-hdmi, ignition-watch, android-hdmi}
/etc/default/{xen-guests, vehicle-bench, ignition-watch, xencommons}
/etc/udev/rules.d/50-tinker-usb-hub.rules
/var/log/xen/console/guest-rtos1.log, guest-android1.log
/var/log/{vehicle-bench.log, cluster-hdmi.log, ignition-watch.log}
```

---

## 7. Build environment setup

### 7.1 Steps (from an empty directory)

`./sync.sh` automates this: it clones each layer at the commit pinned inside the script and
writes `build/conf/local.conf` and `bblayers.conf`. `./sync.sh --check` verifies the pins.
The manual equivalent:

```bash
mkdir ~/xen-hypervisor && cd ~/xen-hypervisor
git clone -b kirkstone git://git.yoctoproject.org/poky
git clone -b kirkstone https://github.com/openembedded/meta-openembedded
git clone -b kirkstone git://git.yoctoproject.org/meta-virtualization
git clone -b kirkstone git://git.yoctoproject.org/meta-arm
git clone -b kirkstone git://git.yoctoproject.org/meta-rockchip
# meta-tinker-xen: copy this project's layer here

source poky/oe-init-build-env build
bitbake-layers add-layer ../meta-openembedded/meta-oe
bitbake-layers add-layer ../meta-arm/meta-arm-toolchain ../meta-arm/meta-arm
bitbake-layers add-layer ../meta-rockchip
bitbake-layers add-layer ../meta-openembedded/meta-filesystems
bitbake-layers add-layer ../meta-openembedded/meta-python
bitbake-layers add-layer ../meta-openembedded/meta-networking
bitbake-layers add-layer ../meta-virtualization
bitbake-layers add-layer ../meta-tinker-xen
```

### 7.2 `build/conf/local.conf` (non-default lines)

```
MACHINE = "tinker-board"
DISTRO_FEATURES:append = " virtualization xen"
```

Optional: `XEN_TINKER_DEBUG = "1"` builds the debug Xen (asserts, early printk on UART2, guest
CONSOLEIO output).

### 7.3 `build/conf/bblayers.conf` (result)

```
BBLAYERS ?= " \
  /home/arjune/xen-hypervisor/poky/meta \
  /home/arjune/xen-hypervisor/poky/meta-poky \
  /home/arjune/xen-hypervisor/poky/meta-yocto-bsp \
  /home/arjune/xen-hypervisor/meta-openembedded/meta-oe \
  /home/arjune/xen-hypervisor/meta-arm/meta-arm-toolchain \
  /home/arjune/xen-hypervisor/meta-arm/meta-arm \
  /home/arjune/xen-hypervisor/meta-rockchip \
  /home/arjune/xen-hypervisor/meta-openembedded/meta-filesystems \
  /home/arjune/xen-hypervisor/meta-openembedded/meta-python \
  /home/arjune/xen-hypervisor/meta-openembedded/meta-networking \
  /home/arjune/xen-hypervisor/meta-virtualization \
  /home/arjune/xen-hypervisor/meta-tinker-xen \
  "
```

### 7.4 Build

```bash
cd ~/xen-hypervisor && source poky/oe-init-build-env build
bitbake tinker-xen-test-image
```

Expected end of the output (exit code 0):

```
NOTE: Tasks Summary: Attempted 4354 tasks of which 4257 didn't need to be rerun and all succeeded.
```

Single recipes can be rebuilt on their own, e.g. `bitbake xen`, `bitbake u-boot`,
`bitbake freertos-xen-guest`, `bitbake vehicle-bench`. The first full build takes several hours and
downloads the Android SDK system image (~400 MB) and kernel sources.

> Note (side effect seen on day 1): enabling `DISTRO_FEATURES xen` together with meta-virtualization
> adds kernel fragments (xen.scc, docker.scc, lxc.scc, vswitch.scc, …) to linux-yocto. The kernel grew
> from 10,002,944 to 10,379,776 bytes. This is expected and harmless.

---

## 8. Project history, stage by stage

Each stage: **goal → what was done → errors seen → cause → fix → result → evidence**. The letters in
brackets are the matching sections of `diagnostics/REPORT.md`.

### Stage 1 – Baseline inventory (A) – 2026-10-23

- **Goal:** know exactly what exists before changing anything.
- **Done:** recorded layer versions, MACHINE, kernel, U-Boot, Xen and WKS (table in Section 4.1);
  saved the known-good image to `diagnostics/baseline/`:
  `core-image-minimal-tinker-board-20261022043621.rootfs.wic`,
  sha256 `d9cdb9a5127b7d0bbd1151fc6430331c84a9b525d49f6f90653af40092598702`, bmap verified
  (12 ranges, 0 mismatches).
- **Rule set:** all changes go into a new layer; nothing in poky/meta-rockchip/meta-virtualization
  is edited.

### Stage 2 – The "Linux freeze" after `mmcblk0: p1 … p9` (B, H)

- **Symptom (user's log):** boot stopped right after `mmcblk0: p1 p2 p3 p4 p5 p6 p7 p8 p9`.
- **Analysis:** the Yocto image has **7** partitions and U-Boot **2022.01**; the log showed **9**
  partitions and U-Boot **2024.01**. So the card was not this Yocto image.
- **Found later on the board:** the card held another build (Poky 5.0.21 scarthgap, kernel 6.6,
  Xen 4.18.1-pre, U-Boot 2024.01 with NS-HYP patches) whose own notes documented a dom0 hang ~2 s
  into boot. That hang was found and fixed in Stage 8 (timer7).
- **Fix:** flash the real Yocto image. The card was erased at the user's request without a backup.

### Stage 3 – Xen prerequisites check (C)

| Requirement | Finding |
|---|---|
| CPU virtualization extensions | Cortex-A17 has them |
| Xen must be entered in non-secure HYP mode | **Blocker**: U-Boot for RK3288 had no NONSEC/VIRT (only LS1021A, sunxi, tegra124, exynos, mx7, stm32mp) |
| SMP under Xen | needs PSCI; RK3288 DT uses `rockchip,rk3066-smp` → CPU0 only |
| GIC-400 with GICH/GICV | OK |
| Arch timer 24 MHz | OK (`arm,cpu-registers-not-fw-configured`) |
| Xen console on UART2 | OK (ns16550 matches `snps,dw-apb-uart`) |
| Xen image format | ARM32 Xen has a zImage header; boot with `bootz` |

### Stage 4 – First test image and a debug Xen (D, E, F/G)

- **Done:** created `meta-tinker-xen`; `xen_4.16.bbappend` with
  `tinker-rk3288-early-printk.cfg` (`CONFIG_DEBUG=y`, early UART 8250 at 0xff690000, reg-shift 2)
  so Xen failures become visible; new image `tinker-xen-test-image` (copy of core-image-minimal +
  `/xen`), so the known-good image is never overwritten.
- **Build:** `bitbake xen` and `bitbake tinker-xen-test-image`: exit 0, 0 warnings.

### Stage 5 – First hardware run (H) – UART wiring and the confirmed blocker

- **Error 1:** board → PC text visible, but typing did nothing. **Cause:** adapter TX wired to pin 10
  (UART1). **Fix:** use UART2: pins 32 (TX), 33 (RX), 34 (GND).
- **Result:** Linux 5.15 login, 4 CPUs, 2005 MB, and the key line:

  ```
  CPU: All CPU(s) started in SVC mode.
  ```
  (secure SVC mode, not HYP → confirms the blocker).
- **Xen attempt from RAM (U-Boot prompt):**

  ```
  - Xen must be entered in NS Hyp mode -
  - Please update the bootloader -
  - Boot failed -
  ```
- Also learned: the SD card is `mmc 1` in U-Boot; U-Boot reserves 0x79f801f8–0x7fffffff.

### Stage 6 – U-Boot non-secure HYP port (I)

- **Goal:** U-Boot hands over to Xen in non-secure HYP mode.
- **Done (U-Boot patch 0001):** RK3288 selects `CPU_V7_HAS_NONSEC`/`CPU_V7_HAS_VIRT`; GIC base
  0xffc00000; `psci_board_init()` opens the SoC to the non-secure world (as the RK3288 TF-A port
  does); empty SMP hooks; **secure boot stays the default**, `bootm_boot_mode=nonsec` is only set by
  the Xen boot script. Original binaries kept in `baseline/*.2022.01-orig`.
- **Boot script:** `xen-boot.scr` (loads Xen + dom0, builds `/chosen`).

### Stage 7 – Getting Xen and dom0 to boot (J) – six problems in a row

| # | Symptom on the UART | Cause (evidence) | Fix |
|---|---|---|---|
| 1 | `Xen must be entered in NS Hyp mode` | no NONSEC/VIRT in RK3288 U-Boot | U-Boot 0001 |
| 2 | Silent hang after `Starting kernel ...` | HSCTLR reset value 0x70cd087f (MMU + Thumb exceptions on); debug markers stopped at "E" | U-Boot 0001: write HSCTLR = 0x30c50830 before ERET |
| 3 | (non-secure access faults) | SoC peripherals still secure-only | U-Boot 0001: SGRF/TZPC setup in `psci_board_init()` |
| 4 | `Missing processor info: 410fc0d1` | Xen had no Cortex-A12/A17 proc_info (also missing upstream) | Xen 0001 |
| 5 | dom0 Oops in `rk3288_suspend_init` | L2CTLR read traps (HCR.TIDCP), Xen injected UNDEF | Xen 0002: emulate L2CTLR like KVM |
| 6 | dom0 abort at 0xffb23fe0 | secure bus-DMAC window used from non-secure | boot script: `fdt set /dma-controller@ffb20000 reg <0x0 0xff600000 0x0 0x4000>` |

### Stage 8 – The famous "~2 s dom0 hang" (J)

- **Symptom:** dom0 always stopped ~2 s into boot (around the GMAC PHY reset).
- **Evidence:** Xen debug dump: vCPU idle, `NOW=-6148914817469028622` (Xen's time negative).
- **Cause:** Linux's `rockchip_timer_init()` stops and reloads **timer7**, which drives the ARM
  architected counter. The counter jumped back to zero under Xen → Xen's timers never fired.
- **Fix:** dom0 kernel patch 0001 – keep timer7 if it is already running (U-Boot starts it).
- **Result:** `/sys/hypervisor/type` = `xen`, dom0 login on hvc0, 483 MB, 1 vCPU
  (`uart-xen-card.log`, image `…20261023155925`).

### Stage 9 – First guest domain (K) – 2026-10-24

- **Done:** xen-tools (xl, xenstored, xenconsoled), backend modules, a BusyBox guest `guest1`.
- **Output:** `xl info` → xen_version 4.16.1, total_memory 2048; `xl list` → Domain-0 512 MB +
  guest1 127 MB; guest: `Machine model: XENVM-4.16`.
- **Seen once:** board reset (`Reset cause: POR`) exactly at `xl create`; not reproducible;
  likely a power dip → use 5 V / 3 A.
- Harmless: `qemu-xen is unavailable`.

### Stage 10 – Guest networking (L)

- **Done:** `CONFIG_BRIDGE=y` (dom0 fragment), `xenbr0` init script (192.168.100.1/24),
  `vif = ['bridge=xenbr0']`.
- **Result:** guest 192.168.100.2; ping both ways 4/4, ~0.66 ms.
- Harmless messages: `gnttab_mark_dirty not implemented yet`,
  `INIT: Id "S2" respawning too fast` (fixed later in Stage 19).

### Stage 11 – FreeRTOS as a Xen guest (M)

- **Why FreeRTOS:** Zephyr's Xen board (xenvm) is AArch64 only; this is a 32-bit system.
- **Design:** ARM32 zImage header (magic 0x016f2818, entry 0x40008000), vGICv2 at
  0x03001000/0x03002000, 1 kHz tick from the virtual timer (PPI 27) with **absolute** CNTV_CVAL,
  identity-mapped MMU with caches, WFI idle hook, console via `CONSOLEIO_write` hypercall (debug Xen).
- **Bugs fixed on the board:**

| Symptom | Cause | Fix |
|---|---|---|
| repeated/stale console lines | MMU off → uncached writes, Xen reads cached | enable MMU + caches |
| period 10.15 ms instead of 10 ms | relative TVAL re-arm adds IRQ latency each tick | absolute `CVAL += period` |
| rtos1 at 100 % CPU, 20 ms spikes | idle task spinning | idle hook executes `WFI` |
| `configASSERT` fails on correct setup | port's GIC priority probe reads 0xFF on Xen's vGIC | `configASSERT` off |

- **Result:** 10 ms task 9.99–10.01 ms (±8 µs) with dom0 idle; up to 19 ms late while a Linux
  guest booted (all on one CPU, credit2).

### Stage 12 – RTDS real-time scheduler (N)

- **Done:** `sched=rtds`, `rtos1-start` gives rtos1 200 µs every 1 ms
  (`xl sched-rtds -d rtos1 -v all -p 1000 -b 200 -e 1`; xl.cfg in 4.16 has no RTDS budget key).

| Situation | credit2 | RTDS defaults | RTDS 200 µs / 1 ms |
|---|---|---|---|
| idle | ±8 µs | ±8 µs | ±10–20 µs |
| Linux guest booting | up to 19.9 ms | up to 18.6 ms | 12.4 ms once, else ≤ ±115 µs |
| dom0 100 % busy | – | ±7 µs | ±4–7 µs |

- **New problem found:** dom0 `reboot` → endless `Xen: Platform reset did not work properly!`.

### Stage 13 – Reboot under Xen (O)

- **Cause:** no PSCI and no RK3288 platform code in Xen 4.16.
- **Fix:** Xen 0003 – new platform `rockchip.c`, `.reset` writes 0xfdb9 to CRU GLB_SRST_FST.
- **Error in the first version:** `rockchip.c:39: Cannot find the RK3288 CRU node in DT`.
  **Cause:** on the RK3288W U-Boot renames the CRU to `rockchip,rk3288w-cru`. **Fix:** match both.
- **Result:** `(XEN) Platform: Rockchip RK3288`; `reboot` → `Reset cause: RST` (a real soft reset).

### Stage 14 – Autoboot Xen from the card (P)

- **Done:** own WKS `tinker-xen.wks` without `loader=u-boot` → no `/extlinux/extlinux.conf`, so
  U-Boot's distro boot runs `/boot.scr` (= xen-boot.scr). `/native/extlinux.conf` keeps Linux without
  Xen. If `bootz` returns, the script falls back to native Linux. **No `saveenv`, U-Boot environment
  untouched.**
- **Tests:** power on → `Found U-Boot script /boot.scr` → Xen → dom0 ✔; reboot → Xen again ✔;
  stop autoboot + `sysboot mmc 1:6 any ${scriptaddr} /native/extlinux.conf` → Linux without Xen ✔.

### Stage 15 – SMP with PSCI (Q)

- **Before:** `Failed to bring up CPU 1 (error -19)` → Xen on 1 CPU.
- **Fix:** U-Boot 0002 – RK3288 selects `ARCH_SUPPORT_PSCI`; new `psci.c` with VERSION, FEATURES,
  CPU_ON, CPU_OFF, AFFINITY_INFO, MIGRATE_INFO_TYPE, SYSTEM_RESET. CPU_ON = core reset + PMU power-up
  + boot ROM mailbox (0xff700000: +8 entry, +4 0xdeadbeaf, `sev`).
- **Error in run 1:** only 2 CPUs; CPU2/3 returned `ALREADY_ON (-4)`. **Cause:** all parked cores
  wait on the same mailbox, so the first CPU_ON released all of them. **Fix:**
  `rk3288_psci_cpus_off()` in `psci_board_init()` powers cores 1–3 off first (as Linux and TF-A do).
- **Safety:** tested by sending U-Boot over the UART (`loady 0x01000000`, `go`) – nothing written to
  the card until it worked.
- **Result:** `(XEN) Using PSCI v1.0`, `Brought up 4 CPUs`, `xl info` nr_cpus 4; reboot via PSCI
  SYSTEM_RESET.

### Stage 16 – Headless Android 7.0 guest (R, T, U)

- **Why 7.0:** the newest ARM32 AOSP images Google publishes; they need the old 32-bit binder ABI
  (`CONFIG_ANDROID_BINDER_IPC_32BIT`), removed in Linux 4.18 → a separate 4.14 guest kernel.
  Building AOSP from source (~250 GB) did not fit the PC.
- **Done:** `linux-android-guest` (4.14.336, Xen frontends, binder 32-bit, ashmem, SELinux, cgroups,
  netfilter, vfb), `android-guest` (SDK image + ramdisk overlay `init.xen.rc`, `fstab.xen`,
  `default.prop`; emulator GLES libs removed, `libGLES_android.so` renamed `libGLES_soft.so`),
  partitions p8/p9 as xvda/xvdb, IP 192.168.100.3, adbd on TCP 5555.
- **Errors and fixes on the board:**

| Run | Error | Cause | Fix |
|---|---|---|---|
| 1 | system_server loop: `F EventHub: Could not register INotify for /dev/input` | no input devices → no /dev/input | `init.xen.rc`: `mkdir /dev/input 0755 root input` |
| 2 | system_server loop: `NullPointerException` in `AlarmManagerService$AlarmHandler` | no /dev/alarm in 4.14; system_server lacks CAP_WAKE_ALARM (added in Android 8) → timerfd alarm clocks -EPERM | guest kernel 0001: allow alarm clocks for gid 1000 |
| 2 | `usb 1-1: reset high-speed USB device` repeating | dom0 adb server wakes the GL850G hub, its resume fails | udev rule: hub `power/control = on` |
| 3 | **Xen panic** `Assertion '!unit_on_replq(svc)' failed at rt.c:587` | RTDS on all 4 CPUs, Xen 4.16 bug (properly fixed in Stage 26) | credit2 Pool-0 + RTDS pool `rt` on CPU 3 |

- **Result (run 4):** `SurfaceFlinger: Boot is finished (100948 ms)`, `sys.boot_completed=1`,
  77 packages, 0 system_server crashes, adb works; rtos1 ±2 µs idle, ≤ ±57 µs while Android boots.

### Stage 17 – Remove the demo guest (S)

On request, `guest1` (`xen-guest-demo`, `tinker-xen-guest-initramfs`) was deleted completely.

### Stage 18 – Quieter FreeRTOS console (V)

Three lines per second made the shared UART unusable for typing. Now one line every 10 s
(`REPORT_PERIODS = 1000`). Live workaround on older cards: `xl debug-keys G` then `xl debug-keys -`
twice.

### Stage 19 – Production hardening (W, X)

| Item | Problem | Fix | Verified |
|---|---|---|---|
| Release Xen | debug Xen slow/noisy; release build dropped RTDS | `tinker-rk3288-release.cfg`: DEBUG off, `EXPERT`, `UNSUPPORTED`, `SCHED_RTDS` on | `debug=n`, 4 CPUs |
| Thermal | dom0 has no physical CPU nodes → cooling maps make TSADC defer forever → no temperature, no HW shutdown | boot script `fdt rm /thermal-zones/cpu-thermal/cooling-maps` | 41.8 °C / 40.0 °C |
| FreeRTOS PV console | CONSOLEIO needs debug Xen | ring page (HVMOP_get_param CONSOLE_PFN/EVTCHN) + EVTCHNOP_send | `xl console rtos1` |
| Android network | no default route / DNS | `xen-net.sh` (route via .1, netd network 60000 + DNS); dom0 ip_forward + MASQUERADE | route OK |
| Android xen-net service | `Service xen-net does not have a SELinux domain defined` | `seclabel u:r:su:s0` | 192.168.100.3 up |
| Watchdog | hung system stays hung | `hw-watchdog` keeps dw_wdt alive every 5 s | reset after 43 s when stopped |
| Guest autostart | manual xl commands | `/etc/init.d/xen-guests` (S90/K10) | autostart after reboot |
| UART getty | `INIT: Id "S2" respawning too fast` | `start_getty`: no getty on ttyS2 under Xen | quiet |

Final verification (X): reboot → guests stopped first, `Reset cause: RST`, Xen with 4 CPUs, guests
autostarted, Android `boot_completed` 76 s after dom0 login, FreeRTOS 9961–10038 µs; poweroff →
`reboot: Power down`.

### Stage 20 – Screen, touch and sound (Y) – experimental, disabled

- **Built:** QEMU as Xen device model (VNC on 127.0.0.1:5900), `android-hdmi` (VNC client → dom0
  /dev/fb0 + touch/mouse/keyboard forwarding), guest kernel 0002 (Xen pointer as touchscreen) and
  0003 (16 bpp fbfront), DRM/HDMI and ALSA in dom0.
- **Errors:**

| Error | Cause | Fix / status |
|---|---|---|
| SurfaceFlinger `no suitable EGLConfig` | 32 bpp xenfb | 0003: 16 bpp RGB565 |
| apps abort in RenderThread `Failed to choose config` | HWUI needs GLES 2.0, only GLES 1.x software renderer | `ro.kernel.qemu=0` turns HWUI off… |
| …but then the guest **freezes 1–2 min after boot** | vCPUs idle in `cpu_v7_do_idle`, virtual timer IRQ 27 stuck active in the list registers | **not solved** |

- **Decision (user, option A):** back to stable headless; screen/touch kept in the layer but off.
- Stability afterwards: 10 min, 0 system_server crashes, FreeRTOS 9961–10038 µs.

### Stage 21 – Automotive bench (Z)

- **Built:** `vehicle-sim` (60 s drive cycle on vcan0), `can2rtos` (receive-only gateway),
  FreeRTOS `vVehicleTask`, CAN modules + can-utils.
- **Results:** ~1000 frames/10 s, 0 lost, 0 bad; overspeed/redline alerts raised and cleared;
  pause → `SIGNAL LOST`, resume → `SIGNAL OK again`; 10 ms task 9970–10029 µs.

### Stage 22 – Instrument-cluster dashboard (Z)

- **Built:** `cluster-hdmi` (framebuffer drawing, built-in 5×7 font, CAN + FreeRTOS verdicts).
- **Error:** RTOS lamp had no data: `/var/log/xen/console` did not exist (xenconsoled does not create
  it; /var/log is volatile). **Fix:** xen-tools bbappend adds the volatile directory and
  `XENCONSOLED_TRACE=guest`.
- **Result:** snapshot on the board (Section 2.4).

### Stage 23 – Frame bursts (Z)

- **Symptom:** FreeRTOS max gap ~105 ms (signal-loss limit 100 ms) while `candump vcan0` showed
  ≤ 29 ms.
- **Cause:** FreeRTOS sent an event-channel notify after **every** console read (up to 200/s);
  xenconsoled rate-limits a guest to `RATE_LIMIT_ALLOWANCE 30` events per `RATE_LIMIT_PERIOD 200` ms
  and then ignores it until the period ends (`tools/console/daemon/io.c`).
- **Fix:** notify only when the input ring was nearly full; `can2rtos` reports its own 10 s timing.
- **Result:** FreeRTOS max gap 20–35 ms, dom0 side 17–33 ms, 0 lost, 0 dropped.

### Stage 24 – Ignition power-off (Z)

`ignition-watch`: reads ACC on header pin 7 (gpiochip0 line 17) with libgpiod; ACC off for 10 s →
`poweroff` (guests stopped first); ACC back on cancels; nothing happens until ACC was seen on once.
Disabled by default. Not tested (nothing wired).

### Stage 25 – Xen panic after flashing (Z)

Right after flashing the image with Stages 21–24, about one minute after boot:

```
(XEN) CPU3: Unexpected Trap: Data Abort
(XEN) ----[ Xen-4.16.1  arm32  debug=n  Not tainted ]----
(XEN) CPU:    3
(XEN) PC:     0023ae60 rt.c#repl_timer_handler+0x1cc/0x2ac
(XEN)      R0: 00100100 R1: 0000000a R2: ffffffff R3: 00000000
(XEN)      HDFAR: 00100138
(XEN) Panic on CPU 3:
(XEN) CPU3: Unexpected Trap: Data Abort
(XEN) Reboot in five seconds...
```

- **Analysis:** `addr2line` on `xen-syms`: `deadline_queue_insert` ← `repl_timer_handler`,
  rt.c:1517. R0 = 0x00100100 = `LIST_POISON1` → a list entry that was already deleted is still linked:
  the RTDS replenishment queue is corrupted. rt.c:587 (the Stage 16 assertion) is
  `ASSERT(!unit_on_replq(svc))` in `replq_insert` → same bug.
- **Root cause** (upstream commit 73c62927f64e, Oct 2022): "When a domain gets paused the unit
  runnable state can change to 'not runnable' without the scheduling lock being involved… RTDS will
  remove the unit from the run queue, but doesn't do so for the replenish queue, leading to hitting
  an ASSERT() in replq_insert() later when the domain is unpaused again." Our Xen 4.16.1 predates it.
- **Reproduced on purpose:** `xl pause rtos1; usleep 3000; xl unpause rtos1` in a loop → same panic
  within 250 rounds (`uart-rtds-repro-old.log`).
- **Fix:** Xen patches 0004 (73c62927f64e) and 0005 (0f1dec89d324, retry `runq_pick`) backported.
- **Mistake during this stage (no damage):** an Enter sent during "Hit any key to stop autoboot"
  stopped U-Boot; the next Linux commands landed at the U-Boot prompt (`Unknown command`). None writes
  anything; resumed with `boot`. Lesson: after power-on, only listen until `login:`.

### Stage 26 – Final verification (Z) – 2026-10-25

| Check | Result |
|---|---|
| Boot | U-Boot → Xen → login by itself, no panic |
| Xen | compiled Sun Oct 25 09:43:12 UTC 2026, `/boot/xen` 917560 bytes, sha256 `6a53ae892f2dc3bce53696a0c1b1275e111ce7e8b01c539d72107f0027a77750` |
| Crash test | 3000 pause/unpause rounds, **no panic** (old Xen: < 250) |
| Guests | Domain-0, rtos1, android1 running |
| Vehicle frames | 1000/10 s, 0 lost, max gap 25–35 ms |
| FreeRTOS 10 ms task | 9958–10040 µs |
| Guest logs | `/var/log/xen/console/guest-rtos1.log`, `guest-android1.log` |
| ignition-watch | installed (`S94ignition-watch`), not running (ENABLED=0), `gpioget gpiochip0 17` = 0 |

### Stage 27 – Three guests, HDMI placeholder fix, rtos1 TFT – 2026-11-04

Android removed (commit `5986a0e`); guests rtos1 + media1. Two display faults fixed and verified
on the board, details in 9.12:

| Fault | Root cause | Fix |
|---|---|---|
| QEMU placeholder "This VM has no graphic display device" on HDMI during playback | `guest-vnc` reconnected on its own after a media1 restart, bypassing `display-map`'s `guest_fb_ready` | `guest-vnc -1` (exit on loss); `display-map` passes it; `guest_fb_ready` also requires the frontend in state 4 |
| rtos1 ILI9341 blank | SPI 24.75 MHz (> 10 MHz ILI9341 limit), CS asserted forever | `SPI_BAUD_DIV` 6 (8.25 MHz), CS deasserted/asserted per command |

Verification: media1 destroy/create while playing → no placeholder; TFT shows the dashboard after
rewiring + `rtos1-start`; full reboot → rtos1 and media1 start, autologin on all consoles, HDMI
shows media1; rtos1 10 ms task 9941–10080 µs, RTDS 1000/1000.

---

## 9. Component reference (code and configuration)

Only the key parts are reproduced here; the full sources are in the layer (paths given).

### 9.1 U-Boot

`recipes-bsp/u-boot/u-boot_2022.01.bbappend`:

```
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append:tinker-board = " \
    file://0001-rockchip-rk3288-allow-booting-in-non-secure-HYP-mode.patch \
    file://0002-rockchip-rk3288-add-PSCI-to-start-the-secondary-CPUs.patch \
    "
```

**Patch 0001 – non-secure HYP boot** (key parts):

```c
/* arch/arm/cpu/armv7/nonsec_virt.S – before the exception return to HYP */
#ifdef CONFIG_ARMV7_VIRT
	cmp	r6, #HYP_MODE
	ldreq	r4, =0x30c50830			@ HSCTLR RES1 bits only
	mcreq	p15, 4, r4, c1, c0, 0		@ write HSCTLR
	isb
#endif
```

```c
/* arch/arm/mach-rockchip/rk3288/rk3288.c */
bool armv7_boot_nonsec_default(void) { return false; }   /* secure stays default */

void psci_board_init(void)              /* open the SoC to non-secure, as TF-A does */
{
	writel(1, CORE_AXI_SECURITY0);                        /* GIC */
	writel(0xffe0ffe0, SGRF_BASE + SGRF_SOC_CON(2));      /* bus masters/peripherals */
	writel(0x003f003f, SGRF_BASE + SGRF_SOC_CON(3));
	writel(0xffff0000, SGRF_BASE + SGRF_SOC_CON(4));
	writel(0x00ff0000, SGRF_BASE + SGRF_SOC_CON(5));
	writel(BIT(15) | BIT(31), SGRF_BASE + SGRF_SOC_CON(21)); /* whole DDR non-secure */
	writel(0xff, TZPC_BASE + TZPC_DECPROT1SET);           /* DMA non-secure + reset */
	writel(0xff, TZPC_BASE + TZPC_DECPROT2SET);
	...
}
```

```
# arch/arm/mach-rockchip/Kconfig
config ROCKCHIP_RK3288
	select CPU_V7_HAS_NONSEC
	select CPU_V7_HAS_VIRT
# include/configs/rk3288_common.h
#define CONFIG_ARM_GIC_BASE_ADDRESS	0xffc00000
```

**Patch 0002 – PSCI** (`arch/arm/mach-rockchip/rk3288/psci.c`, runs in the secure section):

```c
s32 __secure psci_cpu_on(u32 function_id, u32 target_cpu, u32 pc, u32 context_id)
{
	s32 cpu = rk3288_target_cpu(target_cpu);
	if (cpu < 0)                                   return ARM_PSCI_RET_INVAL;
	if (psci_state[cpu] == PSCI_AFFINITY_LEVEL_ON) return ARM_PSCI_RET_ALREADY_ON;
	...
	psci_save(cpu, pc, context_id);
	psci_set_state(cpu, PSCI_AFFINITY_LEVEL_ON_PENDING);
	if (rk3288_cpu_power_on(cpu)) { ... return ARM_PSCI_RET_INTERNAL_FAILURE; }

	rk3288_mdelay(1);                                   /* boot ROM reaches its WFE loop */
	writel((u32)&psci_cpu_entry, BOOTROM_MAILBOX_PC);   /* 0xff700008 */
	writel(BOOTROM_MAGIC, BOOTROM_MAILBOX_MAGIC);       /* 0xdeadbeaf at 0xff700004 */
	dsb();
	asm volatile("sev");
	return ARM_PSCI_RET_SUCCESS;
}

void __secure psci_system_reset(void)
{
	writel(CRU_GLB_SRST_FST_VALUE, CRU_GLB_SRST_FST);   /* 0xfdb9 → 0xff7601b0 */
	...
}

void rk3288_psci_cpus_off(void)   /* called from psci_board_init(): park cores 1-3 powered off */
{
	writel(0, BOOTROM_MAILBOX_MAGIC);
	for (cpu = 1; cpu < RK3288_NR_CPUS; cpu++) {
		writel(BIT(cpu) | BIT(cpu) << 16, CRU_SOFTRST_CON0);
		setbits_le32(PMU_PWRDN_CON, BIT(cpu));
	}
	...
}
```

### 9.2 Boot script `recipes-bsp/xen-boot-script/files/xen-boot.cmd`

```
setenv bootm_boot_mode nonsec
setenv xen_addr 0x02000000
setenv dom0_addr 0x04000000
load mmc 1:6 ${fdt_addr_r} /rk3288-tinker.dtb
load mmc 1:6 ${xen_addr} /xen
load mmc 1:6 ${dom0_addr} /zImage
setenv dom0_size ${filesize}

fdt addr ${fdt_addr_r}
fdt resize 1024
fdt set /dma-controller@ffb20000 reg <0x0 0xff600000 0x0 0x4000>
fdt rsvmem add 0x79e00000 0x06200000
fdt rm /thermal-zones/cpu-thermal/cooling-maps
fdt set /chosen \#address-cells <1>
fdt set /chosen \#size-cells <1>
fdt set /chosen xen,xen-bootargs "console=dtuart dtuart=serial2 dom0_mem=512M dom0_max_vcpus=1 sched=credit2 loglvl=all guest_loglvl=all"
fdt mknod /chosen module@4000000
fdt set /chosen/module@4000000 compatible "xen,linux-zimage" "xen,multiboot-module"
fdt set /chosen/module@4000000 reg <${dom0_addr} 0x${dom0_size}>
fdt set /chosen/module@4000000 bootargs "console=hvc0 earlycon=xenboot root=PARTLABEL=root rootwait rw rootfstype=ext4 clk_ignore_unused"

bootz ${xen_addr} - ${fdt_addr_r}

echo "Xen did not start: booting Linux without Xen"
setenv bootm_boot_mode sec
sysboot mmc 1:6 any ${scriptaddr} /native/extlinux.conf
```

`native-extlinux.conf`:

```
default native
label native
   kernel /zImage
   fdtdir /
append root=PARTLABEL=root rootwait console=tty1 console=ttyS2,115200n8 rw rootfstype=ext4 init=/sbin/init
```

### 9.3 Xen

`recipes-extended/xen/xen_4.16.bbappend`:

```
XEN_TINKER_DEBUG ??= "0"
SRC_URI:append:tinker-board = " \
    ${@'file://tinker-rk3288-early-printk.cfg' if d.getVar('XEN_TINKER_DEBUG') == '1' else 'file://tinker-rk3288-release.cfg'} \
    file://0001-xen-arm32-add-Cortex-A12-and-Cortex-A17-processor-info.patch \
    file://0002-xen-arm32-emulate-L2CTLR-for-guests.patch \
    file://0003-xen-arm-add-Rockchip-RK3288-platform-with-reset.patch \
    file://0004-xen-sched-fix-race-in-RTDS-scheduler.patch \
    file://0005-xen-sched-try-harder-to-find-a-runnable-unit-in-rt_schedule.patch \
    "
```

`tinker-rk3288-release.cfg`:

```
# CONFIG_DEBUG is not set
CONFIG_EXPERT=y
CONFIG_UNSUPPORTED=y
CONFIG_SCHED_RTDS=y
```

`tinker-rk3288-early-printk.cfg` (debug):

```
CONFIG_DEBUG=y
CONFIG_EARLY_UART_CHOICE_8250=y
CONFIG_EARLY_UART_BASE_ADDRESS=0xff690000
CONFIG_EARLY_UART_8250_REG_SHIFT=2
```

| Patch | What it does | Upstream status |
|---|---|---|
| 0001 | proc_info for Cortex-A12 (MIDR 0x410FC0D0, RK3288 reports 0x410fc0d1) and A17; init = set ACTLR.SMP like A15 | Pending |
| 0002 | emulate L2CTLR (p15,1,c9,c0,2): return HW value with the domain's CPU count, ignore writes | Pending |
| 0003 | `xen/arch/arm/platforms/rockchip.c`: platform "Rockchip RK3288", `.reset` = 0xfdb9 → CRU+0x1b0; matches `rockchip,rk3288-cru` and `rockchip,rk3288w-cru` | Pending |
| 0004 | `rt_schedule()`: also `replq_remove()` a picked unit that is not runnable | Backport 73c62927f64e |
| 0005 | `rt_schedule()`: loop over the run queue until a runnable unit is found | Backport 0f1dec89d324 |

Patch 0002 core:

```c
case HSR_CPREG32(L2CTLR):
    if ( psr_mode_is_user(regs) )
        return inject_undef_exception(regs, hsr);
    if ( cp32.read )
    {
        uint32_t l2ctlr = READ_CP32(L2CTLR);
        l2ctlr &= ~(3U << 24);
        l2ctlr |= ((v->domain->max_vcpus - 1) & 3U) << 24;
        set_user_reg(regs, regidx, l2ctlr);
    }
    break;
```

Patches 0004 + 0005 result in `xen/common/sched/rt.c`:

```c
        while ( true )
        {
            snext = runq_pick(ops, cpumask_of(sched_cpu), cur_cpu);
            if ( snext == NULL )
            {
                snext = rt_unit(sched_idle_unit(sched_cpu));
                break;
            }
            if ( unit_runnable_state(snext->unit) )
                break;

            q_remove(snext);
            replq_remove(ops, snext);      /* the missing line that caused the panic */
        }
```

`xen-tools_4.16.bbappend`:

```
do_install:append:tinker-board() {
    sed -i 's|^#XENCONSOLED_TRACE=.*|XENCONSOLED_TRACE=guest|' ${D}${sysconfdir}/default/xencommons
    echo "d root root 0755 /var/log/xen/console none" >> ${D}${sysconfdir}/default/volatiles/99_xen
}
```

### 9.4 dom0 kernel (linux-yocto 5.15)

```
SRC_URI:append:tinker-board = " \
    file://0001-ARM-rockchip-rk3288-keep-timer7-running-if-already-started.patch \
    file://xen-dom0-bridge.cfg \
    file://xen-dom0-display.cfg \
    file://xen-dom0-can.cfg \
    "
```

Patch 0001 (`arch/arm/mach-rockchip/rockchip.c`):

```c
			if (!(readl(reg_base + 0x30) & 1)) {     /* only if timer7 is not running */
				writel(0, reg_base + 0x30);
				writel(0xffffffff, reg_base + 0x20);
				writel(0xffffffff, reg_base + 0x24);
				writel(1, reg_base + 0x30);
				dsb();
			}
```

Fragments: `CONFIG_BRIDGE=y`; `CONFIG_FB_VIRTUAL=m`;
`CONFIG_CAN_VCAN=m CONFIG_CAN_GS_USB=m CONFIG_CAN_PEAK_USB=m CONFIG_CAN_SLCAN=m`.

### 9.5 Image recipe `recipes-core/images/tinker-xen-test-image.bb`

```
require recipes-core/images/core-image-minimal.bb
WKS_FILE = "tinker-xen.wks"
IMAGE_BOOT_FILES:append = " xen-${MACHINE};xen xen-boot.scr xen-boot.scr;boot.scr \
    native-extlinux.conf;native/extlinux.conf"
do_image_wic[depends] += "xen:do_deploy xen-boot-script:do_deploy android-guest:do_deploy"
IMAGE_INSTALL:append = " \
    xen-tools-xencommons \
    kernel-module-xen-gntdev kernel-module-xen-gntalloc \
    kernel-module-xen-blkback kernel-module-xen-netback kernel-module-xen-wdt \
    xen-tools-scripts-network xen-tools-scripts-block xenbr0 \
    freertos-xen-guest \
    android-guest android-tools \
    xen-guests xen-guests-watchdog \
    qemu android-hdmi \
    kernel-module-rockchipdrm kernel-module-dw-hdmi kernel-module-vfb \
    kernel-module-snd-usb-audio alsa-utils-aplay alsa-utils-amixer alsa-utils-speakertest \
    vehicle-bench can-utils cluster-hdmi ignition-watch \
    kernel-module-vcan kernel-module-gs-usb kernel-module-peak-usb kernel-module-slcan \
    "
IMAGE_ROOTFS_EXTRA_SPACE = "65536"
```

### 9.6 FreeRTOS guest (`recipes-rtos/freertos-xen-guest`)

Files: `startup.S` (zImage header, vectors, stacks), `guest.ld` (link at 0x40008000), `main.c`
(platform + tasks), `tft.c`/`tft.h` (ILI9341 driver, 9.12), `FreeRTOSConfig.h`, `Makefile`,
`rtos1.cfg`, `rtos1-start`, `rtos1-hwprep.c` (dom0 helper: SPI2 clocks + pin mux, 9.12).
FreeRTOS-Kernel V11.1.0 is fetched by the recipe and used unmodified.

zImage header in `startup.S`:

```asm
_start:
	.rept	8
	mov	r0, r0
	.endr
	b	reset			@ 0x20
	.word	0x016f2818		@ 0x24: zImage magic
	.word	_start			@ 0x28: absolute load/run address (entry)
	.word	_end			@ 0x2c: end address
	.word	0x04030201		@ 0x30: little-endian marker
```

Tasks (`main.c`):

```c
xTaskCreate( vRealTimeTask,  "rt10ms",    configMINIMAL_STACK_SIZE * 2, NULL, 4, NULL );
xTaskCreate( vHeartbeatTask, "heartbeat", configMINIMAL_STACK_SIZE * 2, NULL, 3, NULL );
xTaskCreate( vProducerTask,  "producer",  configMINIMAL_STACK_SIZE * 2, NULL, 2, NULL );
xTaskCreate( vConsumerTask,  "consumer",  configMINIMAL_STACK_SIZE * 2, NULL, 2, NULL );
xTaskCreate( vVehicleTask,   "vehicle",   configMINIMAL_STACK_SIZE * 2, NULL, 3, NULL );
xTaskCreate( vDisplayTask,   "display",   configMINIMAL_STACK_SIZE * 2, NULL, 1, NULL );  /* TFT */
xTaskCreate( vShellTask,     "shell",     configMINIMAL_STACK_SIZE * 2, NULL, 1, NULL );
```

Console input with the burst fix:

```c
static uint32_t console_read( char * buf, uint32_t size )
{
    ...
    while( cons != prod && n < size )
        buf[ n++ ] = ring->in[ cons++ & ( sizeof( ring->in ) - 1 ) ];
    ring->in_cons = cons;
    /* notify xenconsoled only when the ring was nearly full (rate limit 30 / 200 ms) */
    if( n && ( prod - ( cons - n ) ) > sizeof( ring->in ) - 256 )
        ( void ) xen_hypercall2( __HYPERVISOR_event_channel_op, EVTCHNOP_send,
                                 ( uint32_t ) &ulConsEvtchn );
    return n;
}
```

Vehicle checks (`vVehicleTask`, every 5 ms):

```c
#define VEHICLE_PERIOD_MS       5
#define VEHICLE_TIMEOUT_MS      100     /* no frame for this long: signal lost */
#define OVERSPEED_KMH100        12000   /* 120.00 km/h */
#define REDLINE_RPM             6000

if( !overspeed && speed > OVERSPEED_KMH100 )            → "ALERT overspeed"
else if( overspeed && speed < OVERSPEED_KMH100 - 500 )  → "overspeed cleared"
if( !redline && rpm > REDLINE_RPM )                      → "ALERT engine over redline"
else if( redline && rpm < REDLINE_RPM - 300 )            → "redline cleared"
if( have_signal && now - last_rx > 100 ms )              → "SIGNAL LOST ... speed/rpm invalid"
```

`rtos1.cfg`:

```
name   = "rtos1"
kernel = "/var/lib/xen/rtos1/freertos-xen-guest.bin"
memory = 4
vcpus  = 1
pool   = "rt"
iomem  = [ "ff130,1", "ff7c0,1" ]     # SPI2 and GPIO5 pages, mapped 1:1 (TFT)
```

### 9.7 Android guest

`android1.cfg`:

```
name = "android1"
kernel = "/var/lib/xen/android/zImage"
ramdisk = "/var/lib/xen/android/ramdisk.img"
extra = "console=hvc0 androidboot.hardware=xen androidboot.console=hvc0 androidboot.selinux=permissive video=vfb:640x480-16@60 vfb.videomemorysize=4194304"
memory = 768
vcpus = 2
disk = [ 'phy:/dev/disk/by-partlabel/android-system,xvda,r',
         'phy:/dev/disk/by-partlabel/android-data,xvdb,w' ]
vif = [ 'bridge=xenbr0' ]
#vfb = [ 'vnc=1,vnclisten=127.0.0.1,vncdisplay=0' ]     (experimental screen, off)
```

`init.xen.rc`:

```
on early-init
    mount debugfs debugfs /sys/kernel/debug mode=755
on init
    mkdir /dev/input 0755 root input
on fs
    mount_all /fstab.xen
on boot
    setprop service.adb.tcp.port 5555
    setprop ro.radio.noril yes
    start xen-net
service xen-net /system/bin/sh /xen-net.sh
    seclabel u:r:su:s0
    user root
    group root
    oneshot
    disabled
```

`fstab.xen`:

```
/dev/block/xvda    /system      ext4    ro                                         wait
/dev/block/xvdb    /data        ext4    noatime,nosuid,nodev,errors=panic          wait,check
```

`xen-net.sh`:

```sh
ifconfig eth0 192.168.100.3 netmask 255.255.255.0 up
ip route add default via 192.168.100.1 dev eth0
# wait for netd, then a resolver network for DNS
ndc network create 60000
ndc resolver setnetdns 60000 "" 8.8.8.8 1.1.1.1
ndc network default set 60000
```

How the image is built (`android-guest.bb`, `do_compile`): ramdisk = SDK ramdisk + a second cpio
with `default.prop` (+ `ro.sf.lcd_density=160`), `fstab.xen`, `init.xen.rc`, `xen-net.sh`;
`system.img` edited with `debugfs`: emulator EGL/GLES libs removed, `libGLES_android.so` →
`libGLES_soft.so`; `e2fsck -fn` check. License `CLOSED` (Android SDK License: development use only).

Guest kernel (`linux-android-guest_4.14.336.bb`): `multi_v7_defconfig` + `android-guest.cfg`
(XEN, HVC_XEN, blk/net/fb/kbd frontends, ANDROID_BINDER_IPC + _32BIT, ASHMEM, SELinux, cgroups,
netfilter/NAT, FB_VIRTUAL, LPAE, no modules); `do_configure` fails the build if any required option
is missing. Patches: 0001 timerfd alarm for gid 1000, 0002 kbdfront pointer = touchscreen,
0003 fbfront 16 bpp.

Patch 0001 core:

```c
#define ANDROID_AID_SYSTEM	1000
static bool timerfd_may_use_alarm(void)
{
	return capable(CAP_WAKE_ALARM) ||
	       in_egroup_p(KGIDT_INIT(ANDROID_AID_SYSTEM));
}
```

### 9.8 dom0 services

| Init script | Order | Job | Config |
|---|---|---|---|
| `hw-watchdog` | S05 | opens /dev/watchdog (dw_wdt), writes every 5 s, never closes cleanly | – |
| `xenbr0` | S79 | bridge 192.168.100.1/24, ip_forward, `iptables -t nat ... MASQUERADE` | – |
| `xencommons` | S80 | xenstored, xenconsoled (`--log=guest`) | `/etc/default/xencommons` |
| `xen-guests` | S90 / K10 | start rtos1 (`rtos1-start`), android1 and media1; stop in reverse (`xl shutdown`, 30 s, then destroy) | `/etc/default/xen-guests` |
| `vehicle-bench` | S92 / K08 | vcan0 + vehicle-sim + can2rtos loop; real bus listen-only | `/etc/default/vehicle-bench` |
| `cluster-hdmi` | S93 | waits for /dev/fb0, runs the dashboard (ENABLED=0 since Part 6: display-map runs it) | `/etc/default/cluster-hdmi` |
| `display-map` | S93 / K07 | one viewer per screen (HDMI + USB displays), see 9.10 | `/etc/default/display-map` |
| `ignition-watch` | S94 / K05 | ACC GPIO → poweroff (ENABLED=0) | `/etc/default/ignition-watch` |
| `android-hdmi` | – | Android PV screen on HDMI (ENABLED=0) | `/etc/default/android-hdmi` |

USB hub rule (`50-tinker-usb-hub.rules`):

```
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="05e3", ATTR{idProduct}=="0608", ATTR{power/control}="on"
```

Getty fix (`start_getty`):

```sh
if [ "$2" != "hvc0" ] && grep -qs xen /sys/hypervisor/type; then
    sleep 1000
    exit 0
fi
```

QEMU (`qemu_%.bbappend`): `QEMU_TARGETS = "i386"`, `PACKAGECONFIG = "fdt pie xen"` – only the Xen
device model (xen-tools expects `/usr/bin/qemu-system-i386` on every architecture).

### 9.9 Automotive programs

**vehicle-sim** (`recipes-extended/vehicle-bench/files/vehicle-sim.c`) – 60 s cycle:

| Time | Speed |
|---|---|
| 0–20 s | accelerate 0 → 135 km/h |
| 20–35 s | cruise 135 km/h (above the 120 limit) |
| 35–50 s | brake to 0 |
| 50–60 s | stand still (800 rpm idle) |

Gearbox: limits 25/70/95/115/130 km/h, ratios 160/90/62/48/40/34 rpm per km/h (late shift in
2nd gear → redline). Frames every 10 ms, uint16 big endian: `0x0C0` speed in 0.01 km/h, `0x0C1` rpm.
`SIGUSR1` pauses/resumes (signal-loss test).

**can2rtos** – receive-only gateway:

```c
struct can_filter flt[2] = {
    { .can_id = ID_SPEED,  .can_mask = CAN_SFF_MASK },
    { .can_id = ID_ENGINE, .can_mask = CAN_SFF_MASK },
};
/* rtos1's console pty from xenstore: /local/domain/<id>/console/tty */
n = snprintf(line, sizeof(line), "V %u %u %u\n", ++seq, f.data[0] << 8 | f.data[1], rpm);
write(con, line, n);        /* EAGAIN → drop (the next frame is newer) */
/* every 10 s: "can2rtos: 10s: frames N, max gap X ms, dropped D" */
```

**vehicle-bench.init** – real bus in listen-only mode:

```sh
ip link set $IFACE type can bitrate $BITRATE listen-only on || {
    echo "vehicle-bench: cannot set $IFACE to listen-only, not starting"; exit 1; }
```

**cluster-hdmi** (`recipes-extended/cluster-hdmi/files/cluster-hdmi.c`, 551 lines): mmaps
`/dev/fb0`, switches the console to graphics mode, own 5×7 font, reads CAN (receive only) and the
FreeRTOS console log; trims guest logs above 2 MB. Options: `-f fb`, `-i iface`, `-l log`,
`-S file.ppm` (snapshot after 3 s, ¼ scale), `-g WxH` (draw into memory), `-D` (demo values).

**ignition-watch** (`/usr/sbin/ignition-watch`):

```sh
v=$(gpioget $CHIP $LINE)
if [ "$v" = "$ACC_ON_LEVEL" ]; then seen_on=1; off_since=0          # ACC on
elif [ $seen_on = 1 ]; then
    [ $off_since = 0 ] && off_since=$(now)                            # ACC just went off
    [ $(( $(now) - off_since )) -ge "$OFF_DELAY" ] && { sync; poweroff; }
fi
```

### 9.10 Part 6: four domains, a screen per OS, Android 10 (2026-10-27)

**Status: built, not tested on hardware.** Android 10 (LineageOS 17.1): source synced, first build
started.

Build 2026-10-27 14:02: `bitbake tinker-xen-test-image`, 4540 tasks, no warnings/errors.
`tinker-xen-test-image-tinker-board.wic` 3,543,864,320 bytes, sha256 `0fe2d29426b6153e…`.
GPT: p6 boot 145.6 MiB, p7 root 577.8 MiB, p8 android-system 1.8 GiB, p9 android-data 550 MiB,
**p10 media-root 298.3 MiB** (`media-guest-image-tinker-board.ext4`, 312,797,184 bytes).
Verified in the rootfs: no ffmpeg/libav in dom0; `display-map`, `media-guest`,
`kernel-module-udl`, `/boot/zImage → zImage-5.15.201-yocto-standard`;
`XEN_GUESTS="rtos1 android1 media1"`; `BUDGET=1000`; boot.scr `dom0_mem=384M`.

**Size reduction, build 2026-10-27 14:54** (4540 tasks, all succeeded):
`tinker-xen-test-image-tinker-board.wic` **1,571,959,808 bytes** (was 3.54 GB), sha256 `27cb7ba8c8d2b29f…`.
GPT: p6 boot **48.0 MiB** (`--fixed-size 48M`), p7 root **166.0 MiB** (rootfs 72 MB), p8
android-system **612.8 MiB** (642,617,344 bytes), p9 android-data 550 MiB, p10 media-root
**106.3 MiB** (111,470,592 bytes).

| Change | File |
|---|---|
| remove `${datadir}/qemu/*` except `keymaps` (220 MB of firmware) | `recipes-devtools/qemu/qemu_%.bbappend` (`do_install:append`) |
| `IMAGE_ROOTFS_EXTRA_SPACE` 65536 → 32768 | `tinker-xen-test-image.bb` |
| `IMAGE_ROOTFS_EXTRA_SPACE` 262144 → 65536 | `media-guest-image.bb` |
| boot `--size 114688K` → `--fixed-size 48M` | `wic/tinker-xen.wks` |
| system.img: `e2fsck -fy`, `resize2fs -M`, grow to +10 %, `dd if=/dev/null … seek=N` (no `truncate` in HOSTTOOLS), `e2fsck -fy` (fixes resize inode 7 `i_size`), `e2fsck -fn` | `android-guest.bb` |
| `dom0_mem=320M` | `xen-boot.cmd` |
| media1 `memory = 192` | `media1.cfg` |
| rtos1 `memory = 4`; `LENGTH = 4M - 32K`; `GUEST_RAM_MB 4` (`_end` = 0x4002ad18, 172 KB) | `rtos1.cfg`, `guest.ld`, `main.c` |

#### Resource plan

| Domain | Memory | vCPUs | CPUs | Scheduler | Display |
|---|---|---|---|---|---|
| Domain-0 | **320 MB** (`dom0_mem=320M`; 512 → 384 → 320) | 1 | Pool-0 (0–2) | credit2 | owns HDMI + USB displays |
| rtos1 | **4 MB** (was 16) | 1 | CPU 3, pool `rt` | RTDS, **period 1000 µs, budget 1000 µs** (was 200), extratime 1 | via cluster-hdmi (dom0) |
| android1 | 512 MB (was 768; ~768 again for Android 10) | 2 | `cpus = "0-2"` | credit2 | vfb, VNC :5900 (still commented out for Android 7) |
| media1 | **192 MB** (was 256) | 2 | `cpus = "0-2"` | credit2 | vfb 800×480, VNC :5901 |

Total **1028 MB** (≈ 1.28 GB with Android 10 at 768 MB) of 2 GB, minus the 98 MB U-Boot reservation.

`rtos1.cfg` is **not** pinned with `cpus = "3"`: the `rt` pool already confines it, and a hard
affinity outside Pool-0 at create time (before the pool move) could fail the create.

#### dom0 image (`tinker-xen-test-image.bb`)

- Removed: `ffmpeg`, `nature-video` (recipe deleted; the clip moved to `media-player`).
- Added: `media-guest`, `display-map`, `kernel-module-udl`.
- `do_image_wic[depends] += "media-guest-image:do_image_complete"`.
- The SSH setup moved into `classes/tinker-ssh.bbclass` (`inherit tinker-ssh`), shared with media1.

#### Kernel (`xen-dom0-display.cfg`)

```
CONFIG_DRM_UDL=m      # DisplayLink DL-1x0/DL-1x5 (USB 2.0) adapters
```

DL-3xxx/DL-5xxx/DL-6xxx need the closed `evdi` + DisplayLinkManager stack: not supported.

#### media1 guest

| File | Content |
|---|---|
| `recipes-core/images/media-guest-image.bb` | `core-image-minimal` + `media-player ffmpeg`; `IMAGE_FSTYPES = "ext4"`; `IMAGE_ROOTFS_EXTRA_SPACE = "262144"`; `inherit tinker-ssh`; postprocess: hostname `media1`, static `eth0` `MEDIA_GUEST_IP ?= "192.168.100.4"`/24 gw .1, plain `/etc/resolv.conf` (8.8.8.8) |
| `recipes-extended/media-guest/files/media1.cfg` | `kernel = "/boot/zImage"` (dom0's 5.15: blk/net/fb/kbd frontends built in); `extra = "console=hvc0 root=/dev/xvda rw rootwait rootfstype=ext4 xen_fbfront.video=2,800,480"`; `disk = [ 'phy:/dev/disk/by-partlabel/media-root,xvda,w' ]`; `vif = [ 'bridge=xenbr0' ]`; `vfb = [ 'vnc=1,vnclisten=127.0.0.1,vncdisplay=1' ]` |
| `recipes-extended/media-player/` | `media-play [-f fbdev] [-d secs] [-l] file\|dir…`: ffmpeg `-f fbdev`, `-pix_fmt bgra`, scale+pad to the framebuffer; pictures with `-loop 1 -framerate 1 -t SECS`. `media-player` init (S94): loops `/home/root/media`, or `/usr/share/media-player/sixes-river-800x480.mp4` while empty |
| `wic/tinker-xen.wks` | `part --source rawcopy --sourceparams="file=media-guest-image-${MACHINE}.ext4" --part-name media-root` (partition 10) |
| `xen-guests` | `XEN_GUESTS="rtos1 android1 media1"`; RDEPENDS `media-guest` |
| `xen-consoles` | 4th tmux pane: `xl console media1` |

#### display-map (`recipes-extended/display-map`)

`/etc/default/display-map`:

```
SCREENS="hdmi=rearcam:vnc:5900 usb1=vnc:5901 usb2=cluster usb3=console"
INPUT_hdmi="/dev/input/event*"          # other screens: none unless INPUT_<screen> is set
```

- Screen → framebuffer: `hdmi` = the fb whose `/sys/class/graphics/fbN/name` contains `rockchip`;
  `usbN` = the N-th fb whose name contains `udl`, sorted by `readlink -f fbN/device` (USB port path).
- Sources: `vnc:<port>` → `android-hdmi -f <fb> -p <port> -I <glob>`; `cluster` →
  `cluster-hdmi -f <fb> -i $IFACE`; `console` → `con2fb <fb> 1` (`FBIOPUT_CON2FBMAP`), then waits
  until the display goes away; `rearcam:vnc:<port>` / `rearcam:cluster` → `rear-camera -f <fb>
  -i $IFACE -- <viewer>`; `rearcam` → `rear-camera` alone (see 9.11).
- One background loop per screen: waits for the fb, restarts the viewer, re-resolves after an unplug.
  Log: `/var/log/display-map.log`. Init S93 / K07.
- Writes `ENABLED=0` to `/etc/default/android-hdmi` and `/etc/default/cluster-hdmi` (the
  single-screen services).

Viewer changes:

- `android-hdmi`: new `-I <glob>|none` (input devices to forward; default `/dev/input/event*`).
- `android-hdmi` and `cluster-hdmi`: switch tty1 to `KD_GRAPHICS` only if
  `FBIOGET_CON2FBMAP` for console 1 equals the minor of their own fb (`console_on()`).

#### Android 10 (LineageOS 17.1): host setup and sync

| Item | Value |
|---|---|
| Host | Ubuntu 22.04.5, 8 threads, 15 GB RAM, **16 GB swap** (`/swapfile`, was 2 GB) |
| Packages | LineageOS build list + `python2` (2.7.18) + `git-lfs` 3.0.2 |
| Tree | `~/lineage-17.1`, **58 GB** after sync |
| Init | `repo init -u https://github.com/LineageOS/android.git -b lineage-17.1 --depth=1 -g default,-darwin,-mips,-notdefault` |
| Sync | `repo sync -c -j8 --no-tags --no-clone-bundle --optimized-fetch --prune` |
| Local manifest | `.repo/local_manifests/tinker-xen.xml`: `remove-project` for `android_external_chromium-webview_prebuilt_{arm64,x86,x86_64}` |
| WebView ARM | re-synced, `git lfs pull` → `webview.apk` 98,126,751 bytes |
| Target | `lineage_arm-userdebug` (`vendor/lineage/build/target/product/lineage_arm.mk`: inherits `aosp_arm.mk`, `TARGET_USES_64_BIT_BINDER := true`) |

Work still to do for the Xen guest:

1. Plain `lineage_arm-userdebug` build (`source build/envsetup.sh; lunch lineage_arm-userdebug; m -j8`).
2. Guest kernel: Android 10 userspace needs the 64-bit binder ABI (`CONFIG_ANDROID_BINDER_IPC_32BIT`
   off) and `CONFIG_ANDROID_BINDER_DEVICES="binder,hwbinder,vndbinder"`; the 4.14 base is an
   Android 10 launch kernel version.
3. Graphics without a GPU: SwiftShader (GLES) plus a composer/gralloc that works on the Xen PV
   framebuffer. Highest risk; no known Android 10 ARM32 software-rendering setup.
4. Vendor init/fstab for Xen (xvda system, vendor, xvdb data, hvc0 console, eth0 192.168.100.3),
   a new `android-guest` recipe and wks partitions (`android-vendor`).

Expected sizes: build output 60–90 GB; card: system 1.5–2 GB, vendor 0.1–0.3 GB, data ~2 GB → whole
card ~5–5.5 GB (8 GB minimum, 16 GB recommended).

Rejected: **Android 17** (64-bit only, RAM/GPU/kernel requirements, ~400 GB / 32–64 GB host).
Fallbacks: Android 9 (from source; Replicant 9 ran software-rendered on ARMv7) or 7.1.1
(`armeabi-v7a-25_r18`, Google APIs, the last prebuilt ARM32 image).

### 9.11 Rear camera and audio pipeline (2026-10-27)

**Status: host-tested (logic, rendering, mixing), not tested on hardware.**

**CAN:** new frame `0x0C2` gear, DLC 2: byte 0 selector `'P' 'R' 'N' 'D'`, byte 1 forward gear
1–6 (0 otherwise). `vehicle-sim` cycle: 50–52 s stand (D), 52–58 s reverse 0→4→0 km/h, 58–60 s P;
SIGUSR2 (`vehicle-bench reverse`) holds R at 3 km/h. `cluster-hdmi` shows the selector when it is
not D (falls back to the speed-derived gear after 1 s without 0x0C2) and redraws its static layer
on SIGCONT; `android-hdmi` requests a full (non-incremental) VNC update on SIGCONT. can2rtos and
FreeRTOS ignore 0x0C2.

**`rear-camera`** (`recipes-extended/rear-camera`): `rear-camera [-f fb] [-i if] [-d /dev/video0]
[-s 640x480] [-r 15] [-n] [-T] [-g WxH] [-- viewer args]`. Forks/execs the viewer; on reverse
(0x0C2 byte 0 == 'R', or SIGUSR1 manual, or -T) SIGSTOPs it and waits (`waitpid WUNTRACED`) until
it has stopped, opens V4L2 (YUYV only, 4 mmap buffers, MJPEG-only cameras refused), draws nearest-
neighbour scaled, aspect-kept, mirrored (-n off) BT.601 YUYV→RGB at ≤ 15 fps, fixed guide lines
(3 bands) and a banner. Exit: 1 s hold after R ends, or 1 s without 0x0C2 → STREAMOFF, SIGCONT.
Camera errors/unplug → colour bars + "NO CAMERA", reopen every 2 s. Viewer exit → rear-camera
exits 1 (display-map restarts). SIGTERM → SIGTERM + SIGCONT to the viewer. Reverse chime via
`/run/audio-mixer/chime` (O_NONBLOCK; no-op when the mixer is down). display-map sources
`rearcam:cluster`, `rearcam:vnc:<port>`, `rearcam`; default `usb2=rearcam:cluster`.
Kernel: `CONFIG_USB_VIDEO_CLASS=m` was already set; image adds `kernel-module-uvcvideo`.

**`audio-mixer`** (`recipes-extended/audio-mixer`, init S91): ALSA `snd_pcm_set_params` S16_LE
stereo 48 kHz, 80 ms latency, 20 ms (960-frame) mix periods; the blocking `snd_pcm_writei` paces
the loop (clock_nanosleep when no card; card reopened every 2 s, alsa-lib error output silenced).

| Source | Transport | Format | Buffering |
|---|---|---|---|
| media (media1) | UDP 192.168.100.1:5601, only from .4 | S16LE 2 ch 48 kHz | > 300 ms buffered → drop to 100 ms |
| android (android1) | TCP 192.168.100.1:5602, only from .3, one connection (new replaces old), SO_RCVBUF 16 KB | S16LE 2 ch 44.1 kHz | read only up to 100 ms ahead → TCP back-pressure paces the guest |
| chimes | FIFO `/run/audio-mixer/chime` (O_RDWR), one name per line; `audio-mixer -c NAME` | synthesised sine, 5 ms ramps | queue of 8, duplicates dropped |

Per source: 32768-frame ring, 60 ms prebuffer before playing, linear-interpolation resampling
(16.16 step), gain `-g media%,android%`. Chimes: `warn` 3× 880 Hz 160 ms, `reverse` 2× 1250 Hz
90 ms, `info` 660+880 Hz. Ducking: guests × 0.25 while a chime plays or is queued (one-pole,
~10 ms). `vehicle-chimes`: `tail -n 0 -F` of `guest-rtos1.log`; `ALERT `/`SIGNAL LOST` → warn,
` cleared`/`SIGNAL OK again` → info. Config `/etc/default/audio-mixer` (DEVICE, GAIN, CHIMES, OPTS).

**media1:** `media-play -a URL` (default `udp://192.168.100.1:5601?pkt_size=1920`, `""` = off). A
video with an audio stream (probed with `ffmpeg -i | grep Audio:`; an output without streams is an
ffmpeg error) gets a second output `-map 0:a:0 -ac 2 -ar 48000 -f s16le`; `-re` paces it.

**Board test 2026-10-27 (Step 40):** uvcvideo STREAMON oopsed in `dma_common_alloc_pages`
(`memset(page_address())` = NULL) because xen-swiotlb's `.alloc_pages` path took a CMA page and
dom0's CMA (64 MiB at 0x70000000, bank 1) is highmem; kernel 0003 frees a highmem CMA page and
allocates from lowmem. After the oops the stream mutex/USB device lock stays held: later USB
enumeration and `lsusb` hang until reboot. Codec card "Audio" (0bda:49f6): pcm0 is 8 kHz only,
pcm1/pcm2 44.1–192 kHz → `DEVICE=plughw:CARD=Audio,DEV=1`. Init `stop` used `killall
audio-mixer`, which matched the init script itself → pidof loop excluding `$$`. Android 7 has no
`mkfifo`/`netcat` links (toybox applets only).

**Android screen:** the 2026-10-25 "timer freeze" (section Y) was s2idle suspend after the 60 s
screen timeout (`PM: suspend entry (s2idle)` at 162 s in guest-android1.log); nothing wakes the
guest. Fix: `write /sys/power/wake_lock xen` in `on init`, `svc power stayon true` and
`screen_off_timeout 2147483647` at boot_completed (service xen-stayon). android1.cfg: vfb on,
`xen_fbfront.depth=16 xen_fbfront.video=2,800,480 qemu=0` (kernel cmdline `qemu=0` →
`ro.kernel.qemu=0` via init's emulator pass, HWUI off); default.prop `ro.config.low_ram=true`
(`ActivityManager.isHighEndGfx()` false → ImageWallpaper draws with Canvas, not GLES 2.0).
Verified live: 6+ min with the screen, launcher focused, no new suspend entries.
display-map default `hdmi=rearcam:vnc:5900 usb1=vnc:5901 usb2=cluster usb3=console`.

**android1 (Android 7):** the SDK image's only audio HAL is `audio.primary.goldfish.so`, which
writes 44.1 kHz stereo S16 to `/dev/eac` (O_RDWR); `ro.hardware=xen` and empty
`ro.product.board`/`ro.board.platform` meant no primary HAL loaded at all. The build adds
`/system/lib/hw/audio.primary.xen.so → audio.primary.goldfish.so` (debugfs `symlink`, e2fsck
clean). `init.xen.rc`: `on post-fs` `exec … /xen-audio.sh setup` makes `/dev/eac` a FIFO
(root:audio 0660) before audioserver starts; service `xen-audio` (su domain, SELinux permissive)
sets `tcp_wmem` to `4096 16384 32768` and runs `netcat 192.168.100.1 5602 < /dev/eac` in a loop.
The HAL's input stream would also read `/dev/eac` (recording would eat playback data; no mic
anyway). Latency ≈ pipe 64 KB (370 ms) + send buffer + 100 ms ring. Android 10 (Q goldfish HAL uses
tinyalsa) needs a different path: not done.


### 9.12 Display path fixes and the rtos1 TFT (2026-11-04)

#### 9.12.1 Current display layout

```
 media1 ──xen-fbfront 800x480──► QEMU xenfb, VNC 127.0.0.1:5901 ──► guest-vnc -1 ──► HDMI /dev/fb0
                                                      (started and supervised by display-map)
 rtos1  ──SPI2 + GPIO5 (iomem, 1:1)───────────────────────────────────────────────► ILI9341 TFT
 dom0   ──UART2 (Xen console, hvc0)──────────────────────────────────────────────► serial cable
```

`/etc/default/display-map`: `SCREENS="hdmi=vnc:5901"`, `SCALE=fill`,
`INPUT_hdmi="/dev/input/event*"`. `media1.cfg`: `vfb = [ 'vnc=1,vnclisten=127.0.0.1,vncdisplay=1' ]`,
`extra = "... xen_fbfront.video=2,800,480"`.

#### 9.12.2 QEMU placeholder on HDMI ("This VM has no graphic display device")

Until a guest's `xen-fbfront` connects, QEMU's VNC server has no graphic console and serves a
640x480 text placeholder. `display-map`'s `run_screen` already waited in `guest_fb_ready` before
starting `guest-vnc`, but `guest-vnc`'s main loop reconnected internally after `goto lost`
(`sleep(2)` then `vnc_connect`), so after any media1 restart it attached to the new QEMU before
the frontend was up. Observed in `/var/log/display-map.log`:

```
guest-vnc: connection lost, retrying
guest-vnc: guest 640x480 shown 1680x1050 on 1680x1050 monitor at +0+0
guest-vnc: connected to 127.0.0.1:5901
guest-vnc: guest 800x480 shown 1680x1050 on 1680x1050 monitor at +0+0
```

Fix, `recipes-extended/guest-vnc/files/guest-vnc.c`:

```c
static int once;                     /* -1: exit when the connection is lost */
...
while ((opt = getopt(argc, argv, "1H:p:f:t:I:m:")) != -1) {
	case '1': once = 1; break;
...
lost:
	close(sock);
	sock = -1;
	fb_clear();                      /* the monitor goes black, never the placeholder */
	if (once) {
		printf("guest-vnc: connection lost, exiting (-1)\n");
		return 1;
	}
	printf("guest-vnc: connection lost, retrying\n");
	sleep(2);
```

`recipes-extended/display-map/files/display-map.init`: both viewer command lines use
`guest-vnc -1 ...` (`vnc:*` and `rearcam:vnc:*`; `rear-camera` exits when its viewer exits, so
display-map restarts both). `guest_fb_ready` now requires both ends of the vfb connection:

```sh
guest_fb_ready() {
    want=$(($1 - 5900))
    for d in $(xenstore-list /local/domain/0/backend/vfb 2>/dev/null); do
        b=/local/domain/0/backend/vfb/$d/0
        [ "$(xenstore-read $b/vncdisplay 2>/dev/null)" = "$want" ] || continue
        [ "$(xenstore-read $b/state 2>/dev/null)" = 4 ] || continue
        # the backend of a guest just destroyed can still read 4 for a moment
        fe=$(xenstore-read $b/frontend 2>/dev/null)
        [ -n "$fe" ] && [ "$(xenstore-read $fe/state 2>/dev/null)" = 4 ] && return 0
    done
    return 1
}
```

The stand-alone `/etc/init.d/guest-vnc` service (`ENABLED=0` by default) is unchanged and still
uses the internal reconnect.

Test (`xl destroy media1; xl create /etc/xen/media1.cfg` while playing):

```
guest-vnc: connection lost, exiting (-1)
hdmi: waiting for the guest screen on VNC port 5901
hdmi (/dev/fb0): vnc:5901
guest-vnc: /dev/fb0 1680x1050, 32 bpp
guest-vnc: guest 800x480 shown 1680x1050 on 1680x1050 monitor at +0+0
guest-vnc: connected to 127.0.0.1:5901
```

#### 9.12.3 rtos1 ILI9341 TFT

Hardware split: the CRU (clocks) and GRF (pin mux) are shared by the whole SoC and stay with dom0;
rtos1 gets only the SPI2 page `0xff130000` and the GPIO5 page `0xff7c0000` (`iomem`, 1:1).
`rtos1-start` runs `rtos1-hwprep` (dom0, `/dev/mem`, RK3288 write-masked registers) before
`xl create`:

| Register | Value written | Meaning |
|---|---|---|
| CRU_CLKGATE2 `0xff760168` | bit 11 = 0 | sclk_spi2 on |
| CRU_CLKGATE6 `0xff760178` | bit 6 = 0 | pclk_spi2 on |
| CRU_CLKSEL39 `0xff7600fc` | `0x8b` | sclk_spi2 = GPLL 594 MHz / 12 = 49.5 MHz |
| GRF_GPIO5B_IOMUX `0xff770050` | bits 7:6 = 0 | GPIO5_B3 = GPIO (RESET) |
| GRF_GPIO5C_IOMUX `0xff770054` | bits 7:6 = 0 | GPIO5_C3 = GPIO (DC) |
| GRF_GPIO8A_IOMUX `0xff770080` | bits 15:12 = `0101` | GPIO8_A6 SPI2_CLK, GPIO8_A7 SPI2_CSN0 |
| GRF_GPIO8B_IOMUX `0xff770084` | bits 3:0 = `0101` | GPIO8_B0 SPI2_RXD, GPIO8_B1 SPI2_TXD |

Wiring (ILI9341 module → 40-pin header):

| Module | Header | SoC pad / function |
|---|---|---|
| VCC | 17 (or 1) | 3.3 V |
| GND | 20 (or 6/9/14/25) | GND |
| CS | 24 | GPIO8_A7 / SPI2_CSN0 |
| RESET | 18 | GPIO5_B3, GPIO bit 11, active low |
| DC/RS | 22 | GPIO5_C3, GPIO bit 19, low = command |
| SDI/MOSI | 19 | GPIO8_B1 / SPI2_TXD |
| SCK | 23 | GPIO8_A6 / SPI2_CLK |
| LED | 1 | 3.3 V backlight |
| SDO/MISO | 21 (optional) | GPIO8_B0 / SPI2_RXD, unused (transmit only) |
| T_* (XPT2046 touch) | – | not connected |

Driver (`tft.c`): polled, no IRQ/DMA. `CTRLR0 = 0x42401` (8-bit frames, mode 0, one-cycle CS setup,
APB byte access, transmit only, master), `SER = 1`, hardware reset (RESET low 20 ms, 150 ms wait),
`SWRESET`, the init table, `SLPOUT`, `DISPON`; `MADCTL 0x28` (landscape, BGR; `-DTFT_MADCTL=0xe8`
rotates 180°), 16-bit RGB565. The dashboard (`vDisplayTask`, priority 1, lowest) redraws only
changed fields.

Fault: registers and pins were correct and SPI2 was transmitting (sampled from dom0: SR busy ~6 %,
DC toggling), but the panel stayed blank:

1. SPI clock = 49.5 MHz / `BAUDR` 2 = **24.75 MHz**; ILI9341 serial write cycle t_scycw ≥ 100 ns
   (**10 MHz**). Over header jumper wires the panel did not latch.
2. CS0 asserted once (`SER = 1`) and never released: the ILI9341 resynchronises its bit counter
   only on a CS edge, so one lost bit misframes all later bytes.

Fix (`tft.c`):

```c
/* SPI clock = sclk_spi2 (≤ 50 MHz, rtos1-hwprep) / SPI_BAUD_DIV (even).
 * ILI9341 write cycle ≥ 100 ns (10 MHz); /6 gives 8.25 MHz from 49.5 MHz. */
#ifndef SPI_BAUD_DIV
#define SPI_BAUD_DIV    6
#endif

static void tft_cmd( uint8_t c )
{
    spi_wait_idle();
    /* CS high then low again: the panel restarts its bit count on every command */
    REG( SPI2_BASE, SPI_SER ) = 0;
    __asm__ volatile ( "dsb" ::: "memory" );
    REG( SPI2_BASE, SPI_SER ) = 1;
    gpio_set( PIN_DC, 0 );
    spi_byte( c );
    spi_wait_idle();
    gpio_set( PIN_DC, 1 );
}
```

Measured after the fix (pad levels from GPIO EXT_PORT, 2 s): pin 23 CLK 45547 edges, pin 24 CS 190
edges, pin 19 MOSI 14256 edges, pin 22 DC 1216 edges, pin 18 RESET steady high, pin 21 MISO idle;
`BAUDR = 6`. rtos1 10 ms task 9941–10080 µs, RTDS period 1000 / budget 1000 unchanged.

The panel is initialised only at rtos1 start: after rewiring or a panel power loss run
`xl destroy rtos1; rtos1-start`.

#### 9.12.4 Autostart and autologin (verified by a full reboot)

| What | Where | Value |
|---|---|---|
| guests started at boot | `/etc/default/xen-guests`, `S90xen-guests` | `XEN_GUESTS="rtos1 media1"`; rtos1 via `rtos1-start` (cpupool `rt`, RTDS 1000/1000, `rtos1-hwprep`), media1 via `e2fsck -p` + `xl create` |
| HDMI viewer | `S93display-map` | `hdmi=vnc:5901` |
| media1 player | media1 `S94media-player` | loops `/home/root/media`, default clip when empty |
| autologin | `classes/tinker-autologin.bbclass` (dom0 and media1 images) | `getty -n -l /sbin/autologin` on tty1, hvc0 (`getty-wrapper`) and ttyS2 (`start_getty`); `/sbin/autologin` = `exec /bin/login -f root` |

Reboot check (UART): `Starting Xen guest rtos1` → `Starting Xen guest media1` →
`Starting display-map: hdmi=vnc:5901` → `root@tinker-board:~#`; media1 console
`Starting media-player` → `root@media1:~#`; rtos1 `[tft] ILI9341 320x240 on SPI2 initialised`.

#### 9.12.5 media1 init failure on cold boots, and the start check

One cold boot: media1's sysvinit printed `INIT: /etc/inittab[N]: wait: unknown action field` for
every `wait`/`respawn` line, an udevd worker segfaulted (`udevd[94]: worker [99] terminated by
signal 11`), no runlevel scripts ran (no network, no player). The guest's `/etc/inittab` on
`mmcblk0p8` was byte-identical to the build, and `xl destroy` + `xl create` booted cleanly. One
read-only file comparison from dom0 at that time also mismatched on 16 files that matched on every
later read (5 passes with `drop_caches`, 3 raw `dd` passes). Suspected transient read corruption at
boot (SD card SC16G at 50 MHz high-speed, or the blkback path); cause not proven.

It is not a one-off: it recurred on several cold boots and board resets (power cuts). Ruled out on
their own (3 runs of the exact boot sequence each, 0 failures): `e2fsck -p` before `xl create`, and
the deferred-probe retries of `ff0d0000.mmc` (SDIO0, waiting for `sdio-pwrseq`), which happen while
guests are created. Every later `xl create` of media1 booted cleanly.

Further failure modes seen at cold boot, all in the guest's first ~3 s of disk reads:
`Configuring network interfaces... Segmentation fault` (ifup), and
`EXT4-fs error (device xvda): ext4_lookup:1858: inode #410: comm swapper/0: iget: checksum invalid`
→ `Starting init: /sbin/init exists but couldn't execute it (error -74)` → fallback `/bin/sh`. The
metadata checksum failure proves that blocks reach the guest corrupted (blkfront ← blkback ←
mmcblk0). Leads not yet tested: Xen `bootscrub=1` (scrub all memory before guests start instead of
the idle-time scrub), and the dom0 swiotlb-xen pool (only 8 MB allocated).

Workaround (`recipes-extended/xen-guests/files/xen-guests`, defaults in `xen-guests.default`): for
a guest with `READY_<name>`, `start_guest` records the console log size, runs `xl create`, then
starts `watch_guest` in the background (pid in `/var/run/xen-guests/<name>.pid`). `ready_wait`
reads only the new part of `/var/log/xen/console/guest-<name>.log`. It fails at once on
`unknown action field|Segmentation fault|terminated by signal|EXT4-fs error|couldn.t execute|Kernel panic`,
and succeeds when `READY_<name>` has matched **and** `READY_PING_<name>` (if set) answers
`ping -c1 -W1`. On failure or after `READY_TIMEOUT`: `xl destroy`, `fsck_disks`, `xl create`, up
to `READY_RETRIES`. `stop_guest` touches `<name>.stop` and kills the watcher first.

```
READY_media1="root@media1|media1 login:"    # extended regex: autologin prompt = runlevel done
READY_PING_media1=192.168.100.4             # network must be up too (rear camera, sound)
READY_TIMEOUT=45
READY_RETRIES=3
```

Log `/var/log/xen-guests.log`. Board test (restart with the fault present):

```
media1 start broken: INIT: /etc/inittab[12]: wait: unknown action field
media1 did not start properly, restarting it (1/3)
media1 started properly after 1 restart(s)
```

media-player, network and HDMI up 45 s after boot.

---

## 10. Build and flash procedure

### 10.1 Build

```bash
cd ~/xen-hypervisor && ./build.sh       # [--sync] [--clean] [target]
```

`build.sh` = `sync.sh` (if needed) + `sync.sh --check` + MACHINE check + `bitbake tinker-xen-test-image`,
log in `build/logs/`, prints the `.wic` sha256. Environment: `DL_DIR`, `SSTATE_DIR`, `TINKER_SSH_KEY`
(default `~/.ssh/id_ed25519.pub`), `BB_NUMBER_THREADS`, `PARALLEL_MAKE`.

### 10.2 Flash (on the PC – this erases the card)

```bash
./flash.sh --list                       # removable disks, e.g. sda
./flash.sh /dev/sda                     # [-y] [image.wic]
```

`flash.sh` checks: block device, whole disk (TYPE=disk), removable (RM=1), size <= `MAX_GB` (128),
no system mount. Then umount all partitions → `wipefs -a` → `bmaptool copy --bmap` (falls back to
`dd` if bmaptool or the .bmap is missing) → `sync` → `partprobe`. Manual equivalent:

```bash
sudo umount /dev/sda?*
sudo bmaptool copy ~/xen-hypervisor/build/tmp/deploy/images/tinker-board/tinker-xen-test-image-tinker-board.wic /dev/sda
```

**Always write to the whole disk (`/dev/sda`), never to a partition (`/dev/sda1`).**

Lesson learned: once `/dev/sda` was a *regular file* (card not inserted while flashing →
bmaptool created a 3.2 GB file in /dev). Check with `ls -l /dev/sda`:
`brw-rw----` = real card; `-rw-r--r--` = a file → `sudo rm /dev/sda`, reinsert the card. Only delete
it when the line starts with `-`.

Error seen once: `bmaptool: ERROR: ... Device or resource busy` → a partition was auto-mounted; run
the `umount` line again.

### 10.3 Verify the card (read-only)

```bash
sudo mount -o ro /dev/sda6 /mnt && ls -l /mnt/xen && sha256sum /mnt/xen; sudo umount /mnt
```

Expected for the final image: `917560` bytes, `6a53ae892f2dc3bce53696a0c1b1275e111ce7e8b01c539d72107f0027a77750`.

### 10.4 First boot

Insert the card, connect the UART, start `picocom -b 115200 /dev/ttyUSB0`, power on,
**do not press keys** until `tinker-board login:` appears. Log in as `root` (no password).

### 10.5 Hardware test after flashing (Step 40 image)

```
cat /sys/class/drm/card0-HDMI-A-1/status          connected
grep ^SCREENS /etc/default/display-map             SCREENS="hdmi=rearcam:vnc:5900 usb1=vnc:5901 usb2=cluster usb3=console"
tail -3 /var/log/display-map.log                   rear-camera: /dev/fb0 800x480 ... viewer started
                                                   android-hdmi: connected to 127.0.0.1:5900, guest 800x480
adb connect 192.168.100.3:5555
adb shell getprop sys.boot_completed               1
adb shell cat /sys/power/wake_lock                 xen
adb shell dumpsys power | grep -E "mWakefulness=|mStayOn="     Awake / true
adb shell dumpsys window | grep -m1 mCurrentFocus  com.android.launcher3/...Launcher
grep -A4 Mouse /proc/bus/input/devices             H: Handlers=eventN
ls -l /proc/$(pidof android-hdmi)/fd | grep event  the mouse's eventN is open
/etc/init.d/vehicle-bench reverse                  rear-camera: in reverse; /dev/video0 640x480 YUYV
/etc/init.d/vehicle-bench reverse                  rear-camera: out of reverse
dmesg | grep -i -A3 "Oops\|NULL pointer"           (nothing: patch 0003)
audio-mixer -c warn                                (chime)
grep -E "^rate|^state" /proc/asound/card*/pcm1p/sub0/hw_params /proc/asound/card*/pcm1p/sub0/status
                                                   rate: 48000 / state: RUNNING
amixer -c Audio sget PCM,1                         Playback 175 [100%] [on]
tail /var/log/audio-mixer.log                      playing on plughw:CARD=Audio,DEV=1; android: connected from 192.168.100.3
adb shell am start -a android.intent.action.VIEW -t audio/ogg \
  -d file:///system/media/audio/ringtones/Andromeda.ogg -n com.android.music/.AudioPreview
netstat -tn | grep 5602                            Recv-Q drains back to 0 after the ringtone
```

---

## 11. Operating the system (commands and expected output)

### 11.1 Console basics

| Action | How |
|---|---|
| Log in | `root`, no password (debug-tweaks image) |
| Switch UART input dom0 ↔ Xen | `Ctrl-a` three times |
| Leave a guest console | `Ctrl-]` |
| Stop autoboot | any key at "Hit any key to stop autoboot" |

### 11.2 Xen and guests

```
xl list                          Domain-0, rtos1, android1
xl info                          xen_version 4.16.1, nr_cpus 4
xl cpupool-list                  Pool-0 3 credit2 / rt 1 rtds
xl sched-rtds -d rtos1 -v all    rtos1 0 1000 200 yes
xl console rtos1                 [rtos] and [vehicle] lines
xl console android1              Android shell "generic:/ $"
xl dmesg | head                  Xen boot log (debug=n, PSCI, 4 CPUs)
/etc/init.d/xen-guests stop|start|status
```

Example:

```
root@tinker-board:~# xl sched-rtds -d rtos1 -v all; xl cpupool-list
Name                                ID VCPU    Period    Budget  Extratime
rtos1                                1    0      1000       200        yes
Name               CPUs   Sched     Active   Domain count
Pool-0               3   credit2       y          2
rt                   1      rtds       y          1
```

### 11.3 Android

```
adb connect 192.168.100.3:5555          connected to 192.168.100.3:5555
adb shell getprop sys.boot_completed    1
adb shell                               generic:/ $
adb logcat
adb kill-server                         (after use)
```

### 11.3a One HDMI display: which OS it shows

`sed -i 's/^SCREENS=.*/SCREENS="hdmi=<source>"/' /etc/default/display-map` then
`/etc/init.d/display-map restart`:

| OS | `<source>` | Expected in `/var/log/display-map.log` | Other checks |
|---|---|---|---|
| android1 | `rearcam:vnc:5900` | `connected to 127.0.0.1:5900`, `guest 800x480 on 800x480` | `adb shell getprop sys.boot_completed` → 1 |
| media1 | `vnc:5901` | `connected to 127.0.0.1:5901` | `xl list \| grep media1` |
| rtos1 + car | `rearcam:cluster` | `cluster-hdmi: /dev/fb0 800x480 32 bpp` | `grep vehicle /var/log/xen/console/guest-rtos1.log \| tail -3` |
| dom0 | `console` | `hdmi (/dev/fb0): console` | login prompt on the display (USB keyboard) |
| rear camera | (`rearcam:` sources) | `rear-camera: in reverse`, `/dev/video0 640x480 YUYV` | `/etc/init.d/vehicle-bench reverse` (toggle) |

Black screen: `cat /sys/class/drm/card0-HDMI-A-1/status` must be `connected`.

### 11.4 Automotive bench

```
candump vcan0                                 raw frames (0C0, 0C1)
grep vehicle /var/log/xen/console/guest-rtos1.log | tail
/etc/init.d/vehicle-bench pause               → "[vehicle] SIGNAL LOST ..."
/etc/init.d/vehicle-bench pause               → "[vehicle] SIGNAL OK again"
tail /var/log/vehicle-bench.log               can2rtos: 10s: frames 1001, max gap 24.9 ms, dropped 0
cluster-hdmi -g 1280x720 -S /tmp/c.ppm        dashboard snapshot without monitor
/etc/init.d/vehicle-bench reverse             hold reverse: rear camera on the cluster screen
candump vcan0,0C2:7FF                         gear frames: 0C2 [2] 52 00 = 'R'
tail /var/log/display-map.log                 rear-camera: in reverse / /dev/video0 640x480 YUYV
audio-mixer -c warn                           warning chime (also reverse, info)
tail /var/log/audio-mixer.log                 media: UDP ..., android: connected from 192.168.100.3
```

Real car (read-only): plug a USB CAN adapter, then in `/etc/default/vehicle-bench`:

```
IFACE=can0
SIM=0
BITRATE=500000
```

`/etc/init.d/vehicle-bench restart`. The CAN IDs and scaling are the bench's own; a real car uses
manufacturer-specific IDs, so `can2rtos` must be adapted. **Never connect vehicle-sim to a real
vehicle bus.**

### 11.5 Ignition

Wiring: ACC (12–14.4 V with spikes) **must not** reach the 3.3 V pin. Optocoupler (or 10 k/2.7 k
divider + 3.3 V zener) → header pin 7 (GPIO0_C1 = gpiochip0 line 17), external 10 k pull-down.

```
gpioget gpiochip0 17                 read the pin by hand first (1 = ACC on)
# /etc/default/ignition-watch: ENABLED=1 (ACC_ON_LEVEL=0 for an inverting optocoupler)
/etc/init.d/ignition-watch start
tail /var/log/ignition-watch.log
```

The board must be powered from permanent 12 V via a 5 V/3 A automotive DC-DC; poweroff halts the
board but does not cut 5 V, so a car install also needs a power-hold/timer relay.

### 11.6 System

```
cat /sys/class/thermal/thermal_zone{1,2}/temp      CPU, GPU in m°C (≈ 35000-42000)
speaker-test -c 2 -t sine                          sound (ALSA card 0)
reboot                                              → guests stopped, Reset cause: RST
poweroff                                            → "reboot: Power down"
```

### 11.7 Logs

`/var/log` is a link to `/var/volatile/log` (tmpfs): **all logs are lost at every reboot**. Save
them first (below). U-Boot and early Xen output exist only on the UART: start
`picocom -b 115200 /dev/ttyUSB0` before power-on to see them. Type or paste one short line at a
time: Xen buffers only 128 characters of UART input for dom0 (`SERIAL_RX_SIZE`), longer pastes
lose characters.

Live, from the build PC (dom0 `192.168.88.110`; media1 `192.168.100.4` only via dom0; dom0's `ssh`
is Dropbear, use `-y` instead of OpenSSH `-o` options):

```
picocom -b 115200 /dev/ttyUSB0                                         UART (Ctrl-a Ctrl-x quits)
ssh -t root@192.168.88.110 tail -f /var/log/display-map.log            HDMI viewer
ssh -t root@192.168.88.110 tail -f /var/log/xen/console/guest-rtos1.log
ssh -t root@192.168.88.110 tail -f /var/log/xen/console/guest-media1.log
ssh -t root@192.168.88.110 ssh -t -y root@192.168.100.4 tail -f /var/log/media-player.log
ssh -t root@192.168.88.110 xl console media1                           (Ctrl-] leaves)
```

Boot (U-Boot → Xen → dom0):

```
xl dmesg                                       Xen log: PSCI, CPUs, schedulers, guest creation
cat /var/log/dmesg                             dom0 kernel log saved at boot
dmesg                                          dom0 kernel log now (dmesg -w: follow)
cat /var/log/boot                              init scripts ("Starting ..." lines)
```

Yocto Linux (dom0):

```
cat /var/log/messages                          syslog, all services (tail -f to follow)
cat /var/log/cluster-hdmi.log                  dashboard
cat /var/log/vehicle-bench.log                 vehicle-sim / can2rtos
cat /var/log/ignition-watch.log                ignition (when enabled)
cat /var/log/android-hdmi.log                  Android screen viewer (when enabled)
cat /var/log/xen/xen-hotplug.log               vif/disk hotplug scripts
```

FreeRTOS (rtos1), written by xenconsoled (`XENCONSOLED_TRACE=guest` in `/etc/default/xencommons`):

```
cat /var/log/xen/console/guest-rtos1.log       full console (tail -f to follow)
grep '10 ms task' /var/log/xen/console/guest-rtos1.log    timing reports
grep ALERT /var/log/xen/console/guest-rtos1.log           vehicle warnings
xl console rtos1                               live console (Ctrl-] leaves)
cat /var/log/xen/xl-rtos1.log                  xl (toolstack) log
```

Android (android1):

```
cat /var/log/xen/console/guest-android1.log    kernel + init console from boot
xl console android1                            live console (Ctrl-] leaves)
adb connect 192.168.100.3:5555                 needed before the adb lines
adb logcat -d                                  app/framework log (without -d: follow)
adb logcat -d -b crash                         crashes only
adb shell dmesg                                Android kernel log
adb shell getprop sys.boot_completed           1 = boot finished
cat /var/log/xen/xl-android1.log               xl log (.1, .2: earlier starts)
cat /var/log/xen/qemu-dm-android1.log          QEMU device model log
```

`Ctrl-C` stops the following forms (`tail -f`, `dmesg -w`, `adb logcat`). A frozen Android guest
makes `adb logcat` hang: `Ctrl-C` returns the prompt.

Save everything to the SD card before a reboot (one line at a time):

```
D=/home/root/logs-$(date +%H%M%S)
mkdir -p $D
cp -r /var/log/* $D/
xl dmesg > $D/xen-dmesg.txt
dmesg > $D/dom0-dmesg-now.txt
xl list > $D/xl-list.txt
adb connect 192.168.100.3:5555
adb logcat -d > $D/android-logcat.txt
sync; ls $D
```

On the PC (card in a reader): `/media/$USER/root/home/root/logs-*`.

---

## 12. Testing and verification

### 12.1 How tests were done

All board tests ran over the UART from the PC with small Python/pyserial scripts (listen, send a
command, collect the output into `diagnostics/uart-*.log`). Files were moved PC → board by sending
`printf '\ooo...' >> file` chunks and checking `md5sum`; board → PC by throttled `od` chunks (Xen's
serial buffer drops large bursts). BusyBox lacks `head -c`, `timeout` and `base64`, so `dd`, loops
and octal `printf` were used.

New Xen or U-Boot builds were first loaded **into RAM only** (`loady` at the U-Boot prompt) and
started with `bootz`/`go`, so nothing was written to the card before it was proven.

### 12.2 Test matrix

| # | Test | Method | Expected | Result | Log |
|---|---|---|---|---|---|
| 1 | Xen HYP entry | boot | no "NS Hyp" error | ✅ | uart-xen-card.log |
| 2 | dom0 boot | boot | login, `/sys/hypervisor/type`=xen | ✅ | uart-xen-card.log |
| 3 | SMP | `xl info` | nr_cpus 4 | ✅ | uart-xen-psci.log |
| 4 | Reboot | `reboot` | Reset cause: RST | ✅ | uart-xen-reset.log |
| 5 | Autoboot | power on, no key | Xen + guests | ✅ | uart-xen-autoboot.log |
| 6 | Native fallback | sysboot | Linux without Xen | ✅ | uart-xen-autoboot.log |
| 7 | Watchdog | stop keep-alive | reset ~43 s | ✅ | uart-watchdog-test.log |
| 8 | RTOS timing | 10 s reports | ≈ 10000 µs ± 60 | ✅ 9958–10040 | uart-rtds-repro-fixed.log |
| 9 | Android boot | getprop | boot_completed=1 | ✅ | uart-final-reboot-poweroff.log |
| 10 | adb | adb connect | connected | ✅ | uart-android-adb-net.log |
| 11 | Android stability | 10 min | 0 system_server crashes | ✅ | uart-stability.log |
| 12 | Thermal | sysfs | readings | ✅ 35–42 °C | uart-final-all.log |
| 13 | CAN → RTOS | 10 s reports | 1000 frames, 0 lost | ✅ | uart-vehicle-bench.log |
| 14 | Alerts | drive cycle | overspeed, redline raise/clear | ✅ | uart-vehicle-bench.log |
| 15 | Signal loss | pause | SIGNAL LOST / OK again | ✅ | uart-vehicle-bench.log |
| 16 | Frame gaps | 10 s reports | < 100 ms | ✅ 20–35 ms | uart-session.log |
| 17 | Dashboard | `-S` snapshot | picture with live values | ✅ | cluster-board2.png |
| 18 | RTDS race | 3000 × pause/unpause | no panic | ✅ (old Xen: panic < 250) | uart-rtds-repro-*.log |
| 19 | Poweroff | `poweroff` | guests stopped, power down | ✅ | uart-final-reboot-poweroff.log |
| 20 | Guest internet | ping 8.8.8.8 | reply | ⏳ no Ethernet | – |
| 21 | HDMI picture | monitor | dashboard on screen | ⏳ no monitor | – |
| 22 | Ignition | ACC off | poweroff after 10 s | ⏳ not wired | – |
| 23 | Real CAN | adapter | frames in listen-only | ⏳ no adapter | – |
| 24 | HDMI placeholder | `xl destroy/create media1` while playing | no 640x480 placeholder on HDMI | ✅ 2026-11-04 | `/var/log/display-map.log` |
| 25 | TFT SPI activity | dom0 register/pad sampling | CLK/MOSI/CS/DC toggling, `BAUDR` 6 | ✅ 2026-11-04 | – |
| 26 | TFT picture | look at the panel | dashboard drawn | ✅ 2026-11-04 (after rewiring) | – |
| 27 | RTOS timing with TFT | 10 s reports | ≈ 10000 µs | ✅ 9941–10080 | guest-rtos1.log |
| 28 | Autostart + autologin | full reboot, UART | rtos1 + media1 up, all consoles logged in, HDMI = media1 | ✅ 2026-11-04 | UART capture |
| 29 | media1 start check | forced failure / normal starts / restarts and a power cut with the fault | restart, give up after N / "started properly", network up / video + network after 1 restart | ✅ 2026-11-04 | `/var/log/xen-guests.log` |

---

## 13. All errors and fixes

| # | Error / symptom (exact text where available) | Root cause | Fix | Where |
|---|---|---|---|---|
| 1 | Boot stops after `mmcblk0: p1 … p9` | card held a different image (9 partitions, U-Boot 2024.01) | flash the Yocto image | Stage 2 |
| 2 | Typing on the UART does nothing | adapter on UART1 (pins 8/10) | UART2 pins 32/33/34 | Stage 5 |
| 3 | `CPU: All CPU(s) started in SVC mode.` / `Xen must be entered in NS Hyp mode` | no NONSEC/VIRT for RK3288 in U-Boot | U-Boot 0001 | Stage 6 |
| 4 | Silent hang after `Starting kernel ...` | HSCTLR reset value 0x70cd087f | HSCTLR = 0x30c50830 before ERET | U-Boot 0001 |
| 5 | non-secure access faults | SoC still secure | SGRF/TZPC in `psci_board_init` | U-Boot 0001 |
| 6 | `Missing processor info: 410fc0d1` | no A12/A17 proc_info | Xen 0001 | Stage 7 |
| 7 | dom0 Oops in `rk3288_suspend_init` | L2CTLR trap → UNDEF | Xen 0002 | Stage 7 |
| 8 | dom0 abort at 0xffb23fe0 | secure DMAC window | DT: DMAC at 0xff600000 | boot script |
| 9 | dom0 hang ~2 s, Xen `NOW` negative | Linux resets timer7 (arch counter) | kernel 0001 | Stage 8 |
| 10 | `Reset cause: POR` at `xl create` (once) | probably power dip | 5 V/3 A supply | Stage 9 |
| 11 | `INIT: Id "S2" respawning too fast` | getty on Xen-owned UART | start_getty | Stage 19 |
| 12 | FreeRTOS stale console lines | MMU/caches off | enable MMU + caches | Stage 11 |
| 13 | RTOS period 10.15 ms | relative TVAL | absolute CVAL | Stage 11 |
| 14 | rtos1 100 % CPU | idle spinning | WFI idle hook | Stage 11 |
| 15 | `Xen: Platform reset did not work properly!` | no reset method | Xen 0003 | Stage 13 |
| 16 | `Cannot find the RK3288 CRU node in DT` | RK3288W CRU renamed | match both compatibles | Stage 13 |
| 17 | `Failed to bring up CPU 1 (error -19)` | no PSCI | U-Boot 0002 | Stage 15 |
| 18 | only 2 CPUs, `ALREADY_ON (-4)` | all cores released by the first mailbox write | power cores off in `psci_board_init` | Stage 15 |
| 19 | `EventHub: Could not register INotify for /dev/input` | no /dev/input | `mkdir /dev/input` | Stage 16 |
| 20 | `NullPointerException` AlarmManagerService | timerfd alarm needs CAP_WAKE_ALARM | guest kernel 0001 | Stage 16 |
| 21 | `usb 1-1: reset high-speed USB device` | GL850G hub autosuspend + adb scan | udev rule | Stage 16 |
| 22 | `Assertion '!unit_on_replq(svc)' failed at rt.c:587` | RTDS race (Xen bug) | workaround: RTDS only on CPU 3; real fix #31 | Stage 16 |
| 23 | release Xen without RTDS | RTDS only default in debug; menu needs EXPERT | `CONFIG_EXPERT=y`, `CONFIG_SCHED_RTDS=y` | Stage 19 |
| 24 | no temperature readings | cooling maps → TSADC probe deferred | `fdt rm .../cooling-maps` | Stage 19 |
| 25 | `Service xen-net does not have a SELinux domain defined` | shell-script service without domain | `seclabel u:r:su:s0` | Stage 19 |
| 26 | `bmaptool: Device or resource busy` | auto-mounted partition | `umount` again | Section 10 |
| 27 | `/dev/sda` is a 3.2 GB regular file; `lsblk: /dev/sda: not a block device` | flashed with no card present | `rm` only when `ls -l` shows `-`; recreate node by reinserting card | Section 10 |
| 28 | SurfaceFlinger `no suitable EGLConfig` | 32 bpp xenfb | guest kernel 0003 (16 bpp) | Stage 20 |
| 29 | apps `Failed to choose config`, then guest freezes | no GLES 2.0; with software UI the vtimer IRQ stalls | **unsolved** → headless | Stage 20 |
| 30 | dashboard RTOS lamp without data | `/var/log/xen/console` missing | xen-tools bbappend volatile + TRACE | Stage 22 |
| 31 | FreeRTOS max frame gap ~105 ms | notify per read → xenconsoled rate limit 30/200 ms | notify only when ring nearly full | Stage 23 |
| 32 | `CPU3: Unexpected Trap: Data Abort` in `rt.c#repl_timer_handler` | unit left on RTDS replq after pause | Xen 0004 + 0005 (upstream backports) | Stage 25 |
| 33 | Linux commands at the U-Boot prompt (`Unknown command`) | Enter sent during autoboot countdown | `boot`; only listen until `login:` | Stage 25 |
| 34 | Board went silent twice under full load | suspected power supply | power-cycle; better PSU | Section 14 |
| 35 | Launcher3 / SystemUI crash-loop | HWUI needs GLES 2.0 | accepted (headless, adb works) | Section 14 |
| 36 | HDMI shows `This VM has no graphic display device` during playback | `guest-vnc` reconnected internally after a media1 restart, before xen-fbfront connected | `guest-vnc -1`; `guest_fb_ready` checks frontend state 4 | 9.12.2 |
| 37 | rtos1 TFT blank although `[tft] ILI9341 320x240 on SPI2 initialised` | SPI 24.75 MHz > 10 MHz; CS never deasserted | `SPI_BAUD_DIV` 6 (8.25 MHz); CS toggled per command | 9.12.3 |
| 38 | TFT blank after rewiring the panel | panel lost its init sequence | `xl destroy rtos1; rtos1-start` | 9.12.3 |
| 39 | media1 `INIT: ... wait: unknown action field`, `Segmentation fault`, `EXT4-fs error ... checksum invalid` (cold boots) | guest disk reads corrupted in the first seconds after boot (cause unknown) | `xen-guests` start check (crash markers + login + ping) restarts media1 automatically | 9.12.5 |

---

## 14. Known limitations

- **Android is headless.** No GPU, display or sound for the guest: Xen 4.16 has no RK3288 IOMMU
  support (no device passthrough), no PV sound backend for Android 7. The only GLES is the 1.x
  software renderer; Android's UI toolkit needs GLES 2.0, so Launcher3 and SystemUI restart in a
  loop (system_server, services and adb are fine). The PV screen/touch path exists but freezes the
  guest. Android 7.0 is the newest prebuilt ARM32 image; SELinux is permissive.
- **License:** the Android SDK system image is under the Android SDK License Agreement –
  development use only, do not redistribute.
- **Bring-up security:** U-Boot opens the whole DDR and all peripherals to the non-secure world; the
  PSCI monitor lives in reserved but not TrustZone-protected RAM.
- **RTDS** only on CPU 3 (design choice; the scheduler bug itself is fixed now). RTOS jitter about
  ±2 µs idle, up to ±60 µs when Android is busy (shared L2 cache and memory bus).
- **No CPU frequency scaling** under Xen 4.16; CPUs stay at 500 MHz (APLL 1 GHz, U-Boot setting).
- **Automotive:** a bench and listen-only monitoring system, not certified (ISO 26262); it must not
  control anything in a car. CAN reaches FreeRTOS through dom0 (Linux), so the frame path has dom0
  latency (≤ ~35 ms measured); only FreeRTOS's checks are real-time.
- **Power:** two silent hangs under full load (4 CPUs, Android, QEMU, long UART transfers) until
  power-cycled; use a solid 5 V / 3 A supply with a short cable.
- **Not tested on hardware:** guest internet (no Ethernet), HDMI picture (no monitor), ignition (not
  wired), real CAN bus (no adapter).
- **Part 6 tested on hardware 2026-10-27** (`diagnostics/part6/RESULTS.md`): dom0 320 MB, android1
  512 MB, media1 192 MB, rtos1 4 MB, shrunk android-system (613 MB), RTDS 1000/1000 at boot
  (`xl sched-rtds -d rtos1 -v all`), media1 on dom0's kernel. **Still untested:** display-map on
  real displays, udl USB displays, HDMI pixel-clock patch 0002.
- **USB displays:** only DisplayLink DL-1x0/DL-1x5 (udl); no GPU, so all screens are CPU-copied
  (VNC raw encoding) at 500 MHz.
- **Android 10:** in progress; software rendering on ARM32 without a GPU is unproven.
- **Since 2026-11-04 (Stage 27) there is no Android guest**; the Android items above are history.
- **media1 cold-boot init failure** (9.12.5): recurring after power cuts, handled by the
  `xen-guests` start check (automatic restart); root cause not found.
- **TFT:** transmit only (no readback, so a missing panel is not detected); initialised only at rtos1
  start; touch (XPT2046) unused.

---

## 15. Recovery plan

The board's own eMMC and bootloaders are never written; everything is on the SD card, so every
failure is fixed from the PC.

| Problem | What to do |
|---|---|
| A guest misbehaves | `xl destroy <name>; /etc/init.d/xen-guests start`. Don't autostart: `XEN_GUESTS=""` in `/etc/default/xen-guests` |
| Xen or dom0 hangs | the hardware watchdog resets the board after ~45 s; otherwise power-cycle |
| dom0 shell blocked, Xen alive | `Ctrl-a` ×3 (input to Xen), `r` = scheduler dump, `R` = reboot the machine; `Ctrl-a` ×3 back to dom0 |
| USB enumeration / `lsusb` hangs | a uvcvideo oops left the device lock held (before kernel 0003): reboot |
| Android unreachable 1–2 min after boot | s2idle suspend: check `/sys/power/wake_lock` (`xen`) and `PM: suspend entry` in `/var/log/xen/console/guest-android1.log` |
| Android screen off again | headless: drop `vfb` in `/etc/xen/android1.cfg`, extra `video=vfb:640x480-16@60 vfb.videomemorysize=4194304` instead of the xen_fbfront/qemu options |
| Xen does not boot | press a key at "Hit any key to stop autoboot", then `sysboot mmc 1:6 any ${scriptaddr} /native/extlinux.conf` (Linux without Xen). boot.scr also falls back by itself |
| Debug a Xen boot | at the U-Boot prompt `loady ${xen_addr}` a debug Xen and run the xen-boot.cmd lines by hand; nothing is written |
| Android data broken | reflash the card (or `dd` android-userdata.img to p9) |
| Card does not boot | reflash with bmaptool; a known-good original image is in `diagnostics/baseline/` |

Never type `saveenv` at the U-Boot prompt.

---

## 16. Working rules and safety

Rules agreed at the start and followed throughout:

1. The SD card is never flashed automatically – the user flashes with bmaptool; the device is
   checked first (`ls -l /dev/sda` must start with `b`).
2. No destructive disk commands; no `saveenv`, `erase`, `write` or other persistent bootloader
   commands.
3. The bootloader is not replaced without a recovery plan: new U-Boot/Xen builds were tested from
   RAM (`loady`) before they went onto a card; the card is the only boot medium and can always be
   reflashed.
4. No claim of a hardware test without evidence: every ✅ in this document has a UART log.
5. Build directories, shared state and downloads were never deleted; generated `.config` files were
   never edited – changes go through config fragments and patches in the layer.
6. Automotive: simulation only on a virtual bus; a real car only listen-only; nothing transmits on
   a vehicle bus.

---

## 17. Future work

| Item | Notes |
|---|---|
| Test the dashboard on a real HDMI monitor | should appear automatically |
| Test guest internet | needs an Ethernet cable at boot |
| Wire and test ignition-watch | optocoupler on pin 7, power-hold relay |
| Real CAN adapter | candleLight/PEAK, listen-only, adapt IDs to the car |
| Android display | needs GLES 2.0 (virtio-gpu/virgl not available in Xen 4.16 ARM) or a fix for the vtimer freeze |
| Android 10 guest | build `lineage_arm-userdebug`, binder-64 guest kernel, SwiftShader + PV-framebuffer composer (9.10) |
| Part 6 bring-up | flash with Android 7 first; check xl list, RTOS timing, media1, display-map, temperature |
| Newer Xen (4.17+) | upstream RTDS fixes, cpupool improvements; would drop patches 0004/0005 |
| Upstreaming | Xen 0001/0002/0003, kernel 0001 are upstream candidates |
| Security hardening | keep secure DDR regions, put the PSCI monitor in TrustZone RAM |
| CAN directly into FreeRTOS | device passthrough of a CAN controller would remove dom0 latency (needs IOMMU) |

---

## 18. Appendix

### 18.1 Image history

| Date / time | Image (`tinker-xen-test-image-tinker-board-…rootfs.wic`) | sha256 (start) | Contents |
|---|---|---|---|
| 2026-10-22 | `core-image-minimal-…20261022043621` | d9cdb9a5 | original baseline |
| 10-23 09:58 | 20261023095857 | e066744b | first test image, debug Xen |
| 10-23 11:10 | 20261023111057 | 0bc653ca | U-Boot HYP |
| 10-23 15:59 | 20261023155925 | 7e957065 | Xen + dom0 boots |
| 10-23 18:19 | 20261023181955 | 2762f72a | first guest |
| 10-24 05:58 | 20261024055832 | d3607e17 | networking |
| 10-24 07:27 | 20261024072751 | 72ef08b5 | FreeRTOS |
| 10-24 07:43 | 20261024074358 | 4654864b | RTDS |
| 10-24 12:44 | 20261024124409 | a8889f49 | reboot fix |
| 10-24 12:55 | 20261024125534 | 0e7ead10 | autoboot |
| 10-24 13:24 | 20261024132400 | 716468e1 | PSCI / SMP |
| 10-24 13:47 | 20261024134726 | 34f4e3f8 | Android |
| 10-24 14:01 | 20261024140152 | 80e38cf8 | guest1 removed |
| 10-24 14:32 | 20261024143227 | 172618c9 | Android fixes |
| 10-24 14:53 | 20261024145333 | 141d6f54 | cpupools |
| 10-24 15:13 | 20261024151313 | d27e5aaf | quiet RTOS |
| 10-24 16:33 | 20261024163357 | d0cdb27c | production hardening |
| 10-25 01:48 | 20261025014834 | 25b48f7c | final headless |
| 10-25 07:22 | 20261025072211 | e23e81e7 | stable headless after screen test |
| 10-25 08:31 | 20261025083123 | 59e8c585 | automotive bench + dashboard |
| 10-25 14:52 | (ignition build) | 0a623c4a | burst fix, ignition – hit the RTDS panic |
| **10-25 15:14** | **20261025094250** | **99a3fec6** | **RTDS fix – final, flashed and verified** |
| 10-27 16:19 | 20261027104724 | – | Part 6 + rear camera/audio (flashed; webcam oops, 8 kHz output) |
| **10-27 17:25** | **20261027115058** | **a1263bb0** | **kernel 0003, Android screen + keep-awake, 48 kHz output, audio fixes – to flash** |
| 11-04 11:55 | 20261104062458 | 3c999132 | Android removed; `guest-vnc -1` HDMI placeholder fix |
| 11-04 12:01 | 20261104063056 | bd374207 | + rtos1 TFT fix (8.25 MHz SPI, CS per command); autostart + autologin verified |
| 11-04 12:55 | 20261104072454 | df85c441 | + media1 start check in `xen-guests` (login prompt only) |
| **11-04 13:20** | **20261104074956** | **8dd49e11** | **media1 start check: crash markers, network ping, 45 s – current** |

### 18.2 Log index (`~/xen-hypervisor/diagnostics/`)

| Log | Content |
|---|---|
| REPORT.md | engineering report, sections A–Z |
| BOARD-TESTS.md | manual hardware test procedures |
| uart-boot.log | first Yocto boot, SVC mode |
| uart-xen-*.log | Xen bring-up, guest, net, RTDS, reset, autoboot, PSCI, Android, pools |
| uart-final-all.log, uart-final-reboot-poweroff.log | production verification |
| uart-stability.log | 10-minute stability run |
| uart-display-touch*.log, uart-android-screen*.log, uart-hang-*.log | screen experiment and freeze |
| uart-vehicle-bench.log | automotive bench test |
| uart-rtds-panic.log, uart-rtds-repro-old.log, uart-rtds-repro-fixed.log | RTDS panic and fix |
| uart-flash-rtdsfix.log | final boot |
| bitbake-*.log | every build, exit codes checked |
| baseline/ | original image and U-Boot binaries |

### 18.3 Glossary

| Term | Meaning |
|---|---|
| Xen | type-1 hypervisor; runs below all operating systems |
| dom0 / Domain-0 | the privileged Linux VM that controls Xen and owns the hardware |
| domU / guest | an unprivileged VM (rtos1, android1) |
| HYP mode | ARMv7 hypervisor CPU mode (EL2); Xen must start in it, non-secure |
| PSCI | ARM firmware interface to start/stop CPUs and reset the system |
| SGRF / TZPC | RK3288 security controllers deciding what is secure-only |
| CRU / PMU | clock & reset unit / power management unit |
| cpupool | a group of physical CPUs with its own Xen scheduler |
| credit2 | Xen's default fair-share scheduler |
| RTDS | Xen's real-time (EDF, period/budget) scheduler |
| PV console | paravirtual console: a shared ring page + event channel |
| event channel | Xen's virtual interrupt between domains |
| xenconsoled / xenstored | dom0 daemons for guest consoles / the configuration store |
| vcan | Linux virtual CAN bus |
| listen-only | CAN mode in which the controller never transmits, not even ACK |
| ACC | accessory/ignition line of a car (12 V when the key is on) |
| WKS / wic | Yocto's SD-card image layout file / image creator |
| bbappend | Yocto file that modifies another layer's recipe |
| bmaptool | fast, verified image writer using a block map |
