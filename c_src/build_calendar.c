#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>

#include <erl_nif.h>

#define MAX_GENERATED 60

static ERL_NIF_TERM do_build_calendar(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  // Arguments
  long int nowSeconds, startTimeSeconds, endTimeSeconds, frequencySeconds;
  int repeat;

  // Fetch arguments.
  enif_get_long(env, argv[0], &nowSeconds);
  enif_get_long(env, argv[1], &startTimeSeconds);
  enif_get_long(env, argv[2], &endTimeSeconds);
  enif_get_int(env, argv[3], &repeat);
  enif_get_long(env, argv[4], &frequencySeconds);

  // Data used to build the calendar.
  long int gracePeriodSeconds;
  gracePeriodSeconds = nowSeconds - 60;
  long int step = frequencySeconds * repeat;

  // printf("now: %li\r\ngrace: %li\r\nstart: %li\r\nend: %li\r\n\r\n", nowSeconds, gracePeriodSeconds, startTimeSeconds, endTimeSeconds);

  // iterators for loops
  long int i, j;

  // build our events array, fill it with zeroes.
  long int events[MAX_GENERATED];
  for(i = 0; i < MAX_GENERATED; i++)
    events[i] = 0;

  // put up to MAX_GENERATED events into the array
  for(j = 0, i = startTimeSeconds; (i < endTimeSeconds) && (j < MAX_GENERATED); i += step) {
    // if this event (i) is after the grace period, add it to the array.
    if(i > gracePeriodSeconds) {
      events[j] = i;
      events[j] -= (events[j] % 60);
      j++;
    }
  }

  // Count up our total generated events
  for(i=0, j=0; j<MAX_GENERATED; j++) { if(events[j] > 0) { i++; } }

  // Build the array to be returned.
  ERL_NIF_TERM retArr [i];
  for(j=0; j<i ; j++)
    retArr[j] = enif_make_long(env, events[j]);

  // we survived.
  return enif_make_list_from_array(env, retArr,  i);
}

static ErlNifFunc nif_funcs[] =
{
    {"do_build_calendar", 5, do_build_calendar}
};

ERL_NIF_INIT(Elixir.Farmbot.Repo.FarmEvent, nif_funcs, NULL,NULL,NULL,NULL)
