// SPDX-License-Identifier: MIT
/*
 * media-ctl: pause and resume media1's player from dom0.
 *
 * Listens for UDP datagrams "pause" and "play" (dom0's rear-camera sends the
 * current state every second while it runs). "pause" stops every ffmpeg
 * process (SIGSTOP): the picture stays still and the sound stops. "play"
 * lets them run again (SIGCONT); media-play's realtime filters then carry on
 * from where the video stopped instead of racing to catch up.
 *
 * Safety: when paused and nothing has arrived for TIMEOUT_S (dom0's
 * rear-camera stopped, network gone) the player is resumed, so the video
 * never stays frozen for good.
 *
 *   media-ctl [-p port]        (default 5602, all addresses)
 */

#include <ctype.h>
#include <dirent.h>
#include <netinet/in.h>
#include <poll.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <time.h>
#include <unistd.h>

#define TIMEOUT_S 5.0

/* send sig to every process whose name is "ffmpeg"; returns how many */
static int signal_player(int sig)
{
	DIR *d = opendir("/proc");
	struct dirent *e;
	int n = 0;

	if (!d)
		return 0;
	while ((e = readdir(d))) {
		char path[300], comm[32] = "";
		FILE *f;

		if (!isdigit((unsigned char)e->d_name[0]))
			continue;
		snprintf(path, sizeof(path), "/proc/%s/comm", e->d_name);
		f = fopen(path, "r");
		if (!f)
			continue;
		if (fgets(comm, sizeof(comm), f) && strcmp(comm, "ffmpeg\n") == 0 &&
		    kill(atoi(e->d_name), sig) == 0)
			n++;
		fclose(f);
	}
	closedir(d);
	return n;
}

static double now(void)
{
	struct timespec t;

	clock_gettime(CLOCK_MONOTONIC, &t);
	return t.tv_sec + t.tv_nsec / 1e9;
}

int main(int argc, char **argv)
{
	struct sockaddr_in a = { .sin_family = AF_INET, .sin_addr.s_addr = htonl(INADDR_ANY) };
	int port = 5602, s, opt, paused = 0;
	double last = 0;

	while ((opt = getopt(argc, argv, "p:")) != -1) {
		if (opt == 'p' && atoi(optarg) > 0) {
			port = atoi(optarg);
		} else {
			fprintf(stderr, "usage: %s [-p port]\n", argv[0]);
			return 2;
		}
	}
	setvbuf(stdout, NULL, _IOLBF, 0);

	a.sin_port = htons(port);
	s = socket(AF_INET, SOCK_DGRAM, 0);
	if (s < 0 || bind(s, (struct sockaddr *)&a, sizeof(a))) {
		perror("media-ctl: udp");
		return 1;
	}
	printf("media-ctl: listening on udp port %d\n", port);
	/* a player left stopped by an earlier media-ctl runs again */
	signal_player(SIGCONT);

	for (;;) {
		struct pollfd p = { .fd = s, .events = POLLIN };
		char buf[32];
		ssize_t n;

		if (poll(&p, 1, 500) > 0 && (n = recv(s, buf, sizeof(buf) - 1, 0)) > 0) {
			buf[n] = 0;
			buf[strcspn(buf, "\r\n")] = 0;
			last = now();
			if (strcmp(buf, "pause") == 0) {
				/* every time: also catches an ffmpeg started meanwhile */
				int k = signal_player(SIGSTOP);

				if (!paused)
					printf("media-ctl: pause (%d ffmpeg stopped)\n", k);
				paused = 1;
			} else if (strcmp(buf, "play") == 0) {
				if (paused)
					printf("media-ctl: play (%d ffmpeg resumed)\n",
					       signal_player(SIGCONT));
				paused = 0;
			}
		}
		if (paused && now() - last > TIMEOUT_S) {
			printf("media-ctl: no word from dom0 for %.0f s, playing again (%d)\n",
			       TIMEOUT_S, signal_player(SIGCONT));
			paused = 0;
		}
	}
}
