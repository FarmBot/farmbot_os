import { McuParams } from "farmbot"

export interface ConfigFileWifiSettings {
    /** the name of the access point. */
    ssid: string;
    /** if key_mgmt is none, there will be no psk. */
    psk?: string;
    /** only psk and no security are supported. */
    key_mgmt: "WPA-PSK" | "NONE"
}
type IfaceType = "wired" | "wireless"

/** the layout of a network interface config entry */
export interface ConfigFileNetIface {
    /** false means the interface is brought up, but not started.
     *  "hostapd" starts in host mode.
     *  "static" is static ip settings
     *  "dhcp" is dhcp ip settings
     */
    type: IfaceType
    default: false | "hostapd" | "static" | "dhcp";
    settings: {
        /** ip address for static or host mode. */
        ipv4_address?: string;
        /** subnet mask for static mode */
        ipv4_subnet_mask?: string;
        /** list of dns name servers. */
        nameservers?: string[];
        /** if wifi we support no password, or wpa-psk */
        key_mgmt?: "NONE" | "WPA-PSK";
        /** ssid for wifi */
        ssid?: string;
        /** psk for wifi */
        psk?: string;
    }
}

/** hostapd interface can be transformed into a wireless interface */
export interface HostapdConfigFileNetIface extends ConfigFileNetIface {
    /** hostapd mode */
    default: "hostapd",
    type: "wireless";
    /** there is only one setting. */
    settings: {
        /** the ip address that the bot will give itself. */
        ipv4_address: string;
        /** if a password is desired. */
        psk?: string;
    }
}

/** static interface */
export interface StaticConfigFileNetIface extends ConfigFileNetIface {
    /** static mode */
    default: "static";
    settings: {
        /** required ip address */
        ipv4_address: string;
        /** required subnet mask */
        ipv4_subnet_mask: string;
    }
}
/** dhcp interface */
export interface DhcpConfigFileNetIface extends ConfigFileNetIface {
    /** dhcp mode */
    default: "dhcp";
}

/** Farmbot's Configuratrion 
 * doing an HTTP get to "/api/config" will give the bots current config.
*/
export interface BotConfigFile {
    /** network false indicates that farmbot will already have network 
    *  when started.
    */
    network: {
        /** the interfaces that exist on this system. */
        interfaces: {
            [name: string]: ConfigFileNetIface;
        },
        /** Should this bot set time after boot. */
        ntp: boolean;
        /** ssh */
        ssh: boolean;
    } | false;
    /** Just holds the server. All other authorization should use a jwt */
    authorization: {
        server: string;
    },

    /** bag of configuration stuffs. */
    configuration: {
        /** auto update the operating system */
        os_auto_update: boolean;
        /** auto update the arduino firmware */
        fw_auto_update: boolean;
        /** timezone of this bot */
        timezone: string;
        /** steps per milimeter for the arduino firmware */
        steps_per_mm: number;
    },
    /** hardware mcu stuff */
    hardware: {
        params: McuParams;
    }
}
export type LogChannel = "toast";
export type LogType = "info"
    | "fun"
    | "warn"
    | "error"
    | "busy";

/** why isnt this a celeryScript yet */
export interface LogMsg {
    /** only ever toast right now */
    channels: LogChannel[];
    /** datestamp */
    created_at: number;
    /** the contents of the log */
    message: string;
    /** meta info about this message */
    meta: {
        /** type of message */
        type: LogType;
        /** location x */
        x: number;
        /** location y */
        y: number;
        /** location z */
        z: number;
    }
}
