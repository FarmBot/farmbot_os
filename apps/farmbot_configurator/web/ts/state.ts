import { observable, action } from "mobx";
import { BotConfigFile, LogMsg } from "./interfaces";
import {
    uuid,
    CeleryNode,
    isCeleryScript,
    SendMessage,
    BotStateTree
} from "farmbot";

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


function logOrStatus(mystery: any): "log" | "status" | "error" {
    if (mystery["meta"]) {
        return "log"
    }
    if (mystery["configuration"]) {
        return "status";
    }
    return "error";
}

export class MainState {
    // PROPERTIES
    @observable logs: LogMsg[] = [];
    @observable connected = false;
    @observable networkInterfaces: NetworkInterface[] = [];
    @observable botStatus: BotStateTree = {
        location: [-1, -2, -3],
        farm_scheduler: {
            process_info: [],
        },
        mcu_params: {},
        configuration: {

        },
        informational_settings: {

        },
        pins: {}

    }
    @observable configuration: BotConfigFile = {
        network: {},
        authorization: {
            server: undefined
        },
        configuration: {
            os_auto_update: false,
            fw_auto_update: false,
            steps_per_mm: 500,
            timezone: undefined
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
    incomingMessage(mystery: Object): any {
        if (isCeleryScript(mystery)) {
            console.log("What do i do with this?" + JSON.stringify(mystery));
        } else {
            switch (logOrStatus(mystery)) {
                case "log":
                    this.logs.push(mystery as LogMsg);
                    return;
                case "status":
                    this.botStatus = (mystery as BotStateTree)
                    return;
                default: return;
            }
        }
    }
}

export let state = observable<MainState>(new MainState());
(window as any)["state"] = state;
