import { observable, action } from "mobx";
export interface Log { }

export class MainState {
    // PROPERTIES
    @observable logs: Log[] = [];
    @observable wifiSsids: string[] = [];
    @observable connected = false;
    @observable counter = 0;

    // BEHAVIOR
    @action
    up() {
        this.counter += 1;
    }

    @action
    incomingMessage(mystery: any) {
        console.log("Got: " + JSON.stringify(mystery));
    }
}

export let state = observable<MainState>(new MainState());
