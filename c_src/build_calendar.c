#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>

#include <erl_nif.h>

static ERL_NIF_TERM do_build_calendar(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  long int nowSeconds;
  long int startTimeSeconds;
  long int endTimeSeconds;
  int repeat;
  long int frequencySeconds;

  enif_get_long(env, argv[0], &nowSeconds);
  enif_get_long(env, argv[1], &startTimeSeconds);
  enif_get_long(env, argv[2], &endTimeSeconds);
  enif_get_int(env, argv[3], &repeat);
  enif_get_long(env, argv[4], &frequencySeconds);

  long int gracePeriodSeconds;
  gracePeriodSeconds = nowSeconds - 60;
  long int step = frequencySeconds * repeat;
  printf("now: %li\r\ngrace: %li\r\nstart: %li\r\nend: %li\r\n\r\n", nowSeconds, gracePeriodSeconds, startTimeSeconds, endTimeSeconds);

  // iterators
  long int i;
  long int j;

  // build our events array, fill it with zeroes.
  long int events[60];
  for(i = 0; i < 60; i++) {events[i] = 0;}

  // put up to 60 events into the array
  for(j = 0, i = startTimeSeconds; (i < endTimeSeconds) && (j < 60); i += step) {
    // if this event (i) is after the grace period, add it to the array.
    if(i > gracePeriodSeconds) {
      events[j] = i;
      events[j] -= (events[j] % 60);
      j++;
    }
  }

  // Count up our total generated events
  int count = 0;
  for(j=0; j<60; j++) { if(events[j] > 0) { count++; } }

  // Build the array to be returned.
  ERL_NIF_TERM arr[count];

  // size_t stringSize = 21;
  // char buffer[stringSize];

  // ErlNifBinary outputData;
  // enif_alloc_binary(stringSize, &outputData);

  for(j=0; j<count; j++) {
    // // Build a timeinfo struct.
    // struct tm * timeinfo;
    // timeinfo = localtime(&events[j]);
    //
    // // Format the timeinfo struct as a iso datetime.
    // strftime(buffer, stringSize, "%FT%TZ", timeinfo);
    //
    // printf("%s\r\n", buffer);
    // memcpy(outputData.data, buffer, strlen(buffer));
    //
    // // Add the binary to the array.
    // // arr[j] = enif_make_binary(env, &outputData);
    arr[j] = enif_make_long(env, events[j]);
  }

  // Release the binary
  // enif_release_binary(&outputData);

  // we survived.
  return enif_make_list_from_array(env, arr, count);
}

static ErlNifFunc nif_funcs[] =
{
    {"do_build_calendar", 5, do_build_calendar}
};

ERL_NIF_INIT(Elixir.Farmbot.Repo.FarmEvent, nif_funcs, NULL,NULL,NULL,NULL)
