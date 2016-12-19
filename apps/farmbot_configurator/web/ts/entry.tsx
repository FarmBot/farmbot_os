import * as React from "react";
import { render } from "react-dom";
import { Main } from "./main";

import { Provider } from "mobx-react";
import { observable } from "mobx";

import { wsInit } from "./web_socket";
import "../css/main.scss"

let el = document.querySelector("#app");
if (el) {

  render(
    <Provider}>
      <Main />
    </Provider >, el);
}

