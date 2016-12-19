import { MainState } from "./state";
import { infer } from "./jsonrpc";

export function wsInit(state: MainState) {
    // open web socket connection to the bot.
    let ws_host = "ws://" + location.host + "/ws"
    let ws = new WebSocket(ws_host);

    /** when we connect. */
    ws.onopen = function (_event) {
        console.log("Connected to bot!");
        state.setConnected(true);
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
            let mayberesp = state.incomingMessage(data);
            if (mayberesp) {
                let taggedResp = infer(mayberesp);
                if (taggedResp.kind = "response") {
                    ws.send(JSON.stringify(taggedResp.val));
                }
            }

        } catch (error) {
            console.error("Whoopsies");
        }
    }

    return ws;
}