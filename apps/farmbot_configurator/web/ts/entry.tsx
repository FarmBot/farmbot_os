import * as React from "react";
import { render } from "react-dom";
import { Main } from "./main";
import { state } from "./state";
import { useStrict } from "mobx";

import { wsInit } from "./web_socket";
import "../css/main.scss"

useStrict(true);
/** initialize the websocket connection. */
let ws = wsInit(state);
let el = document.querySelector("#app");
if (el) {
  render(<Main state={state} />, el);
}

