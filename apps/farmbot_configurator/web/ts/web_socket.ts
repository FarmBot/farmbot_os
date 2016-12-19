import { MainProps } from "./state";

export function wsInit(store: MainProps) {
    // open web socket connection to the bot.
    let ws_host = "ws://" + location.host + "/ws"
    let ws = new WebSocket(ws_host);
    let that = this;

    ws.onopen = function (event) {

    }

    ws.onmessage = function (event) {
        console.log("got msg");
    }

    return ws;
}