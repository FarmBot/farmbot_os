import * as React from "react";
import { render } from "react-dom";
import { Main } from "./main";
import { state } from "./state";
import { useStrict } from "mobx";

import { wsInit } from "./web_socket";
import { BotConfigFile } from "./interfaces";
// import { uuid } from "farmbot";
import * as FarmNot from "farmbot";
import * as Axios from "axios";
import "../css/main.scss";

// mobx setting for more saftey in the safe things.
useStrict(true);

function onInit() {
  Axios.get("/api/config").then((thing) => {
    console.log(thing.data);
  }).catch((_thing) => {
    console.warn("Couldn't parse current config????");
  })
}

/** initialize the websocket connection. */
let ws = wsInit(state, onInit);

// get the element on which we want to render too.
let el = document.querySelector("#app");
if (el) {
  render(<Main state={state} ws={ws} />, el);
} else {
  console.error("could not find element #app");
}