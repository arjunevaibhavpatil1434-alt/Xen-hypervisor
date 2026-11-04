// SPDX-License-Identifier: MIT
/*
 * media-link: dom0's link to the media1 guest, which owns the rear camera and
 * the sound (both USB devices, exported to it with USB/IP by usb-share).
 *
 *   gear     every gear frame (CAN ID 0x0C2) seen on the vehicle bus (receive
 *            only) goes to media1's rear-camera as a raw struct can_frame in
 *            one UDP datagram (port 5603).
 *   chimes   chime requests written to the FIFO /run/audio-mixer/chime (one
 *            name per line, e.g. by vehicle-chimes) go to media1's
 *            audio-mixer as UDP datagrams (port 5604).
 *
 *   media-link [-i vcan0] [-H 192.168.100.4] [-g 5603] [-c 5604]
 *   media-link -s warn|reverse|info     ask the running media-link for a chime
 */

#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/can.h>
#include <linux/can/raw.h>
#include <net/if.h>
#include <netinet/in.h>
#include <poll.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#define ID_GEAR		0x0C2
#define CHIME_DIR	"/run/audio-mixer"
#define CHIME_FIFO	CHIME_DIR "/chime"

static int chime_client(const char *name)
{
	int fd = open(CHIME_FIFO, O_WRONLY | O_NONBLOCK);

	if (fd < 0) {
		fprintf(stderr, "media-link: not running (%s)\n", strerror(errno));
		return 1;
	}
	if (write(fd, name, strlen(name)) < 0 || write(fd, "\n", 1) < 0) {
		perror(CHIME_FIFO);
		return 1;
	}
	close(fd);
	return 0;
}

static int can_open(const char *ifname)
{
	struct sockaddr_can addr = { .can_family = AF_CAN };
	struct can_filter flt = { .can_id = ID_GEAR, .can_mask = CAN_SFF_MASK };
	int s = socket(PF_CAN, SOCK_RAW | SOCK_NONBLOCK, CAN_RAW);

	addr.can_ifindex = if_nametoindex(ifname);
	if (s < 0 || !addr.can_ifindex ||
	    setsockopt(s, SOL_CAN_RAW, CAN_RAW_FILTER, &flt, sizeof(flt)) ||
	    bind(s, (struct sockaddr *)&addr, sizeof(addr))) {
		if (s >= 0)
			close(s);
		return -1;
	}
	return s;
}

static double since(const struct timespec *t)
{
	struct timespec now;

	clock_gettime(CLOCK_MONOTONIC, &now);
	return (now.tv_sec - t->tv_sec) + (now.tv_nsec - t->tv_nsec) / 1e9;
}

int main(int argc, char **argv)
{
	const char *ifname = "vcan0";
	struct sockaddr_in gear_to = { .sin_family = AF_INET }, chime_to;
	struct timespec last_try = { 0 };
	int opt, gear_port = 5603, chime_port = 5604, can = -1, out, fifo, warned = 0;
	unsigned long frames = 0;
	char line[64];
	size_t len = 0;

	inet_aton("192.168.100.4", &gear_to.sin_addr);
	while ((opt = getopt(argc, argv, "i:H:g:c:s:")) != -1) {
		switch (opt) {
		case 'i': ifname = optarg; break;
		case 'H': if (!inet_aton(optarg, &gear_to.sin_addr)) return 2; break;
		case 'g': gear_port = atoi(optarg); break;
		case 'c': chime_port = atoi(optarg); break;
		case 's': return chime_client(optarg);
		default:
			fprintf(stderr, "usage: %s [-i can-iface] [-H media1-addr] [-g gear-port] "
				"[-c chime-port]\n       %s -s warn|reverse|info\n", argv[0], argv[0]);
			return 2;
		}
	}
	setvbuf(stdout, NULL, _IOLBF, 0);
	signal(SIGPIPE, SIG_IGN);

	chime_to = gear_to;
	gear_to.sin_port = htons(gear_port);
	chime_to.sin_port = htons(chime_port);
	out = socket(AF_INET, SOCK_DGRAM, 0);

	mkdir(CHIME_DIR, 0755);
	if (mkfifo(CHIME_FIFO, 0600) && errno != EEXIST) {
		perror(CHIME_FIFO);
		return 1;
	}
	/* read and write: the FIFO never reports end of file between writers */
	fifo = open(CHIME_FIFO, O_RDWR | O_NONBLOCK);
	if (out < 0 || fifo < 0) {
		perror("media-link");
		return 1;
	}
	printf("media-link: gear %s -> %s:%d, chimes %s -> port %d\n", ifname,
	       inet_ntoa(gear_to.sin_addr), gear_port, CHIME_FIFO, chime_port);

	for (;;) {
		struct pollfd p[2] = { { .fd = fifo, .events = POLLIN }, { .fd = can, .events = POLLIN } };
		struct can_frame f;
		char c;

		/* the CAN interface may come up after us (vehicle-bench) */
		if (can < 0 && since(&last_try) >= 2.0) {
			can = can_open(ifname);
			if (can >= 0)
				printf("media-link: listening on %s\n", ifname);
			else if (!warned)
				fprintf(stderr, "media-link: %s: %s (trying again every 2 s)\n",
					ifname, strerror(errno));
			warned = 1;
			clock_gettime(CLOCK_MONOTONIC, &last_try);
			p[1].fd = can;
		}
		poll(p, 2, 500);

		while (can >= 0 && recv(can, &f, sizeof(f), 0) == sizeof(f))
			if (f.can_id == ID_GEAR) {
				sendto(out, &f, sizeof(f), MSG_DONTWAIT,
				       (struct sockaddr *)&gear_to, sizeof(gear_to));
				if (++frames == 1)
					printf("media-link: first gear frame sent\n");
			}
		if (can >= 0 && (p[1].revents & (POLLERR | POLLHUP | POLLNVAL))) {
			printf("media-link: %s gone\n", ifname);
			close(can);
			can = -1;
		}

		while (read(fifo, &c, 1) == 1) {
			if (c != '\n') {
				if (len < sizeof(line) - 1)
					line[len++] = c;
				continue;
			}
			line[len] = '\0';
			if (len) {
				printf("media-link: chime %s\n", line);
				sendto(out, line, len, MSG_DONTWAIT,
				       (struct sockaddr *)&chime_to, sizeof(chime_to));
			}
			len = 0;
		}
	}
}
