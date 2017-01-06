import * as React from "react";
import { render } from "react-dom";
import { Main } from "./main";
import { state } from "./state";
import { useStrict } from "mobx";

import { wsInit } from "./web_socket";
import { BotConfigFile } from "./interfaces";
// import { uuid } from "farmbot";
import * as FarmNot from "farmbot";
import "../../node_modules/font-awesome/css/font-awesome.min.css";
import "../../node_modules/bootstrap/dist/css/bootstrap.min.css";
import "../css/main.scss";

// mobx setting for more saftey in the safe things.
useStrict(true);

/** initialize the websocket connection. */
let ws = wsInit(state);

// get the element on which we want to render too.
let el = document.querySelector("#app");
if (el) {
  render(<Main state={state} ws={ws} />, el);
} else {
  console.error("could not find element #app");
}