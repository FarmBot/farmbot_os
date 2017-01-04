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
        [name: string]: ConfigFileNetIface | undefined;
    },
    authorization: {
        server: string | undefined;
    },
    configuration: {
        os_auto_update: boolean;
        fw_auto_update: boolean;
        timezone: string | undefined;
        steps_per_mm: number;
    },
    hardware: {
        params: { [name: string]: number }
    }
}
