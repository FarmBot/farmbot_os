#include <stdio.h>
#include <stdlib.h>

int main( int argc, char *argv[] )  {
  // args: 1 now, 2: start_time, 3: end_time, 4: repeat, 5: frequencySeconds
   if( argc != 6 ) {
     printf("Requires 5 args %d\n", argc);
     return -1;
   }

   // args
   unsigned long long nowSeconds;
   unsigned long long startTimeSeconds;
   unsigned long long endTimeSeconds;
   int repeat;
   unsigned long long frequencySeconds;

   sscanf(argv[1], "%llu", &nowSeconds);
   sscanf(argv[2], "%llu", &startTimeSeconds);
   sscanf(argv[3], "%llu", &endTimeSeconds);
   repeat = atoi(argv[4]);
   sscanf(argv[5], "%llu", &frequencySeconds);


   unsigned long long gracePeriodSeconds;
   // now minus 1 minute
   gracePeriodSeconds = nowSeconds - 60;

  //  printf("now: %llu\ngrace: %llu\nstart: %llu\nend: %llu\n\n", nowSeconds, gracePeriodSeconds, startTimeSeconds, endTimeSeconds);

   unsigned long long step = frequencySeconds * repeat;


   unsigned long long i;
   unsigned int j;
   unsigned long long events[60];
   for(i = 0; i < 60; i++) {events[i] = 0;}
   for(j = 0, i = startTimeSeconds; (i < endTimeSeconds) && (j < 60); i += step) {
    //  printf("i: %llu\n", i);
     // if this event (i) is after the grace period, add it to the array.
     if(i > gracePeriodSeconds) {
       j++;
       events[j] = i;
       events[j] -= (events[j] % 60);
      //  printf("j: %d\n", j);
     }
   }

   for(j=0; j<60; j++) {
     if(events[j] > 0) {
       printf("%llu ", events[j]);
     }
   }
   printf("\n");
}
