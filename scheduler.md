# Problem
* we need a way to manage processes between the frontend and the bot
  * Obviously not EVERY process, but just a small subset of them
    * Farmware, Sequences, Regimens and FarmEvents
  * Preferable an interface that can be used to represent all of these things
    without being too specific to any, but not to generic to be useful.

we could lay it out in a number of ways
```js
{
  process_info: {
    "water plants erry day": {
      type: "regimen",
      status: "OK"
    },
    "something else":{
      type: "event",
      status: "failed"
    },
    "plant detection": {
      type: "farmware",
      status: "maybe not string typing"
    }
  }

}
```

and then have `celery_script` commands:
```js
{
  kind: "start_process",
  args: {name: "water plants erry day"}
}

{
  kind: "stop_process",
  args: {name: "water plants erry day"}
}
```

this looks nice, but also deals with strings which is kind of scary.
Plus they need to be converted into Atoms on the bot, which is technically
frowned upon.


it could also be organized as:
```js
{
  process_info: {
    events: [{name: "something user friendly", process_id: 13, status: "running"}],
    regimens: [{name: "water teh plantzz", process_id: 1234, status: "more string typing here?"}],
    farmwares: [{name: "plant-detection", process_id: 2, status: "completely broken"}]
  }
}
```

then the `celery_script`s would look like
```js
{kind: "start_process", args: {process_id: 13}}

{kind: "stop_process", args: {process_id: 2, reason: "maybe we dont want a reason"}}
```

```js
{
  // these are the "user accessable" processes. things can only be started if they
  // are indexed in here.
  process_info: {
    events: [
      {name: "user friendly tag?", uuid: "1234-asdf-1111", status: "running"},
      {name: ":+1:", uuid: "6767-1234-asdf", status: "fuuuuu"}
    ],
    regimens: [
      {name: "water plants @ 4:00 pm", uuid: "1111-aaaa-1234", status: "failed"}
    ],
    farmwares: [
      {name: "herp derp", uuid: "1234-abcd-6789", status: "nothing to see here"}
    ]
  }
}

// celery script nodes would be
{
  kind: "start_process", args: {uuid: "1234-abcd-6789"}
}

{
  kind: "stop_process", args: {uuiid: "1234-asdf-1111"}
}
```
