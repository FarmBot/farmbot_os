import { MainState } from "./state";

export function wsInit(store: MainState) {
    // open web socket connection to the bot.
    let ws_host = "ws://" + location.host + "/ws"
    let ws = new WebSocket(ws_host);
    let that = this;

    ws.onopen = function (event) {

    }

    ws.onmessage = function (event) {
        try {
            let data = JSON.parse(event.data);
            store.incomingMessage(data);
        } catch (error) {
            console.error("Whoopsies");
        }
    }

    return ws;
}