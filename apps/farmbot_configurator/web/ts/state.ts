import { observable, action } from "mobx";
import { BotConfigFile } from "./interfaces";
import { uuid, CeleryNode, isCeleryScript, SendMessage } from "farmbot";

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
    @observable networkInterfaces: NetworkInterface[] = [];
    @observable configuration: BotConfigFile = {
        network: {},
        authorization: {
            server: undefined
        },
        configuration: {
            os_auto_update: false,
            fw_auto_update: false,
            steps_per_mm: 500
        },
        hardware: { params: {} }

    };
    // BEHAVIOR
    @action
    setConnected(bool: boolean) {
        this.connected = bool;
    }

    @action
    deleteMe() {
        this.configuration.network["eth0"] = { type: "ethernet", settings: { ip: { mode: "dhcp" } } }
        delete (this.configuration.network["wlan0"]);
    }

    @action
    incomingMessage(mystery: any): any {
        if (isCeleryScript(mystery)) {
            switch (mystery.kind) {
                case "rpc_ok":
                    return console.log("OK");
                default:
                    console.warn("Unknown CeleryScript node from websocket.");
            }
        } else {
            console.dir(mystery);
        }
    }
}

export let state = observable<MainState>(new MainState());
(window as any)["state"] = state;
