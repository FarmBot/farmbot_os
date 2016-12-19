import * as React from "react";
import { observer } from "mobx-react";
import { NetworkInterface } from "./state";
@observer
export class NetworkInterfaceConfig extends React.Component<{ networkInterface: NetworkInterface }, {}>{
    render() {
        let iface = this.props.networkInterface;
        return (
            <div>
                <h4>  configure {iface.name} </h4>
                <div hidden={iface.type !== "wireless"}>
                    <button> Hello button </button>
                </div>
            </div>
        );
    }
}

// <h3> {el.name} Settings </h3>
//     <button hidden={el.type != "wireless"}> Re Scan for wifi </button>