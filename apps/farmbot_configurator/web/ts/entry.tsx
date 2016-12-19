import * as React from "react";
import { render } from "react-dom";
import { Main } from "./main";
import { state } from "./state";
import { Provider } from "mobx-react";
import { observable, useStrict } from "mobx";

import { wsInit } from "./web_socket";
import "../css/main.scss"

setInterval(function () {
  state.up();
}, 1000);

useStrict(true);

let el = document.querySelector("#app");
if (el) {
  render(<Main state={state} />, el);
}

