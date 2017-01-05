import { McuParams } from "farmbot"
export interface ConfigFileIpSettings {
    mode: "dhcp" | "static"
    /** if mode is static, this will exist. */
    settings?: {
        ipv4_address: string;
        ipv4_subnet_mask: string;
        name_servers: string;
    }
}

export interface ConfigFileWifiSettings {
    /** the name of the access point. */
    ssid: string;
    /** if key_mgmt is none, there will be no psk. */
    psk?: string;
    /** only psk and no security are supported. */
    key_mgmt: "WPA-PSK" | "NONE"
}

export interface ConfigFileNetIface {
    type: "wireless" | "hostapd" | "ethernet";
    /** if type is hostapd there will be no settings. */
    settings?: {
        /** we need settings about the ip address, */
        ip: ConfigFileIpSettings;
        /** but might not need wifi. */
        wifi?: ConfigFileWifiSettings;
    }
}

/** Farmbot's Configuratrion 
 * doing an HTTP get to "/api/config" will give the bots current config.
*/
export interface BotConfigFile {
    /** network false indicates that farmbot will already have network 
    *  when started.
    * otherwise 
    */
    network: { [name: string]: ConfigFileNetIface; } | false,
    /** Just holds the server. All other authorization should use a jwt */
    authorization: {
        server: string | undefined;
    },
    /** bag of configuration stuffs. */
    configuration: {
        /** auto update the operating system */
        os_auto_update: boolean;
        /** auto update the arduino firmware */
        fw_auto_update: boolean;
        /** timezone of this bot */
        timezone: string | undefined;
        /** steps per milimeter for the arduino firmware */
        steps_per_mm: number;
    },
    /** hardware mcu stuff */
    hardware: {
        params: McuParams
    }
    /** Should this bot set time after boot. */
    ntp: boolean;
    /** ssh */
    ssh: boolean;
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
