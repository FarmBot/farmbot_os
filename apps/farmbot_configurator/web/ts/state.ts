import { observable, action } from "mobx";
import { BotConfigFile, LogMsg, ConfigFileNetIface } from "./interfaces";
import {
    uuid,
    CeleryNode,
    isCeleryScript,
    SendMessage,
    BotStateTree
} from "farmbot";
import * as Axios from "axios";

/** This isnt very good im sorry. */
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
    /** Array of log messages */
    @observable logs: LogMsg[] = [
        {
            meta: {
                x: -1,
                y: -2,
                z: -3,
                type: "info"
            },
            message: "Connecting to bot.",
            channels: [],
            created_at: 0
        }
    ];

    /** are we connected to the bot. */
    @observable connected = false;

    /** The current state. if we care about such a thing. */
    @observable botStatus: BotStateTree = {
        location: [-1, -2, -3],
        farm_scheduler: {
            process_info: [],
        },
        mcu_params: {},
        configuration: {},
        informational_settings: {},
        pins: {}
    }

    /** This is the json file that the bot uses to boot up. */
    @observable configuration: BotConfigFile = {
        network: false,
        authorization: {
            server: "fixme"
        },
        configuration: {
            os_auto_update: false,
            fw_auto_update: false,
            steps_per_mm: 500,
            timezone: "fixme"
        },
        hardware: { params: {} }
    };

    @observable ssids: string[] = [];

    // BEHAVIOR

    @action
    tryLogIn() {
        Axios.post("/api/try_log_in", {})
            .then((thing) => {
                console.warn("Bot going offline. (This is ok)");
            })
            .catch((thing) => {
                console.error("something bad happened.");
                console.dir(thing);
            })
    }

    @action
    factoryReset() {
        console.log("This may be a disaaster");
        Axios.post("/api/factory_reset", {}).then((thing) => {
            // I dont think this request will ever complete.
        }).catch((thing) => {
            // probably will hit a timeout here
        });
    }

    @action
    uploadConfigFile(config: BotConfigFile) {
        Axios.post("/api/config", config).then((thing) => {
            console.log("Uploaded!");
        }).catch((err) => {
            console.warn("Problem uploading config!");
            console.dir(err);
        });
    }

    @action
    uploadCreds(email: string, pass: string, server: string) {
        Axios.post("/api/config/creds",
            { email, pass, server }).then((thing) => {
                console.log("Credentials Uploaded!");
            }).catch((err) => {
                console.warn("Problem uploading creds!");
                console.dir(err);
            });
    }

    @action
    blahOK(thing: Axios.AxiosXHR<string[]>) {
        this.ssids = thing.data;
    }

    @action
    blahKO(thing: any) {
        console.error("error scanning for wifi!");
        console.dir(thing);
    }

    /** requires the name of the interface we want to scan on. */
    scan(netIface: string) {
        Axios.post("/api/network/scan", { iface: netIface })
            .then(this.blahOK.bind(this))
            .catch(this.blahKO.bind(this))
    }

    @action
    addInterface(name: string, iface: ConfigFileNetIface) {
        if (this.configuration.network) {
            this.configuration.network.interfaces[name] = iface;
        } else {
            console.log("uhhhh");
        }
    }

    @action
    setConnected(bool: boolean) {
        this.connected = bool;
        let that = this;
        if (bool) {
            Axios.get("/api/config").then((thing) => {
                that.replaceConfig(thing.data as BotConfigFile);
            }).catch((thing) => {
                console.dir(thing);
                console.warn("Couldn't parse current config????");
                return;
            });
            if (this.configuration.network) {
                console.log("Getting network information");

            }
        }
    }

    @action
    replaceConfig(config: BotConfigFile) {
        console.log("got fresh config from bot.");
        this.configuration = config;
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
