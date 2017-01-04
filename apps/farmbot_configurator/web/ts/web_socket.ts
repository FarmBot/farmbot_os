import { MainState } from "./state";

export function wsInit(state: MainState, callback: Function) {
    // open web socket connection to the bot.
    let ws_host = "ws://" + location.host + "/ws"
    let ws = new WebSocket(ws_host);

    /** when we connect. */
    ws.onopen = function (_event) {
        console.log("Connected to bot!");
        state.setConnected(true);
        callback();
    }

    /** if ever we disconnect. */
    ws.onclose = function (_event) {
        console.warn("UH OH!! Bot disconnected!");
        state.setConnected(false);
    }

    /** when a new message comes in. */
    ws.onmessage = function (event) {
        try {
            let data = JSON.parse(event.data);
            if (data === "ping") {
                ws.send(JSON.stringify("pong"));
            } else {
                console.dir(data);
            }
        } catch (error) {
            console.error("bad json");
        }
    }

    return ws;
}