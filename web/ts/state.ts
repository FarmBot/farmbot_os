import { observable, action } from "mobx";
import { BotConfigFile, LogMsg, ConfigFileNetIface } from "./interfaces";
import {
    uuid,
    CeleryNode,
    isCeleryScript,
    SendMessage,
    BotStateTree
} from "farmbot";
import * as _ from "lodash";
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
    @observable possibleInterfaces: string[] = [];
    @observable expected_fw_version: undefined | string;

    /** The current state. if we care about such a thing. */
    @observable botStatus: BotStateTree = {
        location: [-1, -2, -3],
        mcu_params: {},
        configuration: {},
        informational_settings: {},
        pins: {},
        user_env: {},
        process_info: {
            farm_events: [],
            regimens: [],
            farmwares: []
        }
    }

    /** This is the json file that the bot uses to boot up. */
    @observable configuration: BotConfigFile = {
        network: false,
        authorization: {
            server: "fixme"
        },
        configuration: {
            os_auto_update: false,
            steps_per_mm: { x: 500, y: 500, z: 500 }
        },
        hardware: { params: {}, custom_firmware: false }
    };

    @observable ssids: string[] = [];

    // BEHAVIOR

    @action
    tryLogIn() {
        return Axios.post("/api/try_log_in", { hey: "Smile!" });
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
        return Axios.post("/api/config", config);
    }

    @action
    uploadCreds(email: string, pass: string, server: string) {
        this.configuration.authorization.server = server;
        return Axios.post("/api/config/creds", { email, pass, server });
    }

    @action
    scanOK(thing: Axios.AxiosXHR<string[]>) {
        // this.ssids = [
        //     "Uncomment this code for prod.",
        //     "Rick stubbed this."
        // ];
        this.ssids = thing.data;
        console.dir(thing.data);
    }

    @action
    scanKO(thing: any) {
        alert("error scanning for wifi!");
        console.dir(thing);
    }

    /** requires the name of the interface we want to scan on. */
    scan(netIface: string) {
        Axios.post("/api/network/scan", { iface: netIface })
            .then(this.scanOK.bind(this))
            .catch(this.scanKO.bind(this))
    }

    @action
    updateInterface(ifaceName: string, update: Partial<ConfigFileNetIface>) {
        if (this.configuration.network) {
            let iface = this.configuration.network.interfaces[ifaceName];
            let thing = _.merge({}, iface, update);
            this.configuration.network.interfaces[ifaceName] = thing;
        } else {
            console.log("could not find interface " + ifaceName);
        }
    }

    @action
    addInterface(ifaceName: string, thing: ConfigFileNetIface) {
        if (this.configuration.network) {
            this.configuration.network.interfaces[ifaceName] = thing;
        } else {
            this.configuration.network = { ntp: false, interfaces: {}, ssh: false };
            this.configuration.network.interfaces[ifaceName] = thing;
        }
    }

    @action
    CustomFW(bool: boolean) {
        this.configuration.hardware.custom_firmware = bool;
    }

    flashFW() {
        return Axios.post("/api/flash_firmware");
    }

    getExpectedFWVersion() {
        return Axios.get("/api/firmware/expected_version");
    }

    enumerateInterfaces() {
        Axios.get("/api/network/interfaces")
            .then(this.enumerateInterfacesOK.bind(this))
            .catch(this.enumerateInterfacesKO.bind(this))
    }

    @action
    enumerateInterfacesOK(thing: Axios.AxiosXHR<string[]>) {
        this.possibleInterfaces = thing.data;
    }

    @action
    enumerateInterfacesKO(thing: any) {
        this.possibleInterfaces = [];
    }

    @action
    toggleNetwork() {
        if (this.configuration.network) {
            this.configuration.network = false;
        } else {
            this.configuration.network = { interfaces: {}, ntp: false, ssh: false };
        }
    }

    @action
    toggleSSH(b: boolean) {
        if (this.configuration.network) {
            this.configuration.network.ssh = b;
        }
    }

    @action
    toggleNTP(b: boolean) {
        if (this.configuration.network) {
            this.configuration.network.ntp = b;
        }
    }


    @action
    setConnected(bool: boolean) {
        this.connected = bool;
        let that = this;
        if (bool) {
            Axios.get("/api/config")
                .then((thing) => {
                    that.replaceConfig(thing.data as BotConfigFile);
                })
                .catch((thing) => {
                    console.dir(thing);
                    console.warn("Couldn't parse current config????");
                    return;
                });

            Axios.get("/api/firmware/expected_version")
                .then((success) => {
                    console.log("Got expected fw version: " + success.data);
                    that.setExpected_fw((success.data as string));
                })
                .catch((e) => {
                    console.error("ERROR getting expected fw version: " + e);
                })
            if (this.configuration.network) {
                console.log("Getting network information");
            }
        }
    }

    @action
    setExpected_fw(version: string) {
        this.expected_fw_version = version
    }

    @action
    replaceConfig(config: BotConfigFile) {
        console.log("got fresh config from bot.");
        this.configuration = config;
    }

    @action
    incomingMessage(mystery: Object): any {
        // console.log("GOT MEESSAGE");
        if (isCeleryScript(mystery)) {
            console.log("What do i do with this?" + JSON.stringify(mystery));
        } else {
            switch (logOrStatus(mystery)) {
                case "log":
                    this.logs.push(mystery as LogMsg);
                    return;
                case "status":
                    console.log("hello" + JSON.stringify(mystery));
                    this.botStatus = (mystery as BotStateTree)
                    return;
                case "error":
                    console.error("Got unhandled thing.");
                    return;
                default: return;
            }
        }
    }
}

export let state = observable<MainState>(new MainState());
(window as any)["state"] = state;
