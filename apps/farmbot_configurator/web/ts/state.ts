import { observable, action } from "mobx";
import { RpcMessage, RpcRequest, RpcResponse, RpcNotification } from "./interfaces";
import { infer } from "./jsonrpc";

export interface RpcMessageDict { [propName: string]: RpcRequest | undefined; }
export interface Log { }
export class MainState {
    // PROPERTIES
    @observable logs: Log[] = [];
    @observable wifiSsids: string[] = [];
    @observable connected = false;
    @observable messages: RpcMessageDict = {};

    // BEHAVIOR
    @action
    setConnected(bool: boolean) {
        this.connected = bool;
    }

    @action
    incomingMessage(mystery: RpcMessage): RpcMessage | void {
        // console.log("Got: " + JSON.stringify(mystery));
        let rpc = infer(mystery);
        switch (rpc.kind) {
            case "request":
                return this.handleRequest(rpc.val);
            case "response":
                return this.handleResponse(rpc.val);
            case "notification":
                return this.handleNotification(rpc.val);
            default:
                console.warn("got unhandled rpc message!");
                console.dir(rpc.val);
                return { method: "unhandled", id: null, params: [] }
        }
    }

    private handleNotification(data: RpcNotification): void {
        return;
    }

    private handleResponse(data: RpcResponse): void {
        return;
    }

    private handleRequest(data: RpcRequest): RpcResponse {
        switch (data.method) {
            // when we get a ping send a pong
            case "ping":
                return { error: null, id: data.id, results: "pong" }
            default:
                console.warn("Don't know how to handle: " + data.method);
                return { error: "unhandled", id: data.id, results: "could not handle" };
        }
    }



    @action
    makeRequest(req: RpcRequest) {
        this.messages[req.id || "trash"] = req
    }
}

export let state = observable<MainState>(new MainState());
