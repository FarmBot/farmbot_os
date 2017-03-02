import { MainState } from "./state";


/** 
 * DISCLAIMER
 * IM SO SORRY ABOUT THIS BUT I REALLY JUST DONT CARE ENOUT TO FIX IT 
 * PLEASE JUST IGNORE IT SET_TIMEOUT DOESNT WORK THE WAY I WANT IT TO
 * IN THIS CONTEXT
 * ITS NOT IMPORTANT IN PRODUCTION JUST SHHHHH
*/
function wait(ms: number) {
    var start = new Date().getTime();
    var end = start;
    while (end < start + ms) {
        end = new Date().getTime();
    }
}

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
        // recursive because why not
        wait(1000)
        ws = wsInit(state);
    }

    /** ON ws error */
    ws.onerror = function (event) {
        console.error(event);
    }

    /** when a new message comes in. */
    ws.onmessage = function (event) {
        try {
            let data = JSON.parse(event.data);
            if (data === "ping") {
                ws.send(JSON.stringify("pong"));
            } else {
                state.incomingMessage(data);
            }
        } catch (error) {
            console.error("bad json");
        }
    }
    return ws;
}