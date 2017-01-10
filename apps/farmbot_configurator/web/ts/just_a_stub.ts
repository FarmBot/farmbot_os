import { ConfigFileNetIface } from "./interfaces";
type WhateverItsJustAStub = {
    [name: string]: ConfigFileNetIface;
};
export const STUB: WhateverItsJustAStub = {
    eth0: {
        type: "wired",
        default: false,
        settings: {}
    },
    wlan0: {
        type: "wireless",
        default: "dhcp",
        settings: {
            ipv4_address: "0.0.0.0",
            ipv4_subnet_mask: "255.255.255.128",
            /** list of dns name servers. */
            nameservers: ["8.8.8.8"],
            key_mgmt: "WPA-PSK",
            ssid: "Placeholder (not in production mode)",
            psk: "????"
        }
    }
};
