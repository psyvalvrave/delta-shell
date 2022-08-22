#include <netinet/in.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <sys/socket.h>
#include <sys/types.h> 
#include <syslog.h>
#include <unistd.h>
#include <pthread.h>

#include "sudba.h"
#include "susql-parser.h"

/* Port for the server */
static int PORT= 8000;

/* Are we done yet? */
static bool done = false;

static bool sudba_initialize(int argn, char *argv[])
{
  /* 1 */
  if (argn > 2 || (argn == 2 && ((PORT = atoi(argv[1])) <= 0))) {
    fprintf(stderr, "Usage: %s [port-number]\n", argv[0]);
    return false;
  }
  
  /* 2 */
  if (-1 == chdir(DB_WD)) {
    perror(DB_WD);
    return false;
  }
  
  /* 3 */
  FILE *pidfile = fopen(DB_PIDFILE, "w");
  if (!pidfile || fprintf(pidfile, "%d\n", getpid()) <= 0) {
    perror(DB_PIDFILE);
    return false;
  }
  fclose(pidfile);
  
  /* 4 */
  openlog(DB_NAME, LOG_CONS | LOG_PID | LOG_NDELAY, LOG_LOCAL1);
  syslog(LOG_INFO, "Started");
  closelog();

  return true;
}

/* Convert to a daemon
 * https://stackoverflow.com/questions/17954432/creating-a-daemon-in-linux 
 */
static bool sudba_daemonize()
{
  return true;
}

/* 
 * Terminate the main loop 
 * kill -USR1 `cat /tmp/sudba/sudba.pid`
 */
static void sudba_terminate(int signo)
{
  fputs("Terminated by USR1. Will exit after the next request.\n", stderr);
  done = true;
}

/* Hepper funcion to start the parser */
static void *sudba_start_parser_thread(void *sock)
{
  fputs("Request... ", stderr); // Not needed in production
  sudba_parse(*(int *)sock);
  fputs("Done!\n", stderr); // Not needed in production
  return NULL;
}

/* The main function */
int main(int argn, char *argv[])
{
  int status = sudba_initialize(argn, argv);
  if (status == false) return EXIT_FAILURE;
  
  struct sockaddr_in serv_addr, cli_addr; 
  int sockfd = socket(AF_INET, SOCK_STREAM, 0);
  if (-1 == sockfd) {
    perror("socket");
    return EXIT_FAILURE;
  }
  
  bzero((char *) &serv_addr, sizeof(serv_addr));
  serv_addr.sin_family = AF_INET;
  serv_addr.sin_addr.s_addr = INADDR_ANY;
  serv_addr.sin_port = htons(PORT);
  if (   -1 == bind(sockfd, (struct sockaddr *) &serv_addr, sizeof(serv_addr))
      || -1 == listen(sockfd, 5)) {
    perror("bind/listen");
    return EXIT_FAILURE;
  }
  unsigned clilen = sizeof(cli_addr);
  signal(SIGPIPE, SIG_IGN);
  signal(SIGUSR1, sudba_terminate);

  /* Convert to a daemon (when implemented) */
  if(!sudba_daemonize())
    return EXIT_FAILURE;
  
  /* The main loop */
  while(!done) {
    int newsockfd = accept(sockfd, (struct sockaddr *) &cli_addr, &clilen);
    if (-1 == newsockfd) { // What can we do? :(
      continue;
    }
    pthread_t thread;
    pthread_create(&thread, NULL, sudba_start_parser_thread, (void*)&newsockfd);
  }
  return EXIT_SUCCESS;
}

/* Error reporting function */
void yyerror(YYLTYPE* yyllocp, yyscan_t unused, FILE* yyoutfile,
	     const char* msg)
{
  // Make some compilers happy
  yyllocp = NULL;
  fprintf(yyoutfile, HTTP_VER " 400 Bad Request %s\n\r", msg);
}
