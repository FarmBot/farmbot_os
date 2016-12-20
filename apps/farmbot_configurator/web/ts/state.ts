import { observable, action } from "mobx";
import {
    RpcMessage,
    RpcRequest,
    RpcResponse,
    RpcNotification,
    BotConfigFile
} from "./interfaces";
import { infer } from "./jsonrpc";
import { uuid } from "./utils";
/** messages that need to be resolved by the bot. */
export interface RpcMessageDict { [propName: string]: RpcRequest | undefined; }

/** sent back from the bot when asked to query the current network interfaces. */
export type NetworkInterface = WirelessNetworkInterface
    | WiredNetworkInterface
    | HostNetworkInterface

export interface BaseNetworkInterface {
    /** the type of interfaces this is */
    type: "wireless" | "ethernet" | "host"
    /** ths name of this interface. */
    name: string;
}

export interface WirelessNetworkInterface extends BaseNetworkInterface {
    type: "wireless";
    /** a list of wireless access points. */
    ssids: string[];

}

export interface WiredNetworkInterface extends BaseNetworkInterface {
    type: "ethernet";
}

export interface HostNetworkInterface extends BaseNetworkInterface {
    type: "host"
}

export interface Log { }
export class MainState {
    // PROPERTIES
    @observable logs: Log[] = [];
    @observable connected = false;
    @observable messages: RpcMessageDict = {};
    @observable networkInterfaces: NetworkInterface[] = [];
    @observable configuration: BotConfigFile = {
        network: {},
        authorization: { server: null },
        configuration: {
            os_auto_update: false,
            fw_auto_update: false,
            timezone: null,
            steps_per_mm: 500
        },
        hardware: { params: {} }

    };
    // BEHAVIOR
    @action
    setConnected(bool: boolean) {
        this.connected = bool;
    }

    /*
        So this function will files the mysterious message from the websocket.
        so if it can infer the rpc type from it files to the 
        coorosponding handle* which will return either a RpcMessage, or return 
        void. if it response with a rpc message the handler should send that 
        message to the other end of this connection.

    */
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
                console.warn("got malformed rpc message!");
                console.dir(rpc.val);
                return { method: "unhandled", id: null, params: [] }
        }
    }

    private handleNotification(data: RpcNotification): void {
        switch (data.method) {
            case "log_message":
                let message = data.params[0].message;
                console.log("log_message: " + message);
                this.logs.push(message);
                return;
            default:
                console.log("could not handle: " + data.method);
                return;
        }
    }

    /** handles a response. Can possible return a notification if something went wrong */
    private handleResponse(data: RpcResponse): void | RpcNotification {
        let origin = this.messages[data.id];
        if (origin) {
            console.log(origin.method + " has been resolved.");
            switch (origin.method) {
                case "get_current_config":
                    //todo: this needs to be checked. lol.
                    let config: BotConfigFile = JSON.parse(data.result);
                    state.configuration = config;
                    break;
                case "get_network_interfaces":
                    console.log("got network interfaces.");
                    // so does this: todo
                    state.networkInterfaces = JSON.parse(data.result);
                    break;
                case "upload_config_file":
                    console.log("Config file uploaded!");
                    break;
                case "web_app_creds":
                    console.log("Credentials uploaded!");
                    break;
                default:
                    console.warn("unhandlled response: " + origin.method);
            }
            // remove this request from the dictionary.
            delete this.messages[data.id];
            return;
        } else {
            console.warn("orphaned response: " + JSON.stringify(data));
            return;
        }
    }

    private handleRequest(data: RpcRequest): RpcResponse {
        switch (data.method) {
            // when we get a ping send a pong
            case "ping":
                return { error: null, id: data.id, result: "pong" }
            default:
                console.warn("Don't know how to handle: " + data.method);
                return { error: "unhandled", id: data.id, result: "could not handle" };
        }
    }

    uploadAppCredentials(creds: { email: string, pass: string, server: string }, ws: WebSocket) {
        console.log("Uploading web credentials");
        this.makeRequest({
            method: "web_app_creds",
            params: [creds],
            id: uuid()
        }, ws);
    }

    uploadConfigFile(ws: WebSocket) {
        let config = this.configuration;
        console.dir(config);
        this.makeRequest({
            method: "upload_config_file",
            params: [{ config: config }],
            id: uuid()
        }, ws);
    }

    @action
    makeRequest(req: RpcRequest, ws: WebSocket) {
        console.log("requesting: " + req.method);
        this.messages[req.id || "trash"] = req
        ws.send(JSON.stringify(req));
        let that = this;
        /** this is wrong */
        setTimeout(function (ws) {
            that.rejectRequest(req, "timeout");
        }, 5000);
    }

    @action
    rejectRequest(req: RpcRequest, reason: string) {
        let messages = this.messages;
        let origin = messages[req.id];
        if (origin) {
            // should probably splice it out of the array here but i suck
            console.error(req.method + " failed because: " + reason);
        }
    }
}

export let state = observable<MainState>(new MainState());
(window as any)["state"] = state;
