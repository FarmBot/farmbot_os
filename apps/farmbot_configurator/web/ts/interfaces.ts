export type RpcMessage = RpcNotification | RpcRequest | RpcResponse
/** just like a request but doesn't expect a response. */
export interface RpcNotification {
    method: string;
    params: any;
    id: null;
}
/** request a thing to happen and get info back as a response. */
export interface RpcRequest {
    method: string;
    params: any;
    id: string;
}
/** A response to a request. */
export interface RpcResponse {
    /** the results from the request that started this. */
    result: any;
    /** if no error this MUST be null */
    error: null | any;
    /** the id of the request that waranted this response. */
    id: string;
}

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
export interface BotConfigFile {
    network: {
        [name: string]: ConfigFileNetIface
    },
    authorization: {
        server: null | string;
    },
    configuration: {
        os_auto_update: boolean;
        fw_auto_update: boolean;
        timezone: null | string;
        steps_per_mm: number;
    },
    hardware: {
        params: { [name: string]: number }
    }
}