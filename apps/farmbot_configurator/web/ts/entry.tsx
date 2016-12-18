import { render, h } from "preact";
import { Main } from "./main";
import { GlobalState } from "./interfaces";
import "../css/main.scss"

let el = document.querySelector("#app");

if (el) {
  render(<Main />, el);
}