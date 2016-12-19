import { observable } from "mobx";
export interface Log {

}
export interface MainProps {
    logs: Log[];
    wifiSsids: string[];
    connected: boolean;
}
export let state = observable<MainProps>({ logs: [], wifiSsids: [], connected: false });