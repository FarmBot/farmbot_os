// import * as React from "react";
import { h, Component } from "preact";
import {
  RpcMessage,
  RpcNotification,
  RpcRequest,
  RpcResponse
} from "./json_rpc";
import { GlobalState } from "./interfaces";

export class Main extends Component<{}, GlobalState> {
  constructor(props: {}) {
    super(props);

    // open web socket connection to the bot.
    let ws_host = "ws://" + location.host + "/ws"
    let ws = new WebSocket(ws_host);

    // set initial state.
    this.state = { statusBox: { message: "" }, ws: ws };

    // i dont know how to javascript.
    let that = this

    let handleNotification = function (notification: RpcNotification) {
      switch (notification.method) {
        case "ping":
          // console.log("got ping.");
          break;
        default:
          break;
      }
    }

    let handleResponse = function (response: RpcResponse) {
      console.log("response to: " + response.id);
    }

    this.state.ws.onmessage = function (event) {
      let data = (JSON.parse(event.data) as RpcMessage);
      // we have a new RPC message
      if (data.id == null) {
        // we have a notification probably shouldnt be doing so much 
        // type casting
        handleNotification((data as RpcNotification));
        return;
      }
      else {
        console.dir(data);
        // either a request or a response.
        if (data.hasOwnProperty("results")) {
          // its a response.
          handleResponse((data as RpcResponse));
          return;
        } else if (data.hasOwnProperty("method")) {
          // its a request.
          console.log("The bot is asking for information??");
          return;
        } else {
          // something terrible has happened.
          console.log("uhhh...");
          return;
        }
      }
    }

  }

  render() {
    let state = this.state;
    let setState = this.setState;
    let send_request = function (request: RpcRequest) {
      setState({ [request.id]: "pending" });
      state.ws.send(JSON.stringify(request));
    }
    return (
      <div>
        <button onClick={function () {
          let message = {
            id: "1234",
            method: "hey_bot",
            params: [{}]
          };
          send_request(message);
        } }> ask bot something? </button>
      </div>
    );
  }
}
