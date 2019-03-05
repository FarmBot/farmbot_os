#include <stdlib.h>
#include <string.h>
#include <limits.h>

#include <erl_nif.h>

// Enough space for one event every minute for 20 years.
#define MAX_GENERATED LONG_MAX

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
  long int gracePeriodSeconds = nowSeconds - 60;
  long int step = frequencySeconds * repeat;

  // iterator for loops
  long int i;

  // count up to MAX_GENERATED items
  for(i = startTimeSeconds; i < endTimeSeconds; i += step) {
    // if this event (i) is after the grace period this is the next event.
    if(i > gracePeriodSeconds) {
      return enif_make_long(env, i);
    }
  }
  return enif_make_long(env, startTimeSeconds);
}

static ErlNifFunc nif_funcs[] =
{
    {"do_build_calendar", 5, do_build_calendar}
};

ERL_NIF_INIT(Elixir.FarmbotCore.Asset.FarmEvent, nif_funcs, NULL,NULL,NULL,NULL)
