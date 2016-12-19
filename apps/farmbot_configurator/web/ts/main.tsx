import * as React from "react";
import { observer } from "mobx-react";
import { MainState, NetworkInterface } from "./state";
// import { NetworkInterfaceConfig } from "./network_interface_config";


interface MainProps {
  state: MainState;
  ws: WebSocket;
}

@observer
class NetworkInterfaceConfig extends React.Component<{ ifaces: NetworkInterface[] }, {}>{
  render() {
    console.log("derp")
    let ifaces = this.props.ifaces;
    return (
      <div>
        {ifaces.map((el, index) => {
          return (
            <div key={index}>
              {el.name}
            </div>
          );
        })}
      </div>
    );
  }
}

@observer
export class Main extends React.Component<MainProps, {}> {
  constructor(props: {}) {
    super(props);
  }

  render() {
    let state = this.props.state;

    return (
      <div>
        <h1> Configure your Farmbot! </h1>


        <div hidden={state.connected}>
          <h2> YOUR FARMBOT IS BROKEN!@!!!! </h2>
        </div>

        <div hidden={!state.connected}>
          <div>


            <div hidden={state.networkInterfaces.length < 1} >
              <h2>
                Network Configuration
              </h2>
            </div>

            <div>
              <h3> Web App Configuration </h3>
            </div>


          </div>
        </div>
      </div>
    );
  }
}
