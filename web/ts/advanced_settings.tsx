import * as React from "react";
import * as Select from "react-select";
import { MainState } from "./state";
import { observer } from "mobx-react";

interface Props {
    mobx: MainState;
}
export function AdvancedSettings({mobx}: Props) {
    let ssh = false;
    let ntp = false
    let hasNetwork = mobx.configuration.network ? true : false;

    if (mobx.configuration.network) {
        ssh = mobx.configuration.network.ssh;
        ntp = mobx.configuration.network.ntp;
    }

    return <div>
        {/* Factory Reset */}
        <fieldset>
            <label> Factory Reset Your Bot </label>
            <button type="button" onClick={() => {
                mobx.factoryReset();
            } }> Factory Reset your bot! </button>
        </fieldset>

        {/* Allow the user to force network to be enabled */}
        <div>
            <label> Enable Network</label>
            <input type="checkbox"
                defaultChecked={hasNetwork}
                onChange={(event) => {
                    mobx.toggleNetwork();
                    hasNetwork = event.currentTarget.checked;
                }
                } />
        </div>

        {/* hide these settings if we dont have network */}
        <div hidden={mobx.configuration.network === false}>
            {/* SSH  */}
            <fieldset>
                <label> Enable SSH </label>
                <input type="checkbox" defaultChecked={ssh}
                    onChange={(event) => {
                        let blah = event.currentTarget.checked;
                        mobx.toggleSSH(blah);
                    } } />
            </fieldset>

            {/* NTP  */}
            <fieldset>
                <label> Enable NTP </label>
                <input type="checkbox" defaultChecked={ntp}
                    onChange={(event) => {
                        let blah = event.currentTarget.checked;
                        mobx.toggleNTP(blah);
                    } } />
            </fieldset>
        </div>


    </div>
}